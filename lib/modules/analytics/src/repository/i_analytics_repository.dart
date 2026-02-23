import 'package:akimat_project/services/analytics/model/analytics_response.dart';

abstract class IAnalyticsRepository {
  /// Получить данные дашборда
  Future<DashboardResponse> getDashboard({
    DateTime? from,
    DateTime? to,
  });

  /// Получить аналитику по рейсам
  Future<TripsAnalyticsResponse> getTripsAnalytics({
    DateTime? from,
    DateTime? to,
    String? groupBy,
    String? contractorId,
    String? driverId,
  });

  /// Получить детальную информацию о рейсе
  Future<TripDetailResponse> getTripDetail(String tripId);

  /// Получить аналитику по нарушениям
  Future<ViolationsAnalyticsResponse> getViolationsAnalytics({
    DateTime? from,
    DateTime? to,
    String? groupBy,
    String? contractorId,
    String? driverId,
    String? violationType,
  });

  /// Получить аналитику эффективности
  Future<PerformanceAnalyticsResponse> getPerformanceAnalytics({
    DateTime? from,
    DateTime? to,
    String? groupBy,
  });

  /// Получить аналитику по контрактам
  Future<ContractsAnalyticsResponse> getContractsAnalytics({
    DateTime? from,
    DateTime? to,
  });

  /// Получить аналитику по участкам
  Future<AreasAnalyticsResponse> getAreasAnalytics({
    DateTime? from,
    DateTime? to,
    String? contractorId,
  });

  /// Получить аналитику по водителям
  Future<DriversAnalyticsResponse> getDriversAnalytics({
    DateTime? from,
    DateTime? to,
    String? contractorId,
    String? driverId,
  });

  /// Получить аналитику по транспорту
  Future<VehiclesAnalyticsResponse> getVehiclesAnalytics({
    DateTime? from,
    DateTime? to,
    String? contractorId,
  });

  /// Получить техническую аналитику (TOO)
  Future<TechnicalAnalyticsResponse> getTechnicalAnalytics({
    DateTime? from,
    DateTime? to,
  });
}


