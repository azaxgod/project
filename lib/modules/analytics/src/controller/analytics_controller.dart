import 'package:akimat_project/modules/analytics/src/repository/i_analytics_repository.dart';
import 'package:akimat_project/modules/analytics/src/controller/analytics_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AnalyticsController extends StateNotifier<AnalyticsState> {
  AnalyticsController({
    required IAnalyticsRepository repository,
  })  : _repository = repository,
        super(const AnalyticsState());

  final IAnalyticsRepository _repository;

  /// Загрузить дашборд
  Future<void> loadDashboard({DateTime? from, DateTime? to}) async {
    state = state.copyWith(
      dashboard: const AsyncLoading(),
      dateFrom: from,
      dateTo: to,
    );

    state = state.copyWith(
      dashboard: await AsyncValue.guard(() async {
        return await _repository.getDashboard(from: from, to: to);
      }),
    );
  }

  /// Загрузить аналитику по рейсам
  Future<void> loadTripsAnalytics({
    DateTime? from,
    DateTime? to,
    String? groupBy,
    String? contractorId,
    String? driverId,
  }) async {
    state = state.copyWith(
      tripsAnalytics: const AsyncLoading(),
      dateFrom: from ?? state.dateFrom,
      dateTo: to ?? state.dateTo,
    );

    state = state.copyWith(
      tripsAnalytics: await AsyncValue.guard(() async {
        return await _repository.getTripsAnalytics(
          from: from ?? state.dateFrom,
          to: to ?? state.dateTo,
          groupBy: groupBy,
          contractorId: contractorId,
          driverId: driverId,
        );
      }),
    );
  }

  /// Загрузить детальную информацию о рейсе
  Future<void> loadTripDetail(String tripId) async {
    state = state.copyWith(
      tripDetail: const AsyncLoading(),
    );

    state = state.copyWith(
      tripDetail: await AsyncValue.guard(() async {
        return await _repository.getTripDetail(tripId);
      }),
    );
  }

  /// Загрузить аналитику по нарушениям
  Future<void> loadViolationsAnalytics({
    DateTime? from,
    DateTime? to,
    String? groupBy,
    String? contractorId,
    String? driverId,
    String? violationType,
  }) async {
    state = state.copyWith(
      violationsAnalytics: const AsyncLoading(),
      dateFrom: from ?? state.dateFrom,
      dateTo: to ?? state.dateTo,
    );

    state = state.copyWith(
      violationsAnalytics: await AsyncValue.guard(() async {
        return await _repository.getViolationsAnalytics(
          from: from ?? state.dateFrom,
          to: to ?? state.dateTo,
          groupBy: groupBy,
          contractorId: contractorId,
          driverId: driverId,
          violationType: violationType,
        );
      }),
    );
  }

  /// Загрузить аналитику эффективности
  Future<void> loadPerformanceAnalytics({
    DateTime? from,
    DateTime? to,
    String? groupBy,
  }) async {
    state = state.copyWith(
      performanceAnalytics: const AsyncLoading(),
      dateFrom: from ?? state.dateFrom,
      dateTo: to ?? state.dateTo,
    );

    state = state.copyWith(
      performanceAnalytics: await AsyncValue.guard(() async {
        return await _repository.getPerformanceAnalytics(
          from: from ?? state.dateFrom,
          to: to ?? state.dateTo,
          groupBy: groupBy,
        );
      }),
    );
  }

  /// Загрузить аналитику по контрактам
  Future<void> loadContractsAnalytics() async {
    state = state.copyWith(
      contractsAnalytics: const AsyncLoading(),
    );

    state = state.copyWith(
      contractsAnalytics: await AsyncValue.guard(() async {
        return await _repository.getContractsAnalytics();
      }),
    );
  }

  /// Загрузить аналитику по участкам
  Future<void> loadAreasAnalytics({
    DateTime? from,
    DateTime? to,
    String? contractorId,
  }) async {
    state = state.copyWith(
      areasAnalytics: const AsyncLoading(),
      dateFrom: from ?? state.dateFrom,
      dateTo: to ?? state.dateTo,
    );

    state = state.copyWith(
      areasAnalytics: await AsyncValue.guard(() async {
        return await _repository.getAreasAnalytics(
          from: from ?? state.dateFrom,
          to: to ?? state.dateTo,
          contractorId: contractorId,
        );
      }),
    );
  }

  /// Загрузить аналитику по водителям
  Future<void> loadDriversAnalytics({
    DateTime? from,
    DateTime? to,
    String? contractorId,
    String? driverId,
  }) async {
    state = state.copyWith(
      driversAnalytics: const AsyncLoading(),
      dateFrom: from ?? state.dateFrom,
      dateTo: to ?? state.dateTo,
    );

    state = state.copyWith(
      driversAnalytics: await AsyncValue.guard(() async {
        return await _repository.getDriversAnalytics(
          from: from ?? state.dateFrom,
          to: to ?? state.dateTo,
          contractorId: contractorId,
          driverId: driverId,
        );
      }),
    );
  }

  /// Загрузить аналитику по транспорту
  Future<void> loadVehiclesAnalytics({
    DateTime? from,
    DateTime? to,
    String? contractorId,
  }) async {
    state = state.copyWith(
      vehiclesAnalytics: const AsyncLoading(),
      dateFrom: from ?? state.dateFrom,
      dateTo: to ?? state.dateTo,
    );

    state = state.copyWith(
      vehiclesAnalytics: await AsyncValue.guard(() async {
        return await _repository.getVehiclesAnalytics(
          from: from ?? state.dateFrom,
          to: to ?? state.dateTo,
          contractorId: contractorId,
        );
      }),
    );
  }

  /// Загрузить техническую аналитику (TOO)
  Future<void> loadTechnicalAnalytics({
    DateTime? from,
    DateTime? to,
  }) async {
    state = state.copyWith(
      technicalAnalytics: const AsyncLoading(),
      dateFrom: from ?? state.dateFrom,
      dateTo: to ?? state.dateTo,
    );

    state = state.copyWith(
      technicalAnalytics: await AsyncValue.guard(() async {
        return await _repository.getTechnicalAnalytics(
          from: from ?? state.dateFrom,
          to: to ?? state.dateTo,
        );
      }),
    );
  }

  /// Обновить диапазон дат
  void updateDateRange(DateTime? from, DateTime? to) {
    state = state.copyWith(
      dateFrom: from,
      dateTo: to,
    );
  }
}

