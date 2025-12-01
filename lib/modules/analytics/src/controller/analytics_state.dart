import 'package:akimat_project/services/analytics/model/analytics_response.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AnalyticsState extends Equatable {
  const AnalyticsState({
    this.dashboard,
    this.tripsAnalytics,
    this.violationsAnalytics,
    this.performanceAnalytics,
    this.contractsAnalytics,
    this.areasAnalytics,
    this.driversAnalytics,
    this.vehiclesAnalytics,
    this.technicalAnalytics,
    this.tripDetail,
    this.isLoading = false,
    this.error,
    this.dateFrom,
    this.dateTo,
  });

  final AsyncValue<DashboardResponse>? dashboard;
  final AsyncValue<TripsAnalyticsResponse>? tripsAnalytics;
  final AsyncValue<ViolationsAnalyticsResponse>? violationsAnalytics;
  final AsyncValue<PerformanceAnalyticsResponse>? performanceAnalytics;
  final AsyncValue<ContractsAnalyticsResponse>? contractsAnalytics;
  final AsyncValue<AreasAnalyticsResponse>? areasAnalytics;
  final AsyncValue<DriversAnalyticsResponse>? driversAnalytics;
  final AsyncValue<VehiclesAnalyticsResponse>? vehiclesAnalytics;
  final AsyncValue<TechnicalAnalyticsResponse>? technicalAnalytics;
  final AsyncValue<TripDetailResponse>? tripDetail;
  final bool isLoading;
  final String? error;
  final DateTime? dateFrom;
  final DateTime? dateTo;

  AnalyticsState copyWith({
    AsyncValue<DashboardResponse>? dashboard,
    AsyncValue<TripsAnalyticsResponse>? tripsAnalytics,
    AsyncValue<ViolationsAnalyticsResponse>? violationsAnalytics,
    AsyncValue<PerformanceAnalyticsResponse>? performanceAnalytics,
    AsyncValue<ContractsAnalyticsResponse>? contractsAnalytics,
    AsyncValue<AreasAnalyticsResponse>? areasAnalytics,
    AsyncValue<DriversAnalyticsResponse>? driversAnalytics,
    AsyncValue<VehiclesAnalyticsResponse>? vehiclesAnalytics,
    AsyncValue<TechnicalAnalyticsResponse>? technicalAnalytics,
    AsyncValue<TripDetailResponse>? tripDetail,
    bool? isLoading,
    String? error,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) {
    return AnalyticsState(
      dashboard: dashboard ?? this.dashboard,
      tripsAnalytics: tripsAnalytics ?? this.tripsAnalytics,
      violationsAnalytics: violationsAnalytics ?? this.violationsAnalytics,
      performanceAnalytics: performanceAnalytics ?? this.performanceAnalytics,
      contractsAnalytics: contractsAnalytics ?? this.contractsAnalytics,
      areasAnalytics: areasAnalytics ?? this.areasAnalytics,
      driversAnalytics: driversAnalytics ?? this.driversAnalytics,
      vehiclesAnalytics: vehiclesAnalytics ?? this.vehiclesAnalytics,
      technicalAnalytics: technicalAnalytics ?? this.technicalAnalytics,
      tripDetail: tripDetail ?? this.tripDetail,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
    );
  }

  @override
  List<Object?> get props => [
        dashboard,
        tripsAnalytics,
        violationsAnalytics,
        performanceAnalytics,
        contractsAnalytics,
        areasAnalytics,
        driversAnalytics,
        vehiclesAnalytics,
        technicalAnalytics,
        tripDetail,
        isLoading,
        error,
        dateFrom,
        dateTo,
      ];
}








