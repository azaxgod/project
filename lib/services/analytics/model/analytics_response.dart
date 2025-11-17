// Модели ответов API аналитики

class DashboardResponse {
  final DashboardData data;

  DashboardResponse({required this.data});

  factory DashboardResponse.fromJson(Map<String, dynamic> json) {
    return DashboardResponse(
      data: DashboardData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}

class DashboardData {
  final DashboardStats stats;
  final DashboardContractors contractors;
  final List<DashboardContract> contracts;
  final DashboardMap map;
  final List<DashboardCamera> cameras;

  DashboardData({
    required this.stats,
    required this.contractors,
    required this.contracts,
    required this.map,
    required this.cameras,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      stats: DashboardStats.fromJson(json['stats'] as Map<String, dynamic>),
      contractors: DashboardContractors.fromJson(json['contractors'] as Map<String, dynamic>),
      contracts: (json['contracts'] as List<dynamic>?)
          ?.map((e) => DashboardContract.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      map: DashboardMap.fromJson(json['map'] as Map<String, dynamic>),
      cameras: (json['cameras'] as List<dynamic>?)
          ?.map((e) => DashboardCamera.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
}

class DashboardStats {
  final int activeTrips;
  final int completedTrips;
  final int violations;
  final int ticketsInProgress;

  DashboardStats({
    required this.activeTrips,
    required this.completedTrips,
    required this.violations,
    required this.ticketsInProgress,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      activeTrips: json['active_trips'] as int? ?? 0,
      completedTrips: json['completed_trips'] as int? ?? 0,
      violations: json['violations'] as int? ?? 0,
      ticketsInProgress: json['tickets_in_progress'] as int? ?? 0,
    );
  }
}

class DashboardContractors {
  final List<DashboardContractor> active;
  final List<DashboardContractor> idle;

  DashboardContractors({
    required this.active,
    required this.idle,
  });

  factory DashboardContractors.fromJson(Map<String, dynamic> json) {
    return DashboardContractors(
      active: (json['active'] as List<dynamic>?)
          ?.map((e) => DashboardContractor.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      idle: (json['idle'] as List<dynamic>?)
          ?.map((e) => DashboardContractor.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
}

class DashboardContractor {
  final String id;
  final String name;
  final int? count;
  final double? share;

  DashboardContractor({
    required this.id,
    required this.name,
    this.count,
    this.share,
  });

  factory DashboardContractor.fromJson(Map<String, dynamic> json) {
    return DashboardContractor(
      id: json['id'] as String,
      name: json['name'] as String,
      count: json['count'] as int?,
      share: (json['share'] as num?)?.toDouble(),
    );
  }
}

class DashboardContract {
  final String contractId;
  final String? uiStatus;
  final double? budgetProgress;
  final double? volumeProgress;

  DashboardContract({
    required this.contractId,
    this.uiStatus,
    this.budgetProgress,
    this.volumeProgress,
  });

  factory DashboardContract.fromJson(Map<String, dynamic> json) {
    return DashboardContract(
      contractId: json['contract_id'] as String,
      uiStatus: json['ui_status'] as String?,
      budgetProgress: (json['budget_progress'] as num?)?.toDouble(),
      volumeProgress: (json['volume_progress'] as num?)?.toDouble(),
    );
  }
}

class DashboardMap {
  final List<DashboardArea> areas;
  final List<DashboardPolygon> polygons;
  final List<DashboardMapCamera> cameras;

  DashboardMap({
    required this.areas,
    required this.polygons,
    required this.cameras,
  });

  factory DashboardMap.fromJson(Map<String, dynamic> json) {
    return DashboardMap(
      areas: (json['areas'] as List<dynamic>?)
          ?.map((e) => DashboardArea.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      polygons: (json['polygons'] as List<dynamic>?)
          ?.map((e) => DashboardPolygon.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      cameras: (json['cameras'] as List<dynamic>?)
          ?.map((e) => DashboardMapCamera.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
}

class DashboardArea {
  final String id;
  final bool hasTrips;
  final double? intensity;

  DashboardArea({
    required this.id,
    required this.hasTrips,
    this.intensity,
  });

  factory DashboardArea.fromJson(Map<String, dynamic> json) {
    return DashboardArea(
      id: json['id'] as String,
      hasTrips: json['has_trips'] as bool? ?? false,
      intensity: (json['intensity'] as num?)?.toDouble(),
    );
  }
}

class DashboardPolygon {
  final String id;
  final int? tripCount;
  final double? volumeM3;

  DashboardPolygon({
    required this.id,
    this.tripCount,
    this.volumeM3,
  });

  factory DashboardPolygon.fromJson(Map<String, dynamic> json) {
    return DashboardPolygon(
      id: json['id'] as String,
      tripCount: json['trip_count'] as int?,
      volumeM3: (json['volume_m3'] as num?)?.toDouble(),
    );
  }
}

class DashboardMapCamera {
  final String cameraId;
  final int? errorEvents;

  DashboardMapCamera({
    required this.cameraId,
    this.errorEvents,
  });

  factory DashboardMapCamera.fromJson(Map<String, dynamic> json) {
    return DashboardMapCamera(
      cameraId: json['camera_id'] as String,
      errorEvents: json['error_events'] as int?,
    );
  }
}

class DashboardCamera {
  final String cameraId;
  final int? lprEvents;
  final int? volumeEvents;
  final double? errorRate;

  DashboardCamera({
    required this.cameraId,
    this.lprEvents,
    this.volumeEvents,
    this.errorRate,
  });

  factory DashboardCamera.fromJson(Map<String, dynamic> json) {
    return DashboardCamera(
      cameraId: json['camera_id'] as String,
      lprEvents: json['lpr_events'] as int?,
      volumeEvents: json['volume_events'] as int?,
      errorRate: (json['error_rate'] as num?)?.toDouble(),
    );
  }
}

// Trips Analytics
class TripsAnalyticsResponse {
  final TripsAnalyticsData data;

  TripsAnalyticsResponse({required this.data});

  factory TripsAnalyticsResponse.fromJson(Map<String, dynamic> json) {
    return TripsAnalyticsResponse(
      data: TripsAnalyticsData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}

class TripsAnalyticsData {
  final List<TimeSeriesPoint> series;
  final List<VolumeTimeSeriesPoint> volumeSeries;
  final List<TopDriver> topDrivers;
  final List<TopContractor> topContractors;
  final DurationStats? durationStats;
  final VolumeStats? volumeStats;

  TripsAnalyticsData({
    required this.series,
    required this.volumeSeries,
    required this.topDrivers,
    required this.topContractors,
    this.durationStats,
    this.volumeStats,
  });

  factory TripsAnalyticsData.fromJson(Map<String, dynamic> json) {
    return TripsAnalyticsData(
      series: (json['series'] as List<dynamic>?)
          ?.map((e) => TimeSeriesPoint.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      volumeSeries: (json['volume_series'] as List<dynamic>?)
          ?.map((e) => VolumeTimeSeriesPoint.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      topDrivers: (json['top_drivers'] as List<dynamic>?)
          ?.map((e) => TopDriver.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      topContractors: (json['top_contractors'] as List<dynamic>?)
          ?.map((e) => TopContractor.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      durationStats: json['duration_stats'] != null
          ? DurationStats.fromJson(json['duration_stats'] as Map<String, dynamic>)
          : null,
      volumeStats: json['volume_stats'] != null
          ? VolumeStats.fromJson(json['volume_stats'] as Map<String, dynamic>)
          : null,
    );
  }
}

class TimeSeriesPoint {
  final DateTime bucket;
  final int count;

  TimeSeriesPoint({
    required this.bucket,
    required this.count,
  });

  factory TimeSeriesPoint.fromJson(Map<String, dynamic> json) {
    return TimeSeriesPoint(
      bucket: DateTime.parse(json['bucket'] as String),
      count: json['count'] as int? ?? 0,
    );
  }
}

class VolumeTimeSeriesPoint {
  final DateTime bucket;
  final int count;
  final double value;

  VolumeTimeSeriesPoint({
    required this.bucket,
    required this.count,
    required this.value,
  });

  factory VolumeTimeSeriesPoint.fromJson(Map<String, dynamic> json) {
    return VolumeTimeSeriesPoint(
      bucket: DateTime.parse(json['bucket'] as String),
      count: json['count'] as int? ?? 0,
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class TopDriver {
  final String id;
  final String name;
  final int count;

  TopDriver({
    required this.id,
    required this.name,
    required this.count,
  });

  factory TopDriver.fromJson(Map<String, dynamic> json) {
    return TopDriver(
      id: json['id'] as String,
      name: json['name'] as String,
      count: json['count'] as int? ?? 0,
    );
  }
}

class TopContractor {
  final String id;
  final String name;
  final int count;

  TopContractor({
    required this.id,
    required this.name,
    required this.count,
  });

  factory TopContractor.fromJson(Map<String, dynamic> json) {
    return TopContractor(
      id: json['id'] as String,
      name: json['name'] as String,
      count: json['count'] as int? ?? 0,
    );
  }
}

class DurationStats {
  final int? avgMinutes;
  final int? p90Minutes;

  DurationStats({
    this.avgMinutes,
    this.p90Minutes,
  });

  factory DurationStats.fromJson(Map<String, dynamic> json) {
    return DurationStats(
      avgMinutes: json['avg_minutes'] as int?,
      p90Minutes: json['p90_minutes'] as int?,
    );
  }
}

class VolumeStats {
  final double? avgM3;
  final double? p90M3;

  VolumeStats({
    this.avgM3,
    this.p90M3,
  });

  factory VolumeStats.fromJson(Map<String, dynamic> json) {
    return VolumeStats(
      avgM3: (json['avg_m3'] as num?)?.toDouble(),
      p90M3: (json['p90_m3'] as num?)?.toDouble(),
    );
  }
}

// Trip Detail
class TripDetailResponse {
  final TripDetailData data;

  TripDetailResponse({required this.data});

  factory TripDetailResponse.fromJson(Map<String, dynamic> json) {
    return TripDetailResponse(
      data: TripDetailData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}

class TripDetailData {
  final String tripId;
  final String? driverId;
  final String? driverName;
  final String? contractorId;
  final String? contractorName;
  final String? vehicleId;
  final String? vehicleName;
  final String? ticketId;
  final String? contractId;
  final String? areaId;
  final String? polygonId;
  final DateTime? startTime;
  final DateTime? polygonArrivalTime;
  final DateTime? polygonExitTime;
  final String? lprInUrl;
  final String? volumeInUrl;
  final String? lprOutUrl;
  final String? volumeOutUrl;
  final List<Map<String, dynamic>>? gpsTrack;
  final List<String>? cameraIds;
  final String? status;
  final List<String>? violations;

  TripDetailData({
    required this.tripId,
    this.driverId,
    this.driverName,
    this.contractorId,
    this.contractorName,
    this.vehicleId,
    this.vehicleName,
    this.ticketId,
    this.contractId,
    this.areaId,
    this.polygonId,
    this.startTime,
    this.polygonArrivalTime,
    this.polygonExitTime,
    this.lprInUrl,
    this.volumeInUrl,
    this.lprOutUrl,
    this.volumeOutUrl,
    this.gpsTrack,
    this.cameraIds,
    this.status,
    this.violations,
  });

  factory TripDetailData.fromJson(Map<String, dynamic> json) {
    return TripDetailData(
      tripId: json['trip_id'] as String,
      driverId: json['driver_id'] as String?,
      driverName: json['driver_name'] as String?,
      contractorId: json['contractor_id'] as String?,
      contractorName: json['contractor_name'] as String?,
      vehicleId: json['vehicle_id'] as String?,
      vehicleName: json['vehicle_name'] as String?,
      ticketId: json['ticket_id'] as String?,
      contractId: json['contract_id'] as String?,
      areaId: json['area_id'] as String?,
      polygonId: json['polygon_id'] as String?,
      startTime: json['start_time'] != null
          ? DateTime.parse(json['start_time'] as String)
          : null,
      polygonArrivalTime: json['polygon_arrival_time'] != null
          ? DateTime.parse(json['polygon_arrival_time'] as String)
          : null,
      polygonExitTime: json['polygon_exit_time'] != null
          ? DateTime.parse(json['polygon_exit_time'] as String)
          : null,
      lprInUrl: json['lpr_in_url'] as String?,
      volumeInUrl: json['volume_in_url'] as String?,
      lprOutUrl: json['lpr_out_url'] as String?,
      volumeOutUrl: json['volume_out_url'] as String?,
      gpsTrack: json['gps_track'] != null
          ? (json['gps_track'] as List<dynamic>)
              .map((e) => e as Map<String, dynamic>)
              .toList()
          : null,
      cameraIds: (json['camera_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      status: json['status'] as String?,
      violations: (json['violations'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }
}

// Violations Analytics
class ViolationsAnalyticsResponse {
  final ViolationsAnalyticsData data;

  ViolationsAnalyticsResponse({required this.data});

  factory ViolationsAnalyticsResponse.fromJson(Map<String, dynamic> json) {
    return ViolationsAnalyticsResponse(
      data: ViolationsAnalyticsData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}

class ViolationsAnalyticsData {
  final List<TimeSeriesPoint> series;
  final List<ViolationBreakdown> breakdown;
  final List<TopContractor> topContractors;
  final List<TopDriver> topDrivers;
  final List<TopCamera> topCameras;

  ViolationsAnalyticsData({
    required this.series,
    required this.breakdown,
    required this.topContractors,
    required this.topDrivers,
    required this.topCameras,
  });

  factory ViolationsAnalyticsData.fromJson(Map<String, dynamic> json) {
    return ViolationsAnalyticsData(
      series: (json['series'] as List<dynamic>?)
          ?.map((e) => TimeSeriesPoint.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      breakdown: (json['breakdown'] as List<dynamic>?)
          ?.map((e) => ViolationBreakdown.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      topContractors: (json['top_contractors'] as List<dynamic>?)
          ?.map((e) => TopContractor.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      topDrivers: (json['top_drivers'] as List<dynamic>?)
          ?.map((e) => TopDriver.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      topCameras: (json['top_cameras'] as List<dynamic>?)
          ?.map((e) => TopCamera.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
}

class ViolationBreakdown {
  final String name;
  final int count;

  ViolationBreakdown({
    required this.name,
    required this.count,
  });

  factory ViolationBreakdown.fromJson(Map<String, dynamic> json) {
    return ViolationBreakdown(
      name: json['name'] as String,
      count: json['count'] as int? ?? 0,
    );
  }
}

class TopCamera {
  final String cameraId;
  final String? cameraName;
  final int errorEvents;

  TopCamera({
    required this.cameraId,
    this.cameraName,
    required this.errorEvents,
  });

  factory TopCamera.fromJson(Map<String, dynamic> json) {
    return TopCamera(
      cameraId: json['camera_id'] as String,
      cameraName: json['camera_name'] as String?,
      errorEvents: json['error_events'] as int? ?? 0,
    );
  }
}

// Performance Analytics
class PerformanceAnalyticsResponse {
  final PerformanceAnalyticsData data;

  PerformanceAnalyticsResponse({required this.data});

  factory PerformanceAnalyticsResponse.fromJson(Map<String, dynamic> json) {
    return PerformanceAnalyticsResponse(
      data: PerformanceAnalyticsData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}

class PerformanceAnalyticsData {
  final List<ContractorPerformance> contractors;
  final List<DriverPerformance> drivers;
  final List<VehiclePerformance> vehicles;

  PerformanceAnalyticsData({
    required this.contractors,
    required this.drivers,
    required this.vehicles,
  });

  factory PerformanceAnalyticsData.fromJson(Map<String, dynamic> json) {
    return PerformanceAnalyticsData(
      contractors: (json['contractors'] as List<dynamic>?)
          ?.map((e) => ContractorPerformance.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      drivers: (json['drivers'] as List<dynamic>?)
          ?.map((e) => DriverPerformance.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      vehicles: (json['vehicles'] as List<dynamic>?)
          ?.map((e) => VehiclePerformance.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
}

class ContractorPerformance {
  final String id;
  final String name;
  final int tripCount;
  final double violationRate;
  final double? avgDurationMinutes;
  final double? avgVolumeM3;
  final double? cleanTripRate;
  final double? volumeProgress;
  final double? problemTripRate;

  ContractorPerformance({
    required this.id,
    required this.name,
    required this.tripCount,
    required this.violationRate,
    this.avgDurationMinutes,
    this.avgVolumeM3,
    this.cleanTripRate,
    this.volumeProgress,
    this.problemTripRate,
  });

  factory ContractorPerformance.fromJson(Map<String, dynamic> json) {
    return ContractorPerformance(
      id: json['id'] as String,
      name: json['name'] as String,
      tripCount: json['trip_count'] as int? ?? 0,
      violationRate: (json['violation_rate'] as num?)?.toDouble() ?? 0.0,
      avgDurationMinutes: (json['avg_duration_minutes'] as num?)?.toDouble(),
      avgVolumeM3: (json['avg_volume_m3'] as num?)?.toDouble(),
      cleanTripRate: (json['clean_trip_rate'] as num?)?.toDouble(),
      volumeProgress: (json['volume_progress'] as num?)?.toDouble(),
      problemTripRate: (json['problem_trip_rate'] as num?)?.toDouble(),
    );
  }
}

class DriverPerformance {
  final String id;
  final String name;
  final int tripCount;
  final double? avgVolumeM3;
  final int violationCount;
  final double? violationRate;
  final double? avgSpeedKmh;
  final DateTime? lastTripAt;

  DriverPerformance({
    required this.id,
    required this.name,
    required this.tripCount,
    this.avgVolumeM3,
    required this.violationCount,
    this.violationRate,
    this.avgSpeedKmh,
    this.lastTripAt,
  });

  factory DriverPerformance.fromJson(Map<String, dynamic> json) {
    return DriverPerformance(
      id: json['id'] as String,
      name: json['name'] as String,
      tripCount: json['trip_count'] as int? ?? 0,
      avgVolumeM3: (json['avg_volume_m3'] as num?)?.toDouble(),
      violationCount: json['violation_count'] as int? ?? 0,
      violationRate: (json['violation_rate'] as num?)?.toDouble(),
      avgSpeedKmh: (json['avg_speed_kmh'] as num?)?.toDouble(),
      lastTripAt: json['last_trip_at'] != null
          ? DateTime.parse(json['last_trip_at'] as String)
          : null,
    );
  }
}

class VehiclePerformance {
  final String id;
  final String? name;
  final double? avgFillRate;
  final double? tripsPerDay;
  final int? lprErrorCount;
  final double? totalDistanceKm;
  final double? idleHours;
  final DateTime? lastTripAt;

  VehiclePerformance({
    required this.id,
    this.name,
    this.avgFillRate,
    this.tripsPerDay,
    this.lprErrorCount,
    this.totalDistanceKm,
    this.idleHours,
    this.lastTripAt,
  });

  factory VehiclePerformance.fromJson(Map<String, dynamic> json) {
    return VehiclePerformance(
      id: json['id'] as String,
      name: json['name'] as String?,
      avgFillRate: (json['avg_fill_rate'] as num?)?.toDouble(),
      tripsPerDay: (json['trips_per_day'] as num?)?.toDouble(),
      lprErrorCount: json['lpr_error_count'] as int?,
      totalDistanceKm: (json['total_distance_km'] as num?)?.toDouble(),
      idleHours: (json['idle_hours'] as num?)?.toDouble(),
      lastTripAt: json['last_trip_at'] != null
          ? DateTime.parse(json['last_trip_at'] as String)
          : null,
    );
  }
}

// Contracts Analytics
class ContractsAnalyticsResponse {
  final ContractsAnalyticsData data;

  ContractsAnalyticsResponse({required this.data});

  factory ContractsAnalyticsResponse.fromJson(Map<String, dynamic> json) {
    return ContractsAnalyticsResponse(
      data: ContractsAnalyticsData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}

class ContractsAnalyticsData {
  final List<ContractSummary> summary;
  final List<ContractSummary> topBudget;
  final List<ContractSummary> atRisk;
  final List<ContractSummary> budgetIssues;

  ContractsAnalyticsData({
    required this.summary,
    required this.topBudget,
    required this.atRisk,
    required this.budgetIssues,
  });

  factory ContractsAnalyticsData.fromJson(Map<String, dynamic> json) {
    return ContractsAnalyticsData(
      summary: (json['summary'] as List<dynamic>?)
          ?.map((e) => ContractSummary.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      topBudget: (json['top_budget'] as List<dynamic>?)
          ?.map((e) => ContractSummary.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      atRisk: (json['at_risk'] as List<dynamic>?)
          ?.map((e) => ContractSummary.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      budgetIssues: (json['budget_issues'] as List<dynamic>?)
          ?.map((e) => ContractSummary.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
}

class ContractSummary {
  final String contractId;
  final String? contractorName;
  final double? budgetProgress;
  final double? volumeProgress;
  final String? uiStatus;
  final String? result;
  final bool? isOverBudget;

  ContractSummary({
    required this.contractId,
    this.contractorName,
    this.budgetProgress,
    this.volumeProgress,
    this.uiStatus,
    this.result,
    this.isOverBudget,
  });

  factory ContractSummary.fromJson(Map<String, dynamic> json) {
    return ContractSummary(
      contractId: json['contract_id'] as String,
      contractorName: json['contractor_name'] as String?,
      budgetProgress: (json['budget_progress'] as num?)?.toDouble(),
      volumeProgress: (json['volume_progress'] as num?)?.toDouble(),
      uiStatus: json['ui_status'] as String?,
      result: json['result'] as String?,
      isOverBudget: json['is_over_budget'] as bool?,
    );
  }
}

// Areas Analytics
class AreasAnalyticsResponse {
  final AreasAnalyticsData data;

  AreasAnalyticsResponse({required this.data});

  factory AreasAnalyticsResponse.fromJson(Map<String, dynamic> json) {
    return AreasAnalyticsResponse(
      data: AreasAnalyticsData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}

class AreasAnalyticsData {
  final List<AreaAnalytics> areas;

  AreasAnalyticsData({
    required this.areas,
  });

  factory AreasAnalyticsData.fromJson(Map<String, dynamic> json) {
    return AreasAnalyticsData(
      areas: (json['areas'] as List<dynamic>?)
          ?.map((e) => AreaAnalytics.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
}

class AreaAnalytics {
  final String areaId;
  final String? areaName;
  final int tripCount;
  final double? volumeM3;
  final int violationCount;
  final List<String>? activeDrivers;
  final List<String>? activeVehicles;
  final double? avgIntervalHours;
  final double? idleHours;
  final Map<String, dynamic>? geometryGeojson;

  AreaAnalytics({
    required this.areaId,
    this.areaName,
    required this.tripCount,
    this.volumeM3,
    required this.violationCount,
    this.activeDrivers,
    this.activeVehicles,
    this.avgIntervalHours,
    this.idleHours,
    this.geometryGeojson,
  });

  factory AreaAnalytics.fromJson(Map<String, dynamic> json) {
    return AreaAnalytics(
      areaId: json['area_id'] as String,
      areaName: json['area_name'] as String?,
      tripCount: json['trip_count'] as int? ?? 0,
      volumeM3: (json['volume_m3'] as num?)?.toDouble(),
      violationCount: json['violation_count'] as int? ?? 0,
      activeDrivers: (json['active_drivers'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      activeVehicles: (json['active_vehicles'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      avgIntervalHours: (json['avg_interval_hours'] as num?)?.toDouble(),
      idleHours: (json['idle_hours'] as num?)?.toDouble(),
      geometryGeojson: json['geometry_geojson'] as Map<String, dynamic>?,
    );
  }
}

// Drivers Analytics
class DriversAnalyticsResponse {
  final DriversAnalyticsData data;

  DriversAnalyticsResponse({required this.data});

  factory DriversAnalyticsResponse.fromJson(Map<String, dynamic> json) {
    return DriversAnalyticsResponse(
      data: DriversAnalyticsData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}

class DriversAnalyticsData {
  final List<DriverPerformance> drivers;

  DriversAnalyticsData({
    required this.drivers,
  });

  factory DriversAnalyticsData.fromJson(Map<String, dynamic> json) {
    return DriversAnalyticsData(
      drivers: (json['drivers'] as List<dynamic>?)
          ?.map((e) => DriverPerformance.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
}

// Vehicles Analytics
class VehiclesAnalyticsResponse {
  final VehiclesAnalyticsData data;

  VehiclesAnalyticsResponse({required this.data});

  factory VehiclesAnalyticsResponse.fromJson(Map<String, dynamic> json) {
    return VehiclesAnalyticsResponse(
      data: VehiclesAnalyticsData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}

class VehiclesAnalyticsData {
  final List<VehiclePerformance> vehicles;

  VehiclesAnalyticsData({
    required this.vehicles,
  });

  factory VehiclesAnalyticsData.fromJson(Map<String, dynamic> json) {
    return VehiclesAnalyticsData(
      vehicles: (json['vehicles'] as List<dynamic>?)
          ?.map((e) => VehiclePerformance.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
}

// Technical Analytics
class TechnicalAnalyticsResponse {
  final TechnicalAnalyticsData data;

  TechnicalAnalyticsResponse({required this.data});

  factory TechnicalAnalyticsResponse.fromJson(Map<String, dynamic> json) {
    return TechnicalAnalyticsResponse(
      data: TechnicalAnalyticsData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}

class TechnicalAnalyticsData {
  final List<TechnicalCamera> cameras;
  final List<TechnicalPolygon> polygons;
  final double? errorRate;
  final double? eventFrequency;
  final DateTime? lastEventAt;

  TechnicalAnalyticsData({
    required this.cameras,
    required this.polygons,
    this.errorRate,
    this.eventFrequency,
    this.lastEventAt,
  });

  factory TechnicalAnalyticsData.fromJson(Map<String, dynamic> json) {
    return TechnicalAnalyticsData(
      cameras: (json['cameras'] as List<dynamic>?)
          ?.map((e) => TechnicalCamera.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      polygons: (json['polygons'] as List<dynamic>?)
          ?.map((e) => TechnicalPolygon.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      errorRate: (json['error_rate'] as num?)?.toDouble(),
      eventFrequency: (json['event_frequency'] as num?)?.toDouble(),
      lastEventAt: json['last_event_at'] != null
          ? DateTime.parse(json['last_event_at'] as String)
          : null,
    );
  }
}

class TechnicalCamera {
  final String cameraId;
  final String? cameraName;
  final int lprEvents;
  final int volumeEvents;
  final int errorEvents;

  TechnicalCamera({
    required this.cameraId,
    this.cameraName,
    required this.lprEvents,
    required this.volumeEvents,
    required this.errorEvents,
  });

  factory TechnicalCamera.fromJson(Map<String, dynamic> json) {
    return TechnicalCamera(
      cameraId: json['camera_id'] as String,
      cameraName: json['camera_name'] as String?,
      lprEvents: json['lpr_events'] as int? ?? 0,
      volumeEvents: json['volume_events'] as int? ?? 0,
      errorEvents: json['error_events'] as int? ?? 0,
    );
  }
}

class TechnicalPolygon {
  final String polygonId;
  final String? polygonName;
  final int tripCount;
  final double? volume;
  final int? errors;

  TechnicalPolygon({
    required this.polygonId,
    this.polygonName,
    required this.tripCount,
    this.volume,
    this.errors,
  });

  factory TechnicalPolygon.fromJson(Map<String, dynamic> json) {
    return TechnicalPolygon(
      polygonId: json['polygon_id'] as String,
      polygonName: json['polygon_name'] as String?,
      tripCount: json['trip_count'] as int? ?? 0,
      volume: (json['volume'] as num?)?.toDouble(),
      errors: json['errors'] as int?,
    );
  }
}

