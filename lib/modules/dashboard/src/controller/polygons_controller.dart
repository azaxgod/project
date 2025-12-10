import 'package:akimat_project/modules/auth/src/controller/auth_notifier.dart';
import 'package:akimat_project/modules/dashboard/src/controller/areas_controller.dart';
import 'package:akimat_project/modules/dashboard/src/controller/polygons_state.dart';
import 'package:akimat_project/modules/dashboard/src/controller/tickets_controller.dart';
import 'package:akimat_project/modules/dashboard/src/model/contracts/contract.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/user_role.dart';
import 'package:akimat_project/modules/dashboard/src/model/polygons/camera.dart';
import 'package:akimat_project/modules/dashboard/src/model/polygons/polygon.dart';
import 'package:akimat_project/modules/dashboard/src/repository/contracts_repository.dart';
import 'package:akimat_project/modules/dashboard/src/repository/operations_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final polygonsControllerProvider = StateNotifierProvider<PolygonsController, PolygonsState>((ref) {
  final authState = ref.watch(authNotifierProvider);
  final role = userRoleFromString(authState.user?.role);
  final organizationId = authState.user?.organizationId;
  
  return PolygonsController(
    repository: ref.watch(operationsRepositoryProvider),
    contractsRepository: ref.watch(contractsRepositoryProvider),
    initialState: PolygonsState.initial(
      role: role,
      organizationId: organizationId,
    ),
  );
});

class PolygonsController extends StateNotifier<PolygonsState> {
  PolygonsController({
    required OperationsRepository repository,
    required ContractsRepository contractsRepository,
    required PolygonsState initialState,
  })  : _repository = repository,
        _contractsRepository = contractsRepository,
        super(initialState) {
    _loadData();
  }

  final OperationsRepository _repository;
  final ContractsRepository _contractsRepository;

  Future<void> _loadData() async {
    state = state.copyWith(data: const AsyncLoading());
    state = state.copyWith(
      data: await AsyncValue.guard(() async {
        // Load polygons from operations service
        // Для всех ролей используем onlyActive=true
        // Сервер должен возвращать все активные полигоны для CONTRACTOR_ADMIN, включая созданные LANDFILL_ADMIN
        List<Polygon> polygons = await _repository.loadPolygons(onlyActive: true);
        
        debugPrint('PolygonsController._loadData: Loaded ${polygons.length} polygons for role=${state.role}, onlyActive=true');
        
        // Fallback для CONTRACTOR_ADMIN: если сервер вернул пустой список, пробуем загрузить все полигоны без фильтра
        if (state.role == UserRole.contractorAdmin && polygons.isEmpty) {
          debugPrint('PolygonsController._loadData: CONTRACTOR_ADMIN got empty polygons list, trying to load all polygons without onlyActive filter');
          try {
            final allPolygons = await _repository.loadPolygons(onlyActive: null);
            // Фильтруем только активные на клиенте
            polygons = allPolygons.where((p) => p.isActive).toList();
            debugPrint('PolygonsController._loadData: Loaded ${polygons.length} active polygons without onlyActive filter');
          } catch (e) {
            debugPrint('PolygonsController._loadData: Failed to load polygons without onlyActive filter: $e');
          }
        }
        
        // Дополнительный fallback для CONTRACTOR_ADMIN: если все еще пусто, пробуем получить полигоны через контракты
        if (state.role == UserRole.contractorAdmin && polygons.isEmpty && state.organizationId != null) {
          debugPrint('PolygonsController._loadData: CONTRACTOR_ADMIN got empty polygons list, trying to load via contracts');
          try {
            final contracts = await _contractsRepository.loadContracts(
              contractorId: state.organizationId,
            );
            debugPrint('PolygonsController._loadData: Loaded ${contracts.length} contracts for CONTRACTOR_ADMIN');
            
            // Собираем все polygonIds из контрактов типа LANDFILL_SERVICE
            final polygonIds = <String>{};
            for (final contract in contracts) {
              if (contract.contractType == ContractType.landfillService && 
                  contract.polygonIds != null && 
                  contract.polygonIds!.isNotEmpty) {
                polygonIds.addAll(contract.polygonIds!);
              }
            }
            
            debugPrint('PolygonsController._loadData: Found ${polygonIds.length} unique polygon IDs in contracts');
            
            // Загружаем каждый полигон по ID
            for (final polygonId in polygonIds) {
              try {
                final polygon = await _repository.getPolygon(polygonId);
                polygons.add(polygon);
                debugPrint('PolygonsController._loadData: Loaded polygon ${polygon.name} (${polygon.id}) from contract');
              } catch (e) {
                debugPrint('PolygonsController._loadData: Failed to load polygon $polygonId: $e');
              }
            }
            
            debugPrint('PolygonsController._loadData: Loaded ${polygons.length} polygons via contracts fallback');
          } catch (e) {
            debugPrint('PolygonsController._loadData: Failed to load polygons via contracts: $e');
          }
        }
        
        // Load cameras for selected polygon or all polygons
        final cameras = <Camera>[];
        if (state.selectedPolygon != null) {
          final polygonCameras = await _repository.getPolygonCameras(
            state.selectedPolygon!.id,
          );
          cameras.addAll(polygonCameras);
        }
        
        return PolygonsData(
          polygons: polygons,
          cameras: cameras,
        );
      }),
    );
  }

  Future<void> refresh() => _loadData();

  Future<void> createPolygon(Polygon polygon) async {
    final result = await AsyncValue.guard(() async {
      return await _repository.createPolygon(
        name: polygon.name,
        address: polygon.address,
        description: polygon.description,
        geometry: polygon.geometry,
        isActive: polygon.isActive,
      );
    });
    
    if (!result.hasError) {
      await _loadData();
    }
  }

  Future<void> updatePolygon(Polygon polygon) async {
    final result = await AsyncValue.guard(() async {
      return await _repository.updatePolygon(
        polygon.id,
        name: polygon.name,
        address: polygon.address,
        description: polygon.description,
        isActive: polygon.isActive,
      );
    });
    
    if (!result.hasError) {
      await _loadData();
    }
  }

  Future<void> createCamera(Camera camera) async {
    final result = await AsyncValue.guard(() async {
      return await _repository.createCamera(
        polygonId: camera.polygonId,
        type: camera.type,
        name: camera.name,
        location: camera.location,
        isActive: camera.isActive,
      );
    });
    
    if (!result.hasError) {
      await _loadData();
    }
  }

  Future<void> updateCamera(Camera camera) async {
    final result = await AsyncValue.guard(() async {
      return await _repository.updateCamera(
        camera.polygonId,
        camera.id,
        type: camera.type,
        name: camera.name,
        location: camera.location,
        isActive: camera.isActive,
      );
    });
    
    if (!result.hasError) {
      await _loadData();
    }
  }

  void selectPolygon(Polygon? polygon) {
    state = state.copyWith(selectedPolygon: polygon);
  }
}

