import 'package:akimat_project/modules/dashboard/src/model/areas/cleaning_area.dart';
import 'package:akimat_project/modules/dashboard/src/model/monitoring/vehicle_monitoring.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/user_role.dart';
import 'package:akimat_project/modules/dashboard/src/model/polygons/camera.dart';
import 'package:akimat_project/modules/dashboard/src/model/polygons/polygon.dart';
import 'package:akimat_project/modules/dashboard/src/model/polygons/polygon_access.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:akimat_project/modules/dashboard/src/model/organizations/organization.dart';

/// Данные для мониторинга
class MonitoringData {
  final List<CleaningArea> areas;
  final List<Polygon> polygons;
  final List<Camera> cameras;
  final List<VehicleMonitoring> vehicles;
  final List<Organization> contractors; // Подрядчики для маппинга
  final Map<String, List<PolygonAccess>> polygonAccesses; // Доступы к полигонам: polygonId -> список доступов
  final DateTime lastUpdate;

  const MonitoringData({
    required this.areas,
    required this.polygons,
    required this.cameras,
    required this.vehicles,
    required this.contractors,
    required this.polygonAccesses,
    required this.lastUpdate,
  });

  MonitoringData copyWith({
    List<CleaningArea>? areas,
    List<Polygon>? polygons,
    List<Camera>? cameras,
    List<VehicleMonitoring>? vehicles,
    List<Organization>? contractors,
    Map<String, List<PolygonAccess>>? polygonAccesses,
    DateTime? lastUpdate,
  }) {
    return MonitoringData(
      areas: areas ?? this.areas,
      polygons: polygons ?? this.polygons,
      cameras: cameras ?? this.cameras,
      vehicles: vehicles ?? this.vehicles,
      contractors: contractors ?? this.contractors,
      polygonAccesses: polygonAccesses ?? this.polygonAccesses,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }
}

/// Состояние мониторинга
class MonitoringState {
  final AsyncValue<MonitoringData> data;
  final UserRole role;
  final String? organizationId;
  final String? selectedTab; // 'areas' или 'polygons'
  final String? selectedAreaId;
  final String? selectedPolygonId;
  final String? selectedVehicleId;
  final VehicleTrack? selectedVehicleTrack;
  final CleaningAreaStatus? statusFilter;
  final String? contractorFilter;
  final bool showVehicles;
  final bool showAreas;
  final bool showPolygons;
  final bool showCameras;
  final String? createMode; // 'area', 'polygon', 'camera', null
  final List<List<double>> drawingGeometry; // [[lon, lat], ...]
  final bool isEditingGeometry; // Режим редактирования геометрии (можно удалять точки)

  const MonitoringState({
    required this.data,
    required this.role,
    this.organizationId,
    this.selectedTab,
    this.selectedAreaId,
    this.selectedPolygonId,
    this.selectedVehicleId,
    this.selectedVehicleTrack,
    this.statusFilter,
    this.contractorFilter,
    this.showVehicles = true,
    this.showAreas = true,
    this.showPolygons = true,
    this.showCameras = true,
    this.createMode,
    this.drawingGeometry = const [],
    this.isEditingGeometry = false,
  });

  factory MonitoringState.initial({
    required UserRole role,
    String? organizationId,
  }) {
    return MonitoringState(
      data: const AsyncLoading(),
      role: role,
      organizationId: organizationId,
      selectedTab: 'areas',
    );
  }

  MonitoringState copyWith({
    AsyncValue<MonitoringData>? data,
    UserRole? role,
    String? organizationId,
    String? selectedTab,
    String? selectedAreaId,
    String? selectedPolygonId,
    Object? selectedVehicleId = _keepSelectedVehicleId,
    Object? selectedVehicleTrack = _keepSelectedVehicleTrack,
    CleaningAreaStatus? statusFilter,
    String? contractorFilter,
    bool? showVehicles,
    bool? showAreas,
    bool? showPolygons,
    bool? showCameras,
    Object? createMode = _keepCreateMode,
    Object? drawingGeometry = _keepDrawingGeometry,
    bool? isEditingGeometry,
  }) {
    return MonitoringState(
      data: data ?? this.data,
      role: role ?? this.role,
      organizationId: organizationId ?? this.organizationId,
      selectedTab: selectedTab ?? this.selectedTab,
      selectedAreaId: selectedAreaId ?? this.selectedAreaId,
      selectedPolygonId: selectedPolygonId ?? this.selectedPolygonId,
      // ВАЖНО: Используем паттерн с Object? для nullable полей, чтобы можно было явно установить null
      selectedVehicleId: selectedVehicleId == _keepSelectedVehicleId 
          ? this.selectedVehicleId 
          : selectedVehicleId as String?,
      selectedVehicleTrack: selectedVehicleTrack == _keepSelectedVehicleTrack 
          ? this.selectedVehicleTrack 
          : selectedVehicleTrack as VehicleTrack?,
      statusFilter: statusFilter ?? this.statusFilter,
      contractorFilter: contractorFilter ?? this.contractorFilter,
      showVehicles: showVehicles ?? this.showVehicles,
      showAreas: showAreas ?? this.showAreas,
      showPolygons: showPolygons ?? this.showPolygons,
      showCameras: showCameras ?? this.showCameras,
      createMode: createMode == _keepCreateMode ? this.createMode : createMode as String?,
      drawingGeometry: drawingGeometry == _keepDrawingGeometry 
          ? this.drawingGeometry 
          : _parseDrawingGeometry(drawingGeometry),
      isEditingGeometry: isEditingGeometry ?? this.isEditingGeometry,
    );
  }

  static const _keepCreateMode = Object();
  static const _keepDrawingGeometry = Object();
  static const _keepSelectedVehicleId = Object();
  static const _keepSelectedVehicleTrack = Object();

  /// Безопасное приведение drawingGeometry к правильному типу
  static List<List<double>> _parseDrawingGeometry(Object? value) {
    if (value == null) {
      return const <List<double>>[];
    }
    if (value is List<List<double>>) {
      return value;
    }
    if (value is List) {
      // Пытаемся привести к List<List<double>>
      try {
        return value.cast<List<double>>();
      } catch (e) {
        // Если не получилось, возвращаем пустой список
        return const <List<double>>[];
      }
    }
    return const <List<double>>[];
  }
}

