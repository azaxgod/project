import 'package:akimat_project/services/analytics/collection/analytics_collection.dart';
import 'package:akimat_project/services/analytics/model/analytics_response.dart';
import 'i_analytics_repository.dart';

class AnalyticsRepositoryImpl implements IAnalyticsRepository {
  final AnalyticsCollection collection;

  AnalyticsRepositoryImpl({required this.collection});

  @override
  Future<DashboardResponse> getDashboard({
    DateTime? from,
    DateTime? to,
  }) async {
    return await collection.getDashboard(from: from, to: to);
  }

  @override
  Future<TripsAnalyticsResponse> getTripsAnalytics({
    DateTime? from,
    DateTime? to,
    String? groupBy,
    String? contractorId,
    String? driverId,
  }) async {
    return await collection.getTripsAnalytics(
      from: from,
      to: to,
      groupBy: groupBy,
      contractorId: contractorId,
      driverId: driverId,
    );
  }

  @override
  Future<TripDetailResponse> getTripDetail(String tripId) async {
    return await collection.getTripDetail(tripId);
  }

  @override
  Future<ViolationsAnalyticsResponse> getViolationsAnalytics({
    DateTime? from,
    DateTime? to,
    String? groupBy,
    String? contractorId,
    String? driverId,
    String? violationType,
  }) async {
    return await collection.getViolationsAnalytics(
      from: from,
      to: to,
      groupBy: groupBy,
      contractorId: contractorId,
      driverId: driverId,
      violationType: violationType,
    );
  }

  @override
  Future<PerformanceAnalyticsResponse> getPerformanceAnalytics({
    DateTime? from,
    DateTime? to,
    String? groupBy,
  }) async {
    return await collection.getPerformanceAnalytics(
      from: from,
      to: to,
      groupBy: groupBy,
    );
  }

  @override
  Future<ContractsAnalyticsResponse> getContractsAnalytics({
    DateTime? from,
    DateTime? to,
  }) async {
    return await collection.getContractsAnalytics(from: from, to: to);
  }

  @override
  Future<AreasAnalyticsResponse> getAreasAnalytics({
    DateTime? from,
    DateTime? to,
    String? contractorId,
  }) async {
    return await collection.getAreasAnalytics(
      from: from,
      to: to,
      contractorId: contractorId,
    );
  }

  @override
  Future<DriversAnalyticsResponse> getDriversAnalytics({
    DateTime? from,
    DateTime? to,
    String? contractorId,
    String? driverId,
  }) async {
    return await collection.getDriversAnalytics(
      from: from,
      to: to,
      contractorId: contractorId,
      driverId: driverId,
    );
  }

  @override
  Future<VehiclesAnalyticsResponse> getVehiclesAnalytics({
    DateTime? from,
    DateTime? to,
    String? contractorId,
  }) async {
    return await collection.getVehiclesAnalytics(
      from: from,
      to: to,
      contractorId: contractorId,
    );
  }

  @override
  Future<TechnicalAnalyticsResponse> getTechnicalAnalytics({
    DateTime? from,
    DateTime? to,
  }) async {
    return await collection.getTechnicalAnalytics(
      from: from,
      to: to,
    );
  }
}


