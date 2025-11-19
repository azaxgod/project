import 'package:akimat_project/modules/dashboard/src/model/areas/cleaning_area.dart';
import 'package:akimat_project/modules/dashboard/src/model/monitoring/vehicle_monitoring.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/user_role.dart';
import 'package:akimat_project/modules/dashboard/src/model/polygons/camera.dart';
import 'package:akimat_project/modules/dashboard/src/model/polygons/polygon.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:akimat_project/modules/dashboard/src/model/organizations/organization.dart';

/// Данные для мониторинга
class MonitoringData {
  final List<CleaningArea> areas;
  final List<Polygon> polygons;
  final List<Camera> cameras;
  final List<VehicleMonitoring> vehicles;
  final List<Organization> contractors; // Подрядчики для маппинга
  final DateTime lastUpdate;

  const MonitoringData({
    required this.areas,
    required this.polygons,
    required this.cameras,
    required this.vehicles,
    required this.contractors,
    required this.lastUpdate,
  });

  MonitoringData copyWith({
    List<CleaningArea>? areas,
    List<Polygon>? polygons,
    List<Camera>? cameras,
    List<VehicleMonitoring>? vehicles,
    List<Organization>? contractors,
    DateTime? lastUpdate,
  }) {
    return MonitoringData(
      areas: areas ?? this.areas,
      polygons: polygons ?? this.polygons,
      cameras: cameras ?? this.cameras,
      vehicles: vehicles ?? this.vehicles,
      contractors: contractors ?? this.contractors,
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
    String? selectedVehicleId,
    VehicleTrack? selectedVehicleTrack,
    CleaningAreaStatus? statusFilter,
    String? contractorFilter,
    bool? showVehicles,
    bool? showAreas,
    bool? showPolygons,
    bool? showCameras,
    String? createMode,
    List<List<double>>? drawingGeometry,
  }) {
    return MonitoringState(
      data: data ?? this.data,
      role: role ?? this.role,
      organizationId: organizationId ?? this.organizationId,
      selectedTab: selectedTab ?? this.selectedTab,
      selectedAreaId: selectedAreaId ?? this.selectedAreaId,
      selectedPolygonId: selectedPolygonId ?? this.selectedPolygonId,
      selectedVehicleId: selectedVehicleId ?? this.selectedVehicleId,
      selectedVehicleTrack: selectedVehicleTrack ?? this.selectedVehicleTrack,
      statusFilter: statusFilter ?? this.statusFilter,
      contractorFilter: contractorFilter ?? this.contractorFilter,
      showVehicles: showVehicles ?? this.showVehicles,
      showAreas: showAreas ?? this.showAreas,
      showPolygons: showPolygons ?? this.showPolygons,
      showCameras: showCameras ?? this.showCameras,
      createMode: createMode ?? this.createMode,
      drawingGeometry: drawingGeometry ?? this.drawingGeometry,
    );
  }
}

