import 'package:akimat_project/modules/auth/src/controller/auth_notifier.dart';
import 'package:akimat_project/modules/dashboard/src/controller/areas_state.dart';
import 'package:akimat_project/modules/dashboard/src/model/areas/cleaning_area.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/organization_type.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/user_role.dart';
import 'package:akimat_project/modules/dashboard/src/repository/operations_repository.dart';
import 'package:akimat_project/modules/dashboard/src/repository/operations_repository_impl.dart';
import 'package:akimat_project/modules/dashboard/src/repository/organizations_repository.dart';
import 'package:akimat_project/modules/dashboard/src/repository/organizations_repository_impl.dart';
import 'package:akimat_project/services/operations/module.dart';
import 'package:akimat_project/services/organizations/module.dart';
import 'package:akimat_project/services/tickets/module.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final operationsRepositoryProvider = Provider<OperationsRepository>((ref) {
  final services = ref.watch(operationsServicesProvider);
  final ticketsServices = ref.watch(ticketsServicesProvider);
  final authState = ref.watch(authNotifierProvider);
  final role = userRoleFromString(authState.user?.role);
  
  return OperationsRepositoryImpl(
    services: services,
    ticketsServices: ticketsServices,
    userRole: role,
  );
});

final areasControllerProvider = StateNotifierProvider<AreasController, AreasState>((ref) {
  final authState = ref.watch(authNotifierProvider);
  final role = userRoleFromString(authState.user?.role);
  final organizationId = authState.user?.organizationId;
  
  return AreasController(
    operationsRepository: ref.watch(operationsRepositoryProvider),
    organizationsRepository: OrganizationsRepositoryImpl(
      services: ref.watch(organizationsServicesProvider),
    ),
    initialState: AreasState.initial(
      role: role,
      organizationId: organizationId,
    ),
  );
});

class AreasController extends StateNotifier<AreasState> {
  AreasController({
    required OperationsRepository operationsRepository,
    required OrganizationsRepository organizationsRepository,
    required AreasState initialState,
  })  : _operationsRepository = operationsRepository,
        _organizationsRepository = organizationsRepository,
        super(initialState) {
    _loadData();
  }

  final OperationsRepository _operationsRepository;
  final OrganizationsRepository _organizationsRepository;

  Future<void> _loadData() async {
    state = state.copyWith(data: const AsyncLoading());
    state = state.copyWith(
      data: await AsyncValue.guard(() async {
        // Load contractors for filter
        final organizations = await _organizationsRepository.loadOrganizations();
        final contractors = organizations
            .where((org) => org.type == OrganizationType.contractor)
            .toList();
        
        // Load areas from operations service
        // Для CONTRACTOR_ADMIN передаем contractorId в запрос
        final contractorId = state.role == UserRole.contractorAdmin ? state.organizationId : null;
        List<CleaningArea> allAreas = [];
        try {
          allAreas = await _operationsRepository.loadCleaningAreas(
            status: state.statusFilter,
            onlyActive: true,
            contractorId: contractorId,
          );
          debugPrint('AreasController: Loaded ${allAreas.length} areas with contractorId=$contractorId');
        } catch (e) {
          debugPrint('AreasController: Failed to load areas: $e');
          allAreas = [];
        }
        
        // Для CONTRACTOR_ADMIN фильтруем участки по defaultContractorId ИЛИ участки из тикетов
        // Если сервер вернул пустой список (data: null), создаем заглушки из тикетов
        List<CleaningArea> areas = allAreas;
        if (state.role == UserRole.contractorAdmin && state.organizationId != null) {
          // Загружаем тикеты подрядчика, чтобы получить список участков из тикетов
          Set<String> areaIdsFromTickets = {};
          try {
            final tickets = await _operationsRepository.loadTickets();
            areaIdsFromTickets = tickets.map((t) => t.cleaningAreaId).toSet();
            debugPrint('AreasController._loadData: CONTRACTOR_ADMIN found ${areaIdsFromTickets.length} unique area IDs in tickets');
            
            final existingAreaIds = allAreas.map((a) => a.id).toSet();
            final missingAreaIds = areaIdsFromTickets.difference(existingAreaIds);
            
            // Создаем заглушки для участков из тикетов, которых нет в списке
            if (missingAreaIds.isNotEmpty) {
              debugPrint('AreasController._loadData: Creating ${missingAreaIds.length} placeholder CleaningArea objects for missing areas');
              for (final areaId in missingAreaIds) {
                final shortId = areaId.length >= 8 ? areaId.substring(0, 8) : areaId;
                final placeholderArea = CleaningArea(
                  id: areaId,
                  name: 'Участок $shortId',
                  geometry: [],
                  status: CleaningAreaStatus.active,
                  isActive: true,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );
                allAreas.add(placeholderArea);
                debugPrint('AreasController._loadData: Created placeholder for area $areaId');
              }
            }
          } catch (e) {
            debugPrint('AreasController._loadData: Failed to load tickets: $e');
          }
          
          // Фильтруем участки: defaultContractorId ИЛИ участки из тикетов
          areas = allAreas
              .where((area) => 
                  area.defaultContractorId == state.organizationId || 
                  areaIdsFromTickets.contains(area.id))
              .toList();
          debugPrint('AreasController._loadData: CONTRACTOR_ADMIN filtered ${areas.length} areas from ${allAreas.length} total');
        }
        
        return AreasData(
          areas: areas,
          contractors: contractors,
        );
      }),
    );
  }

  Future<void> refresh() => _loadData();

  Future<void> createArea(CleaningArea area) async {
    final result = await AsyncValue.guard(() async {
      return await _operationsRepository.createCleaningArea(
        name: area.name,
        description: area.description,
        geometry: area.geometry,
        city: area.city,
        defaultContractorId: area.defaultContractorId,
      );
    });
    
    if (!result.hasError) {
      await _loadData();
    }
  }

  Future<void> updateArea(CleaningArea area) async {
    final result = await AsyncValue.guard(() async {
      return await _operationsRepository.updateCleaningArea(
        area.id,
        name: area.name,
        description: area.description,
        status: area.status,
        defaultContractorId: area.defaultContractorId,
      );
    });
    
    if (!result.hasError) {
      await _loadData();
    }
  }

  void setStatusFilter(CleaningAreaStatus? status) {
    state = state.copyWith(statusFilter: status);
  }

  void setContractorFilter(String? contractorId) {
    state = state.copyWith(contractorFilter: contractorId);
  }

  void selectArea(CleaningArea? area) {
    state = state.copyWith(selectedArea: area);
  }
}

