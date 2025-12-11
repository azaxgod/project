import 'dart:async';
import 'package:akimat_project/modules/auth/src/controller/auth_notifier.dart';
import 'package:akimat_project/modules/dashboard/src/controller/areas_controller.dart';
import 'package:akimat_project/modules/dashboard/src/controller/monitoring_state.dart';
import 'package:akimat_project/modules/dashboard/src/model/areas/cleaning_area.dart';
import 'package:akimat_project/modules/dashboard/src/model/monitoring/driver_location.dart';
import 'package:akimat_project/modules/dashboard/src/model/monitoring/vehicle_monitoring.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/driver.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/organization_type.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/user_role.dart';
import 'package:akimat_project/modules/dashboard/src/model/polygons/camera.dart';
import 'package:akimat_project/modules/dashboard/src/model/polygons/polygon.dart';
import 'package:akimat_project/modules/dashboard/src/model/polygons/polygon_access.dart';
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
          // Для CONTRACTOR_ADMIN передаем contractorId в запрос
          final contractorId = state.role == UserRole.contractorAdmin ? state.organizationId : null;
          // Пробуем сначала с onlyActive=true
          areas = await _operationsRepository.loadCleaningAreas(
            status: state.statusFilter,
            onlyActive: true,
            contractorId: contractorId,
          );
          debugPrint('MonitoringController._loadData: Loaded ${areas.length} areas with onlyActive=true, contractorId=$contractorId');
          
          // Если сервер вернул пустой список для CONTRACTOR_ADMIN, это может быть {data: null}
          // В этом случае areas будет пустым списком, и мы создадим заглушки из тикетов ниже
        } catch (e) {
          debugPrint('MonitoringController._loadData: Failed to load areas with onlyActive=true: $e');
          // Fallback: пробуем без onlyActive, если запрос с onlyActive падает
          try {
            debugPrint('MonitoringController._loadData: Retrying without onlyActive parameter');
            final contractorId = state.role == UserRole.contractorAdmin ? state.organizationId : null;
            areas = await _operationsRepository.loadCleaningAreas(
              status: state.statusFilter,
              onlyActive: null,
              contractorId: contractorId,
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
        
        // Для CONTRACTOR_ADMIN создаем заглушки для участков из тикетов, которых нет в списке
        // НЕ пытаемся загружать участки по отдельности через getCleaningArea() - это возвращает 403
        // Создаем минимальные объекты CleaningArea с ID в качестве имени
        Set<String> areaIdsFromTickets = {};
        if (state.role == UserRole.contractorAdmin && state.organizationId != null) {
          try {
            final tickets = await _operationsRepository.loadTickets();
            areaIdsFromTickets = tickets.map((t) => t.cleaningAreaId).toSet();
            debugPrint('MonitoringController._loadData: CONTRACTOR_ADMIN found ${areaIdsFromTickets.length} unique area IDs in tickets');
            debugPrint('MonitoringController._loadData: CONTRACTOR_ADMIN has ${areas.length} areas from loadCleaningAreas()');
            
            // Создаем заглушки для участков из тикетов, которых нет в списке
            final existingAreaIds = areas.map((a) => a.id).toSet();
            final missingAreaIds = areaIdsFromTickets.difference(existingAreaIds);
            
            if (missingAreaIds.isNotEmpty) {
              debugPrint('MonitoringController._loadData: Creating ${missingAreaIds.length} placeholder CleaningArea objects for missing areas');
              
              for (final areaId in missingAreaIds) {
                // Создаем заглушку с коротким ID в качестве имени
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
                areas.add(placeholderArea);
                debugPrint('MonitoringController._loadData: Created placeholder for area $areaId');
              }
            }
          } catch (e) {
            debugPrint('MonitoringController._loadData: Failed to load tickets for CONTRACTOR_ADMIN: $e');
          }
        }

        // Загружаем полигоны
        debugPrint('MonitoringController._loadData: Loading polygons for role: ${state.role}');
        List<Polygon> polygons = [];
        
        // Для водителя API может возвращать 500, поэтому используем специальную обработку
        if (state.role == UserRole.driver) {
          try {
            // Пробуем сначала без onlyActive для водителя (может быть проблема с бэкендом)
            debugPrint('MonitoringController._loadData: DRIVER role - trying to load polygons without onlyActive');
            polygons = await _operationsRepository.loadPolygons(onlyActive: null);
            // Фильтруем только активные на клиенте
            polygons = polygons.where((polygon) => polygon.isActive).toList();
            debugPrint('MonitoringController._loadData: DRIVER - Loaded ${polygons.length} active polygons without onlyActive filter');
          } catch (e) {
            debugPrint('MonitoringController._loadData: DRIVER - Failed to load polygons without onlyActive: $e');
            // Пробуем с onlyActive как fallback
            try {
              debugPrint('MonitoringController._loadData: DRIVER - Retrying with onlyActive=true');
              polygons = await _operationsRepository.loadPolygons(onlyActive: true);
              debugPrint('MonitoringController._loadData: DRIVER - Loaded ${polygons.length} polygons with onlyActive=true');
            } catch (e2) {
              debugPrint('MonitoringController._loadData: DRIVER - Failed to load polygons with onlyActive=true: $e2');
              polygons = []; // Продолжаем с пустым списком
            }
          }
        } else {
          // Для остальных ролей используем стандартную логику
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

        // Загружаем локации водителей (для ролей, которые должны их видеть)
        debugPrint('MonitoringController._loadData: Loading driver locations for role: ${state.role}');
        List<VehicleMonitoring> driverVehicles = [];
        if (state.role == UserRole.akimatAdmin || 
            state.role == UserRole.kguZkhAdmin || 
            state.role == UserRole.contractorAdmin) {
          try {
            debugPrint('MonitoringController._loadData: Role ${state.role} has access to driver locations, loading...');
            // Загружаем локации водителей
            final driversLocationsData = await _operationsRepository.getDriversLocations();
            debugPrint('MonitoringController._loadData: Received driver locations data: ${driversLocationsData.keys}');
            
            // API может возвращать данные в формате:
            // {data: {drivers: [...]}} или {drivers: [...]} или {data: {locations: [...]}} или {locations: [...]}
            List<dynamic> driversLocationsList = [];
            if (driversLocationsData.containsKey('data')) {
              final data = driversLocationsData['data'] as Map<String, dynamic>?;
              // Проверяем оба варианта: drivers и locations
              driversLocationsList = data?['drivers'] as List<dynamic>? ?? 
                                     data?['locations'] as List<dynamic>? ?? [];
              debugPrint('MonitoringController._loadData: Found drivers in data: ${driversLocationsList.length}');
            } else if (driversLocationsData.containsKey('drivers')) {
              driversLocationsList = driversLocationsData['drivers'] as List<dynamic>? ?? [];
              debugPrint('MonitoringController._loadData: Found drivers in drivers: ${driversLocationsList.length}');
            } else if (driversLocationsData.containsKey('locations')) {
              driversLocationsList = driversLocationsData['locations'] as List<dynamic>? ?? [];
              debugPrint('MonitoringController._loadData: Found drivers in locations: ${driversLocationsList.length}');
            } else {
              debugPrint('MonitoringController._loadData: No drivers found in response, keys: ${driversLocationsData.keys}');
            }
            debugPrint('MonitoringController._loadData: Loaded ${driversLocationsList.length} driver locations');
            
            // Загружаем список водителей для получения contractorId
            List<Driver> allDrivers = [];
            try {
              allDrivers = await _organizationsRepository.loadDrivers();
              debugPrint('MonitoringController._loadData: Loaded ${allDrivers.length} drivers');
            } catch (e) {
              debugPrint('MonitoringController._loadData: Failed to load drivers: $e');
            }
            
            // Создаем Map для быстрого поиска водителя по ID
            final driversMap = {for (var d in allDrivers) d.id: d};
            
            // Преобразуем локации водителей в VehicleMonitoring объекты
            for (final locationJson in driversLocationsList) {
              try {
                final driverLocation = DriverLocation.fromJson(locationJson as Map<String, dynamic>);
                final driver = driversMap[driverLocation.driverId];
                
                // Применяем фильтрацию по ролям
                if (state.role == UserRole.contractorAdmin) {
                  // Подрядчик видит только своих водителей
                  if (driver == null || driver.contractorId != state.organizationId) {
                    continue;
                  }
                } else if (state.role == UserRole.akimatAdmin || state.role == UserRole.kguZkhAdmin) {
                  // KGU и Akimat видят всех водителей - не фильтруем
                  debugPrint('MonitoringController._loadData: KGU/Akimat admin - showing all drivers, driverId: ${driverLocation.driverId}');
                }
                
                // Преобразуем локацию водителя в VehicleMonitoring
                final driverVehicle = _driverLocationToVehicleMonitoring(
                  driverLocation: driverLocation,
                  driver: driver,
                );
                driverVehicles.add(driverVehicle);
              } catch (e) {
                debugPrint('MonitoringController._loadData: Error parsing driver location: $e');
              }
            }
            debugPrint('MonitoringController._loadData: Created ${driverVehicles.length} vehicle objects from driver locations for role ${state.role}');
          } catch (e, stackTrace) {
            debugPrint('MonitoringController._loadData: Failed to load driver locations for role ${state.role}: $e');
            debugPrint('MonitoringController._loadData: Stack trace: $stackTrace');
            // Продолжаем без локаций водителей, чтобы не блокировать загрузку других данных
          }
        } else {
          debugPrint('MonitoringController._loadData: Role ${state.role} does not have access to driver locations');
        }

        // Объединяем технику и водителей
        final allVehicles = [...vehicles, ...driverVehicles];
        debugPrint('MonitoringController._loadData: Total vehicles (including drivers): ${allVehicles.length}');

        // Загружаем доступы к полигонам ПЕРЕД фильтрацией
        // (нужно для фильтрации полигонов по доступам для подрядчиков)
        // ВАЖНО: Подрядчик не должен загружать доступы через API (403 Forbidden)
        // API /polygons уже возвращает только доступные полигоны для подрядчика
        debugPrint('MonitoringController._loadData: Loading polygon accesses before filtering');
        final polygonAccessesBeforeFilter = <String, List<PolygonAccess>>{};
        
        // Загружаем доступы только для KGU и Akimat (им нужно видеть все доступы)
        // Для подрядчика API /polygons уже фильтрует по доступам
        if (state.role == UserRole.kguZkhAdmin || state.role == UserRole.akimatAdmin) {
          for (final polygon in polygons) {
            try {
              final accesses = await _operationsRepository.getPolygonAccess(polygon.id);
              debugPrint('MonitoringController._loadData: Loaded ${accesses.length} total accesses for polygon ${polygon.id}');
              polygonAccessesBeforeFilter[polygon.id] = accesses;
            } catch (e) {
              debugPrint('MonitoringController._loadData: Failed to load accesses for polygon ${polygon.id}: $e');
              polygonAccessesBeforeFilter[polygon.id] = [];
            }
          }
          debugPrint('MonitoringController._loadData: Loaded accesses for ${polygonAccessesBeforeFilter.length} polygons before filtering');
        } else {
          debugPrint('MonitoringController._loadData: Skipping polygon access loading for role ${state.role} (API /polygons already filters by access)');
        }

        // Фильтруем данные по ролям
        debugPrint('MonitoringController._loadData: Filtering data by role');
        final filteredAreas = _filterAreasByRole(areas, areaIdsFromTickets);
        final filteredPolygons = _filterPolygonsByRole(polygons, polygonAccessesBeforeFilter);
        final filteredCameras = _filterCamerasByRole(cameras, polygons);
        final filteredVehicles = _filterVehiclesByRole(allVehicles);

        // Объединяем все камеры в один список
        final allCameras = <Camera>[];
        for (final cameraList in cameras.values) {
          allCameras.addAll(cameraList);
        }

        // Загружаем доступы к полигонам для отображения (после фильтрации)
        // ВАЖНО: Подрядчик не должен загружать доступы (403 Forbidden)
        debugPrint('MonitoringController._loadData: Loading polygon accesses for display');
        final polygonAccesses = <String, List<PolygonAccess>>{};
        
        // Для KGU и Akimat используем уже загруженные доступы
        // Для подрядчика не загружаем доступы (API /polygons уже фильтрует)
        if (state.role == UserRole.kguZkhAdmin || state.role == UserRole.akimatAdmin) {
          for (final polygon in filteredPolygons) {
            try {
              // Используем уже загруженные доступы
              final accesses = polygonAccessesBeforeFilter[polygon.id] ?? [];
              debugPrint('MonitoringController._loadData: Using ${accesses.length} accesses for polygon ${polygon.id}');
              // KGU и Akimat видят все доступы
              polygonAccesses[polygon.id] = accesses;
              debugPrint('MonitoringController._loadData: Added ${accesses.length} accesses for polygon ${polygon.id} (role: ${state.role})');
            } catch (e) {
              debugPrint('MonitoringController._loadData: Failed to get accesses for polygon ${polygon.id}: $e');
              polygonAccesses[polygon.id] = [];
            }
          }
          debugPrint('MonitoringController._loadData: Loaded accesses for ${polygonAccesses.length} polygons');
        } else {
          // Для подрядчика и других ролей не загружаем доступы
          debugPrint('MonitoringController._loadData: Skipping polygon access loading for role ${state.role}');
          // Инициализируем пустые списки для всех полигонов
          for (final polygon in filteredPolygons) {
            polygonAccesses[polygon.id] = [];
          }
        }

        debugPrint('MonitoringController._loadData: Creating MonitoringData');
        final data = MonitoringData(
          areas: filteredAreas,
          polygons: filteredPolygons,
          cameras: filteredCameras,
          vehicles: filteredVehicles,
          contractors: contractors, // Добавляем подрядчиков для маппинга
          polygonAccesses: polygonAccesses, // Добавляем доступы к полигонам
          lastUpdate: DateTime.now(),
        );
        debugPrint('MonitoringController._loadData: Data loaded successfully');
        return data;
      }),
    );
  }

  /// Фильтрация участков по ролям
  List<CleaningArea> _filterAreasByRole(List<CleaningArea> areas, Set<String> areaIdsFromTickets) {
    switch (state.role) {
      case UserRole.akimatAdmin:
      case UserRole.kguZkhAdmin:
      case UserRole.landfillAdmin:
        return areas; // Видят все участки (LANDFILL_ADMIN может просматривать, но не создавать)
      case UserRole.contractorAdmin:
        // Видят участки, где они назначены как подрядчик по умолчанию ИЛИ участки из их тикетов
        if (state.organizationId != null) {
          final filtered = areas
              .where((area) => 
                  area.defaultContractorId == state.organizationId || 
                  areaIdsFromTickets.contains(area.id))
              .toList();
          debugPrint('MonitoringController._filterAreasByRole: CONTRACTOR_ADMIN organizationId=${state.organizationId}, totalAreas=${areas.length}, areaIdsFromTickets=${areaIdsFromTickets.length}, filteredAreas=${filtered.length}');
          return filtered;
        }
        debugPrint('MonitoringController._filterAreasByRole: CONTRACTOR_ADMIN organizationId is null, returning empty list');
        return [];
      case UserRole.driver:
        // Видят только участки, где есть активные тикеты
        // TODO: Реализовать фильтрацию по тикетам водителя через Operations Service
        return areas;
      default:
        return [];
    }
  }

  /// Фильтрация полигонов по ролям
  List<Polygon> _filterPolygonsByRole(
    List<Polygon> polygons,
    Map<String, List<PolygonAccess>> polygonAccesses,
  ) {
    switch (state.role) {
      case UserRole.akimatAdmin:
      case UserRole.kguZkhAdmin:
      case UserRole.landfillAdmin:
        return polygons; // Видят все полигоны
      case UserRole.contractorAdmin:
        // Подрядчик: API /polygons уже возвращает только доступные полигоны
        // Не нужно дополнительно фильтровать по доступам
        debugPrint('MonitoringController._filterPolygonsByRole: CONTRACTOR_ADMIN - API already filtered polygons, returning ${polygons.length} polygons');
        return polygons;
      case UserRole.driver:
        // Водитель видит полигоны своего подрядчика
        // API /polygons уже фильтрует по подрядчику водителя
        debugPrint('MonitoringController._filterPolygonsByRole: DRIVER - API already filtered polygons, returning ${polygons.length} polygons');
        return polygons;
      default:
        return [];
    }
  }

  /// Фильтрация камер по ролям
  List<Camera> _filterCamerasByRole(Map<String, List<Camera>> cameras, List<Polygon> polygons) {
    switch (state.role) {
      case UserRole.akimatAdmin:
      case UserRole.kguZkhAdmin:
      case UserRole.landfillAdmin:
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
        return vehicles; // Видят всю технику и всех водителей
      case UserRole.landfillAdmin:
        return vehicles; // Видят всю технику (но не участки)
      case UserRole.contractorAdmin:
        // Видят только свою технику и своих водителей
        // Фильтрация уже применена при создании driverVehicles, но применяем еще раз для безопасности
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

  /// Преобразование локации водителя в VehicleMonitoring объект
  VehicleMonitoring _driverLocationToVehicleMonitoring({
    required DriverLocation driverLocation,
    Driver? driver,
  }) {
    // Определяем статус на основе времени обновления
    final now = DateTime.now();
    final timeDiff = now.difference(driverLocation.updatedAt);
    VehicleStatus status;
    if (timeDiff.inMinutes < 2) {
      status = VehicleStatus.inTrip;
    } else if (timeDiff.inMinutes < 5) {
      status = VehicleStatus.idle;
    } else {
      status = VehicleStatus.offline;
    }

    // Создаем GPS точку из локации водителя
    final gpsPoint = GpsPoint(
      lat: driverLocation.lat,
      lon: driverLocation.lon,
      capturedAt: driverLocation.updatedAt,
      speedKmh: 0.0, // У водителей нет данных о скорости из GPS телефона
      headingDeg: 0.0, // У водителей нет данных о направлении из GPS телефона
      isSimulated: false,
    );

    // Создаем VehicleMonitoring объект
    // Используем driver_id как vehicle_id с префиксом "driver_" для отличия от реальных транспортных средств
    final driverIdShort = driverLocation.driverId.length >= 8 
        ? driverLocation.driverId.substring(0, 8) 
        : driverLocation.driverId;
    return VehicleMonitoring(
      vehicleId: 'driver_${driverLocation.driverId}',
      plateNumber: driver != null ? 'Водитель: ${driver.fullName}' : 'Водитель: $driverIdShort',
      contractorId: driver?.contractorId,
      contractorName: null, // Можно добавить позже, если нужно
      lastGps: gpsPoint,
      lastTicketId: null,
      lastCleaningAreaId: null,
      lastPolygonId: null,
      status: status,
    );
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

      // Загружаем локации водителей (для ролей, которые должны их видеть)
      List<VehicleMonitoring> driverVehicles = [];
      if (state.role == UserRole.akimatAdmin || 
          state.role == UserRole.kguZkhAdmin || 
          state.role == UserRole.contractorAdmin) {
        try {
          debugPrint('MonitoringController._updateVehicles: Role ${state.role} has access to driver locations, loading...');
          // Загружаем локации водителей
          final driversLocationsData = await _operationsRepository.getDriversLocations();
          debugPrint('MonitoringController._updateVehicles: Received driver locations data: ${driversLocationsData.keys}');
          
          // API может возвращать данные в формате:
          // {data: {drivers: [...]}} или {drivers: [...]} или {data: {locations: [...]}} или {locations: [...]}
          List<dynamic> driversLocationsList = [];
          if (driversLocationsData.containsKey('data')) {
            final data = driversLocationsData['data'] as Map<String, dynamic>?;
            // Проверяем оба варианта: drivers и locations
            driversLocationsList = data?['drivers'] as List<dynamic>? ?? 
                                   data?['locations'] as List<dynamic>? ?? [];
            debugPrint('MonitoringController._updateVehicles: Found drivers in data: ${driversLocationsList.length}');
          } else if (driversLocationsData.containsKey('drivers')) {
            driversLocationsList = driversLocationsData['drivers'] as List<dynamic>? ?? [];
            debugPrint('MonitoringController._updateVehicles: Found drivers in drivers: ${driversLocationsList.length}');
          } else if (driversLocationsData.containsKey('locations')) {
            driversLocationsList = driversLocationsData['locations'] as List<dynamic>? ?? [];
            debugPrint('MonitoringController._updateVehicles: Found drivers in locations: ${driversLocationsList.length}');
          } else {
            debugPrint('MonitoringController._updateVehicles: No drivers found in response, keys: ${driversLocationsData.keys}');
          }
          debugPrint('MonitoringController._updateVehicles: Loaded ${driversLocationsList.length} driver locations');
          
          // Загружаем список водителей для получения contractorId
          List<Driver> allDrivers = [];
          try {
            allDrivers = await _organizationsRepository.loadDrivers();
          } catch (e) {
            debugPrint('MonitoringController._updateVehicles: Failed to load drivers: $e');
          }
          
          // Создаем Map для быстрого поиска водителя по ID
          final driversMap = {for (var d in allDrivers) d.id: d};
          
          // Преобразуем локации водителей в VehicleMonitoring объекты
          for (final locationJson in driversLocationsList) {
            try {
              final driverLocation = DriverLocation.fromJson(locationJson as Map<String, dynamic>);
              final driver = driversMap[driverLocation.driverId];
              
              // Применяем фильтрацию по ролям
              if (state.role == UserRole.contractorAdmin) {
                // Подрядчик видит только своих водителей
                if (driver == null || driver.contractorId != state.organizationId) {
                  continue;
                }
              } else if (state.role == UserRole.akimatAdmin || state.role == UserRole.kguZkhAdmin) {
                // KGU и Akimat видят всех водителей - не фильтруем
                debugPrint('MonitoringController._updateVehicles: KGU/Akimat admin - showing all drivers, driverId: ${driverLocation.driverId}');
              }
              
              // Преобразуем локацию водителя в VehicleMonitoring
              final driverVehicle = _driverLocationToVehicleMonitoring(
                driverLocation: driverLocation,
                driver: driver,
              );
              driverVehicles.add(driverVehicle);
            } catch (e) {
              debugPrint('MonitoringController._updateVehicles: Error parsing driver location: $e');
            }
          }
          debugPrint('MonitoringController._updateVehicles: Created ${driverVehicles.length} vehicle objects from driver locations for role ${state.role}');
        } catch (e, stackTrace) {
          debugPrint('MonitoringController._updateVehicles: Failed to load driver locations for role ${state.role}: $e');
          debugPrint('MonitoringController._updateVehicles: Stack trace: $stackTrace');
          // Продолжаем без локаций водителей, чтобы не блокировать обновление других данных
        }
      } else {
        debugPrint('MonitoringController._updateVehicles: Role ${state.role} does not have access to driver locations');
      }

      // Объединяем технику и водителей
      final allVehicles = [...vehicles, ...driverVehicles];
      debugPrint('MonitoringController._updateVehicles: Total vehicles (including drivers): ${allVehicles.length}');

      final filteredVehicles = _filterVehiclesByRole(allVehicles);
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

  /// Привязать подрядчика к полигону
  Future<void> grantPolygonAccessToContractor(
    String polygonId, {
    required String contractorId,
  }) async {
    try {
      await _operationsRepository.grantPolygonAccess(
        polygonId,
        contractorId: contractorId,
        source: 'MANUAL', // Ручная привязка через UI
      );
      // Обновляем данные после привязки
      await _loadData();
    } catch (e) {
      debugPrint('MonitoringController.grantPolygonAccessToContractor: Error: $e');
      rethrow;
    }
  }

  /// Выбор техники и загрузка трека
  Future<void> selectVehicle(String? vehicleId) async {
    // Обновляем selectedVehicleId и очищаем трек в одном обновлении состояния
    state = state.copyWith(
      selectedVehicleId: vehicleId,
      selectedVehicleTrack: null, // Очищаем трек при смене или снятии выбора
    );
    
    if (vehicleId == null) {
      // Если vehicleId null, просто скрываем виджет
      return;
    }

    // Загружаем трек для выбранной машины
    try {
      final track = await _operationsRepository.getVehicleTrack(
        vehicleId,
        from: DateTime.now().subtract(const Duration(hours: 1)),
        to: DateTime.now(),
      );
      state = state.copyWith(selectedVehicleTrack: track);
    } catch (e) {
      // Игнорируем ошибки, но оставляем selectedVehicleId установленным
      debugPrint('Error loading vehicle track: $e');
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
    debugPrint('MonitoringController.setCreateMode: called with mode=$mode');
    debugPrint('MonitoringController.setCreateMode: current state.createMode=${state.createMode}');
    debugPrint('MonitoringController.setCreateMode: current state.hashCode=${state.hashCode}');
    
    // ВАЖНО: Используем явную передачу null для createMode и drawingGeometry
    // чтобы можно было закрыть панель (установить createMode в null)
    final newState = state.copyWith(
      createMode: mode, // Передаем напрямую, включая null
      drawingGeometry: mode != null ? const <List<double>>[] : null, // Если режим null, то и геометрия null
    );
    
    debugPrint('MonitoringController.setCreateMode: new state.createMode=${newState.createMode}');
    debugPrint('MonitoringController.setCreateMode: new state.drawingGeometry=${newState.drawingGeometry}');
    debugPrint('MonitoringController.setCreateMode: new state.hashCode=${newState.hashCode}');
    
    // ВАЖНО: Используем state = для StateNotifier, чтобы уведомить слушателей
    state = newState;
    
    debugPrint('MonitoringController.setCreateMode: state updated successfully');
    debugPrint('MonitoringController.setCreateMode: After update, state.createMode=${state.createMode}');
  }

  /// Добавить точку при рисовании
  /// Для камеры: заменяет предыдущую точку (только 1 точка)
  /// Для участков/полигонов: добавляет точку к списку
  void addDrawingPoint(double lon, double lat) {
    final currentGeometry = List<List<double>>.from(state.drawingGeometry);
    
    // Для камеры: заменяем точку (только 1 точка)
    if (state.createMode == 'camera') {
      state = state.copyWith(drawingGeometry: [[lon, lat]]);
    } else {
      // Для участков и полигонов: добавляем точку
      currentGeometry.add([lon, lat]);
      state = state.copyWith(drawingGeometry: currentGeometry);
    }
  }

  /// Очистить геометрию рисования
  void clearDrawingGeometry() {
    state = state.copyWith(drawingGeometry: [], isEditingGeometry: false);
  }

  /// Включить режим редактирования геометрии
  void enableEditingGeometry() {
    state = state.copyWith(isEditingGeometry: true);
  }

  /// Выключить режим редактирования геометрии
  void disableEditingGeometry() {
    state = state.copyWith(isEditingGeometry: false);
  }

  /// Удалить точку по индексу
  void removeDrawingPoint(int index) {
    if (index >= 0 && index < state.drawingGeometry.length) {
      final currentGeometry = List<List<double>>.from(state.drawingGeometry);
      currentGeometry.removeAt(index);
      state = state.copyWith(drawingGeometry: currentGeometry);
    }
  }

  /// Сохранить геометрию (без отправки на сервер)
  void saveGeometry() {
    // Геометрия уже сохранена в state.drawingGeometry
    // Просто выключаем режим редактирования
    state = state.copyWith(isEditingGeometry: false);
  }

  /// Завершить рисование (отправка на сервер через форму)
  void finishDrawing() {
    // Геометрия уже сохранена в state.drawingGeometry
    // Выключаем режим редактирования, форма сама отправит данные
    state = state.copyWith(isEditingGeometry: false);
  }
}

