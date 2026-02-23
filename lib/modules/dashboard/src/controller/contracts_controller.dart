import 'package:akimat_project/modules/auth/src/controller/auth_notifier.dart';
import 'package:akimat_project/modules/dashboard/src/controller/contracts_state.dart';
import 'package:akimat_project/modules/dashboard/src/model/contracts/contract.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/organization.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/organization_type.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/user_role.dart';
import 'package:akimat_project/modules/dashboard/src/repository/contracts_repository.dart';
import 'package:akimat_project/modules/dashboard/src/repository/contracts_repository_impl.dart';
import 'package:akimat_project/modules/dashboard/src/controller/organizations_controller.dart';
import 'package:akimat_project/modules/dashboard/src/repository/organizations_repository.dart';
import 'package:akimat_project/services/contracts/module.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ContractsController extends StateNotifier<ContractsState> {
  ContractsController({
    required ContractsRepository contractsRepository,
    required OrganizationsRepository organizationsRepository,
    required ContractsState initialState,
  })  : _contractsRepository = contractsRepository,
        _organizationsRepository = organizationsRepository,
        super(initialState) {
    _loadData();
  }

  final ContractsRepository _contractsRepository;
  final OrganizationsRepository _organizationsRepository;

  Future<void> _loadData() async {
    state = state.copyWith(data: const AsyncLoading());
    
    try {
      // Логируем фильтры для отладки
      debugPrint('ContractsController._loadData: Loading contracts with filters:');
      debugPrint('  - contractorFilter: ${state.contractorFilter}');
      debugPrint('  - statusFilter: ${state.statusFilter}');
      debugPrint('  - periodStart: ${state.periodStart}');
      debugPrint('  - periodEnd: ${state.periodEnd}');
      
      // Загружаем контракты с фильтрами
      // Если фильтр = null, API вернет все контракты (фильтр не передается в query параметры)
      final contracts = await _contractsRepository.loadContracts(
        contractorId: state.contractorFilter,
        status: state.statusFilter,
        startFrom: state.periodStart,
        startTo: state.periodEnd,
      );
      
      debugPrint('ContractsController._loadData: Loaded ${contracts.length} contracts');

      // Загружаем подрядчиков для фильтра
      final allOrganizations = await _organizationsRepository.loadOrganizations();
      final contractors = allOrganizations
          .where((org) => org.type == OrganizationType.contractor && org.isActive)
          .toList();

      // Фильтруем контракты по роли
      List<Contract> filteredContracts = contracts;
      if (state.role == UserRole.contractorAdmin && state.organizationId != null) {
        filteredContracts = contracts
            .where((c) => c.contractorId == state.organizationId)
            .toList();
      }

      state = state.copyWith(
        data: AsyncData(
          ContractsData(
            contracts: filteredContracts,
            contractors: contractors,
          ),
        ),
      );
    } catch (e, stack) {
      state = state.copyWith(data: AsyncError(e, stack));
    }
  }

  Future<void> refresh() => _loadData();

  void setContractorFilter(String? contractorId) {
    // Всегда обновляем состояние и перезагружаем данные,
    // даже если значение не изменилось (например, повторный выбор "Все")
    state = state.copyWith(
      contractorFilter: contractorId,
      clearContractorFilter: contractorId == null,
    );
    // Всегда перезагружаем данные, чтобы применить фильтр (или сбросить его при null)
    _loadData();
  }

  void setStatusFilter(ContractStatus? status) {
    // Всегда обновляем состояние и перезагружаем данные,
    // даже если значение не изменилось (например, повторный выбор "Все")
    debugPrint('ContractsController.setStatusFilter: Called with status: $status');
    debugPrint('ContractsController.setStatusFilter: Current statusFilter: ${state.statusFilter}');
    
    // Принудительно обновляем состояние, даже если значение не изменилось
    // Это гарантирует, что фильтр будет сброшен при выборе "Все" (null)
    state = state.copyWith(
      statusFilter: status,
      clearStatusFilter: status == null,
    );
    
    debugPrint('ContractsController.setStatusFilter: New statusFilter: ${state.statusFilter}');
    debugPrint('ContractsController.setStatusFilter: Calling _loadData()');
    
    // Всегда перезагружаем данные, чтобы применить фильтр (или сбросить его при null)
    _loadData();
  }

  void setPeriodFilter(DateTime? start, DateTime? end) {
    state = state.copyWith(periodStart: start, periodEnd: end);
    _loadData();
  }

  Future<void> createContract({
    required ContractType contractType,
    String? contractorId,
    String? landfillId,
    required String name,
    ContractWorkType? workType,
    required double pricePerM3,
    double? budgetTotal,
    double? minimalVolumeM3,
    List<String>? polygonIds,
    double? vatRate,
    required DateTime startAt,
    required DateTime endAt,
    required bool isActive,
    String? createdByOrgId, // ID организации KGU ZKH, создающей контракт
  }) async {
    try {
      await _contractsRepository.createContract(
        contractType: contractType,
        contractorId: contractorId,
        landfillId: landfillId,
        name: name,
        workType: workType,
        pricePerM3: pricePerM3,
        budgetTotal: budgetTotal,
        minimalVolumeM3: minimalVolumeM3,
        polygonIds: polygonIds,
        vatRate: vatRate,
        startAt: startAt,
        endAt: endAt,
        isActive: isActive,
        createdByOrgId: createdByOrgId ?? state.organizationId, // Используем organizationId из state или переданный
      );
      await _loadData();
    } catch (e) {
      rethrow;
    }
  }
}

final contractsRepositoryProvider = Provider<ContractsRepository>((ref) {
  return ContractsRepositoryImpl(services: ref.watch(contractsServicesProvider));
});

final contractsControllerProvider =
    StateNotifierProvider<ContractsController, ContractsState>((ref) {
  final authState = ref.watch(authNotifierProvider);
  final contractsRepository = ref.watch(contractsRepositoryProvider);
  final organizationsRepository = ref.watch(organizationsRepositoryProvider);
  final role = userRoleFromString(authState.user?.role);
  final organizationId = authState.user?.organizationId;
  return ContractsController(
    contractsRepository: contractsRepository,
    organizationsRepository: organizationsRepository,
    initialState: ContractsState.initial(role: role, organizationId: organizationId),
  );
});

