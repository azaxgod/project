import 'dart:async';
import 'package:akimat_project/modules/auth/src/controller/auth_notifier.dart';
import 'package:akimat_project/modules/dashboard/src/controller/areas_controller.dart';
import 'package:akimat_project/modules/dashboard/src/controller/monitoring_state.dart';
import 'package:akimat_project/modules/dashboard/src/model/areas/cleaning_area.dart';
import 'package:akimat_project/modules/dashboard/src/model/monitoring/vehicle_monitoring.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/organization_type.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/user_role.dart';
import 'package:akimat_project/modules/dashboard/src/model/polygons/camera.dart';
import 'package:akimat_project/modules/dashboard/src/model/polygons/polygon.dart';
import 'package:akimat_project/modules/dashboard/src/repository/operations_repository.dart';
import 'package:akimat_project/modules/dashboard/src/repository/organizations_repository.dart';
import 'package:akimat_project/modules/dashboard/src/repository/organizations_repository_impl.dart';
import 'package:akimat_project/services/organizations/module.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final monitoringControllerProvider = StateNotifierProvider<MonitoringController, MonitoringState>((ref) {
  debugPrint('monitoringControllerProvider: Starting initialization');
  try {
    debugPrint('monitoringControllerProvider: Getting authState');
    final authState = ref.watch(authNotifierProvider);
    debugPrint('monitoringControllerProvider: authState.user=${authState.user?.role}');
    
    debugPrint('monitoringControllerProvider: Getting role');
    final role = userRoleFromString(authState.user?.role);
    final organizationId = authState.user?.organizationId;
    debugPrint('monitoringControllerProvider: role=$role, organizationId=$organizationId');
    
    debugPrint('monitoringControllerProvider: Getting operationsRepositoryProvider');
    final operationsRepo = ref.watch(operationsRepositoryProvider);
    debugPrint('monitoringControllerProvider: operationsRepositoryProvider obtained');
    
    debugPrint('monitoringControllerProvider: Getting organizationsServicesProvider');
    final orgServices = ref.watch(organizationsServicesProvider);
    debugPrint('monitoringControllerProvider: organizationsServicesProvider obtained');
    
    debugPrint('monitoringControllerProvider: Creating OrganizationsRepositoryImpl');
    final orgRepo = OrganizationsRepositoryImpl(services: orgServices);
    debugPrint('monitoringControllerProvider: OrganizationsRepositoryImpl created');
    
    debugPrint('monitoringControllerProvider: Creating MonitoringState.initial');
    final initialState = MonitoringState.initial(
      role: role,
      organizationId: organizationId,
    );
    debugPrint('monitoringControllerProvider: MonitoringState.initial created');
    
    debugPrint('monitoringControllerProvider: Creating MonitoringController');
    final controller = MonitoringController(
      operationsRepository: operationsRepo,
      organizationsRepository: orgRepo,
      initialState: initialState,
    );
    debugPrint('monitoringControllerProvider: MonitoringController created successfully');
    return controller;
  } catch (e, stackTrace) {
    debugPrint('monitoringControllerProvider: ERROR during initialization: $e');
    debugPrint('monitoringControllerProvider: Stack trace: $stackTrace');
    // Возвращаем контроллер с начальным состоянием, чтобы не падал provider
    return MonitoringController(
      operationsRepository: ref.read(operationsRepositoryProvider),
      organizationsRepository: OrganizationsRepositoryImpl(
        services: ref.read(organizationsServicesProvider),
      ),
      initialState: MonitoringState.initial(
        role: UserRole.akimatAdmin, // Fallback
        organizationId: null,
      ),
    );
  }
});

class MonitoringController extends StateNotifier<MonitoringState> {
  MonitoringController({
    required OperationsRepository operationsRepository,
    required OrganizationsRepository organizationsRepository,
    required MonitoringState initialState,
  })  : _operationsRepository = operationsRepository,
        _organizationsRepository = organizationsRepository,
        super(initialState) {
    debugPrint('MonitoringController: Constructor called');
    try {
      debugPrint('MonitoringController: Starting _loadData');
      _loadData();
      debugPrint('MonitoringController: _loadData started');
      debugPrint('MonitoringController: Starting _startVehicleUpdates');
      _startVehicleUpdates();
      debugPrint('MonitoringController: Constructor completed');
    } catch (e, stackTrace) {
      debugPrint('MonitoringController: Constructor error: $e');
      debugPrint('MonitoringController: Constructor stack: $stackTrace');
      // Не пробрасываем ошибку, чтобы provider не падал
    }
  }

  final OperationsRepository _operationsRepository;
  final OrganizationsRepository _organizationsRepository;
  Timer? _vehicleUpdateTimer;

  @override
  void dispose() {
    _vehicleUpdateTimer?.cancel();
    super.dispose();
  }

  /// Загрузка всех данных для мониторинга
  Future<void> _loadData() async {
    debugPrint('MonitoringController._loadData: Starting data load');
    state = state.copyWith(data: const AsyncLoading());
    state = state.copyWith(
      data: await AsyncValue.guard(() async {
        debugPrint('MonitoringController._loadData: Inside guard');
        
        // Load contractors for filter
        debugPrint('MonitoringController._loadData: Loading contractors');
        final organizations = await _organizationsRepository.loadOrganizations();
        final contractors = organizations
            .where((org) => org.type == OrganizationType.contractor)
            .toList();
        debugPrint('MonitoringController._loadData: Loaded ${contractors.length} contractors');
        
        // Загружаем участки
        debugPrint('MonitoringController._loadData: Loading areas');
        List<CleaningArea> areas = [];
        try {
          // Пробуем сначала с onlyActive=true
          areas = await _operationsRepository.loadCleaningAreas(
            status: state.statusFilter,
            onlyActive: true,
          );
          debugPrint('MonitoringController._loadData: Loaded ${areas.length} areas with onlyActive=true');
        } catch (e) {
          debugPrint('MonitoringController._loadData: Failed to load areas with onlyActive=true: $e');
          // Fallback: пробуем без onlyActive, если запрос с onlyActive падает
          try {
            debugPrint('MonitoringController._loadData: Retrying without onlyActive parameter');
            areas = await _operationsRepository.loadCleaningAreas(
              status: state.statusFilter,
              onlyActive: null,
            );
            // Фильтруем на клиенте, если бэкенд не поддерживает onlyActive
            if (state.statusFilter == null) {
              areas = areas.where((area) => area.isActive).toList();
            }
            debugPrint('MonitoringController._loadData: Loaded ${areas.length} areas without onlyActive (filtered on client)');
          } catch (e2) {
            debugPrint('MonitoringController._loadData: Failed to load areas without onlyActive: $e2');
            // Продолжаем с пустым списком, чтобы не ломать всю страницу
            areas = [];
          }
        }

        // Загружаем полигоны
        debugPrint('MonitoringController._loadData: Loading polygons');
        List<Polygon> polygons = [];
        try {
          polygons = await _operationsRepository.loadPolygons(onlyActive: true);
          debugPrint('MonitoringController._loadData: Loaded ${polygons.length} polygons with onlyActive=true');
        } catch (e) {
          debugPrint('MonitoringController._loadData: Failed to load polygons with onlyActive=true: $e');
          // Fallback: пробуем без onlyActive
          try {
            debugPrint('MonitoringController._loadData: Retrying polygons without onlyActive parameter');
            polygons = await _operationsRepository.loadPolygons(onlyActive: null);
            // Фильтруем на клиенте
            polygons = polygons.where((polygon) => polygon.isActive).toList();
            debugPrint('MonitoringController._loadData: Loaded ${polygons.length} polygons without onlyActive (filtered on client)');
          } catch (e2) {
            debugPrint('MonitoringController._loadData: Failed to load polygons without onlyActive: $e2');
            polygons = [];
          }
        }

        // Загружаем камеры для всех полигонов
        debugPrint('MonitoringController._loadData: Loading cameras');
        final cameras = <String, List<Camera>>{};
        for (final polygon in polygons) {
          try {
            final polygonCameras = await _operationsRepository.getPolygonCameras(polygon.id);
            cameras[polygon.id] = polygonCameras;
          } catch (e) {
            debugPrint('MonitoringController._loadData: Failed to load cameras for polygon ${polygon.id}: $e');
            cameras[polygon.id] = []; // Продолжаем с пустым списком камер для этого полигона
          }
        }
        debugPrint('MonitoringController._loadData: Loaded cameras for ${cameras.length} polygons');

        // Загружаем технику
        debugPrint('MonitoringController._loadData: Loading vehicles');
        List<VehicleMonitoring> vehicles = [];
        try {
          vehicles = await _operationsRepository.getVehiclesLive(
            contractorId: state.contractorFilter,
          );
          debugPrint('MonitoringController._loadData: Loaded ${vehicles.length} vehicles');
        } catch (e) {
          debugPrint('MonitoringController._loadData: Failed to load vehicles: $e');
          // Продолжаем с пустым списком техники, чтобы не ломать всю страницу
          vehicles = [];
        }

        // Фильтруем данные по ролям
        debugPrint('MonitoringController._loadData: Filtering data by role');
        final filteredAreas = _filterAreasByRole(areas);
        final filteredPolygons = _filterPolygonsByRole(polygons);
        final filteredCameras = _filterCamerasByRole(cameras, polygons);
        final filteredVehicles = _filterVehiclesByRole(vehicles);

        // Объединяем все камеры в один список
        final allCameras = <Camera>[];
        for (final cameraList in cameras.values) {
          allCameras.addAll(cameraList);
        }

        debugPrint('MonitoringController._loadData: Creating MonitoringData');
        final data = MonitoringData(
          areas: filteredAreas,
          polygons: filteredPolygons,
          cameras: filteredCameras,
          vehicles: filteredVehicles,
          contractors: contractors, // Добавляем подрядчиков для маппинга
          lastUpdate: DateTime.now(),
        );
        debugPrint('MonitoringController._loadData: Data loaded successfully');
        return data;
      }),
    );
  }

  /// Фильтрация участков по ролям
  List<CleaningArea> _filterAreasByRole(List<CleaningArea> areas) {
    switch (state.role) {
      case UserRole.akimatAdmin:
      case UserRole.kguZkhAdmin:
        return areas; // Видят все участки
      case UserRole.tooAdmin:
        return []; // TOO не видит участки (только полигоны)
      case UserRole.contractorAdmin:
        // Видят только участки с тикетами на этого подрядчика
        // TODO: Реализовать фильтрацию по тикетам через Operations Service
        // Пока возвращаем все участки, так как фильтрация должна быть на бэкенде
        return areas;
      case UserRole.driver:
        // Видят только участки, где есть активные тикеты
        // TODO: Реализовать фильтрацию по тикетам водителя через Operations Service
        return areas;
      default:
        return [];
    }
  }

  /// Фильтрация полигонов по ролям
  List<Polygon> _filterPolygonsByRole(List<Polygon> polygons) {
    switch (state.role) {
      case UserRole.akimatAdmin:
      case UserRole.kguZkhAdmin:
      case UserRole.tooAdmin:
      case UserRole.contractorAdmin:
      case UserRole.driver:
        return polygons; // Все видят полигоны
      default:
        return [];
    }
  }

  /// Фильтрация камер по ролям
  List<Camera> _filterCamerasByRole(Map<String, List<Camera>> cameras, List<Polygon> polygons) {
    switch (state.role) {
      case UserRole.akimatAdmin:
      case UserRole.kguZkhAdmin:
      case UserRole.tooAdmin:
        return cameras.values.expand((c) => c).toList(); // Видят все камеры
      case UserRole.contractorAdmin:
      case UserRole.driver:
        // Видят камеры доступных полигонов
        return cameras.values.expand((c) => c).toList();
      default:
        return [];
    }
  }

  /// Фильтрация техники по ролям
  List<VehicleMonitoring> _filterVehiclesByRole(List<VehicleMonitoring> vehicles) {
    switch (state.role) {
      case UserRole.akimatAdmin:
      case UserRole.kguZkhAdmin:
        return vehicles; // Видят всю технику
      case UserRole.tooAdmin:
        return vehicles; // Видят всю технику (но не участки)
      case UserRole.contractorAdmin:
        // Видят только свою технику
        return vehicles
            .where((v) => v.contractorId == state.organizationId)
            .toList();
      case UserRole.driver:
        // Видят только технику, связанную с их тикетами
        // TODO: Реализовать фильтрацию по тикетам водителя
        return vehicles;
      default:
        return [];
    }
  }

  /// Запуск периодического обновления техники
  void _startVehicleUpdates() {
    _vehicleUpdateTimer?.cancel();
    _vehicleUpdateTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _updateVehicles();
    });
  }

  /// Обновление данных техники
  Future<void> _updateVehicles() async {
    final currentData = state.data.valueOrNull;
    if (currentData == null) return;

    try {
      debugPrint('MonitoringController._updateVehicles: Updating vehicles...');
      final vehicles = await _operationsRepository.getVehiclesLive(
        contractorId: state.contractorFilter,
      );
      debugPrint('MonitoringController._updateVehicles: Loaded ${vehicles.length} vehicles');

      final filteredVehicles = _filterVehiclesByRole(vehicles);
      debugPrint('MonitoringController._updateVehicles: Filtered to ${filteredVehicles.length} vehicles');

      state = state.copyWith(
        data: AsyncData(
          currentData.copyWith(
            vehicles: filteredVehicles,
            lastUpdate: DateTime.now(),
          ),
        ),
      );
      debugPrint('MonitoringController._updateVehicles: Vehicles updated successfully');
    } catch (e, stackTrace) {
      debugPrint('MonitoringController._updateVehicles: Error updating vehicles: $e');
      debugPrint('MonitoringController._updateVehicles: Stack trace: $stackTrace');
      // Игнорируем ошибки при обновлении, чтобы не сломать UI
    }
  }

  /// Обновление всех данных
  Future<void> refresh() async {
    debugPrint('MonitoringController.refresh: Starting data refresh');
    await _loadData();
    debugPrint('MonitoringController.refresh: Data refresh completed');
  }

  /// Переключение вкладки
  void setSelectedTab(String tab) {
    state = state.copyWith(selectedTab: tab);
  }

  /// Выбор участка
  void selectArea(String? areaId) {
    state = state.copyWith(selectedAreaId: areaId);
  }

  /// Выбор полигона
  void selectPolygon(String? polygonId) {
    state = state.copyWith(selectedPolygonId: polygonId);
  }

  /// Выбор техники и загрузка трека
  Future<void> selectVehicle(String? vehicleId) async {
    state = state.copyWith(selectedVehicleId: vehicleId);
    
    if (vehicleId == null) {
      state = state.copyWith(selectedVehicleTrack: null);
      return;
    }

    try {
      final track = await _operationsRepository.getVehicleTrack(
        vehicleId,
        from: DateTime.now().subtract(const Duration(hours: 1)),
        to: DateTime.now(),
      );
      state = state.copyWith(selectedVehicleTrack: track);
    } catch (e) {
      // Игнорируем ошибки
    }
  }

  /// Установка фильтра статуса
  void setStatusFilter(CleaningAreaStatus? status) {
    state = state.copyWith(statusFilter: status);
    _loadData();
  }

  /// Установка фильтра подрядчика
  void setContractorFilter(String? contractorId) {
    state = state.copyWith(contractorFilter: contractorId);
    _loadData();
  }

  /// Переключение видимости слоев
  void toggleVehicles(bool show) {
    state = state.copyWith(showVehicles: show);
  }

  void toggleAreas(bool show) {
    state = state.copyWith(showAreas: show);
  }

  void togglePolygons(bool show) {
    state = state.copyWith(showPolygons: show);
  }

  void toggleCameras(bool show) {
    state = state.copyWith(showCameras: show);
  }

  // ==================== CRUD Operations ====================

  /// Создать участок уборки
  Future<void> createCleaningArea({
    required String name,
    String? description,
    required List<List<double>> geometry,
    String? city,
    String? defaultContractorId,
  }) async {
    try {
      await _operationsRepository.createCleaningArea(
        name: name,
        description: description,
        geometry: geometry,
        city: city,
        defaultContractorId: defaultContractorId,
      );
      await refresh();
    } catch (e) {
      debugPrint('Error creating cleaning area: $e');
      rethrow;
    }
  }

  /// Создать полигон
  Future<void> createPolygon({
    required String name,
    String? address,
    String? description,
    required List<List<double>> geometry,
    required bool isActive,
  }) async {
    try {
      await _operationsRepository.createPolygon(
        name: name,
        address: address,
        description: description,
        geometry: geometry,
        isActive: isActive,
      );
      await refresh();
    } catch (e) {
      debugPrint('Error creating polygon: $e');
      rethrow;
    }
  }

  /// Создать камеру
  Future<void> createCamera({
    required String polygonId,
    required CameraType type,
    required String name,
    List<double>? location,
    required bool isActive,
  }) async {
    try {
      await _operationsRepository.createCamera(
        polygonId: polygonId,
        type: type,
        name: name,
        location: location,
        isActive: isActive,
      );
      await refresh();
    } catch (e) {
      debugPrint('Error creating camera: $e');
      rethrow;
    }
  }

  // ==================== Drawing Mode ====================

  /// Установить режим создания
  void setCreateMode(String? mode) {
    state = state.copyWith(
      createMode: mode,
      drawingGeometry: mode != null ? [] : null,
    );
    debugPrint('MonitoringController.setCreateMode: mode=$mode');
  }

  /// Добавить точку при рисовании
  void addDrawingPoint(double lon, double lat) {
    final currentGeometry = List<List<double>>.from(state.drawingGeometry);
    currentGeometry.add([lon, lat]);
    state = state.copyWith(drawingGeometry: currentGeometry);
  }

  /// Очистить геометрию рисования
  void clearDrawingGeometry() {
    state = state.copyWith(drawingGeometry: []);
  }

  /// Завершить рисование
  void finishDrawing() {
    // Геометрия уже сохранена в state.drawingGeometry
    // Можно добавить логику валидации
  }
}

