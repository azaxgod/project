import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/operations/module.dart';
import '../../../../services/tickets/module.dart';
import '../../../../services/violations/module.dart';
import '../model/kpi_card.dart';
import '../model/trip.dart';
import '../model/polygon.dart';

final akimatHomeControllerProvider =
    StateNotifierProvider<AkimatHomeController, AkimatHomeState>((ref) {
  return AkimatHomeController(ref);
});

class AkimatHomeController extends StateNotifier<AkimatHomeState> {
  final Ref ref;
  
  AkimatHomeController(this.ref) : super(AkimatHomeState.initial()) {
    _loadRealData();
  }

  Future<void> _loadRealData() async {
    try {
      // Загружаем данные параллельно
      final results = await Future.wait([
        _loadKpiData(),
        _loadLastTrips(),
        _loadPolygons(),
      ]);

      final kpi = results[0] as List<KpiCardModel>;
      final trips = results[1] as List<TripModel>;
      final polygons = results[2] as List<PolygonModel>;

      state = state.copyWith(
        kpiCards: kpi,
        lastTrips: trips,
        polygons: polygons,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<List<KpiCardModel>> _loadKpiData() async {
    try {
      final operationsCollection = ref.read(operationsCollectionProvider);
      final ticketsCollection = ref.read(ticketsCollectionProvider);
      final violationsCollection = ref.read(violationsCollectionProvider);

      // Получаем данные для KPI
      final areas = await operationsCollection.getCleaningAreas(onlyActive: true);
      final tickets = await ticketsCollection.getTicketsAkimat();
      final violations = await violationsCollection.getViolations();

      return [
        KpiCardModel(
          title: 'Активные участки',
          value: areas.length.toString(),
          clickable: true,
        ),
        KpiCardModel(
          title: 'Активные тикеты',
          value: tickets.length.toString(),
          clickable: true,
        ),
        KpiCardModel(
          title: 'Нарушения',
          value: violations.data.length.toString(),
          clickable: true,
        ),
        KpiCardModel(
          title: 'Рейсы сегодня',
          value: '0', // TODO: Добавить получение количества рейсов
          clickable: false,
        ),
      ];
    } catch (e) {
      debugPrint('Error loading KPI data: $e');
      // Возвращаем KPI с ошибками
      return [
        KpiCardModel(title: 'Активные участки', value: '--', clickable: false),
        KpiCardModel(title: 'Активные тикеты', value: '--', clickable: false),
        KpiCardModel(title: 'Нарушения', value: '--', clickable: false),
        KpiCardModel(title: 'Рейсы сегодня', value: '--', clickable: false),
      ];
    }
  }

  Future<List<TripModel>> _loadLastTrips() async {
    try {
      final violationsCollection = ref.read(violationsCollectionProvider);
      final violations = await violationsCollection.getViolations();

      // Используем нарушения как "последние рейсы" для демонстрации
      return violations.data.map((record) => TripModel(
        time: '${record.violation.createdAt.hour.toString().padLeft(2, '0')}:${record.violation.createdAt.minute.toString().padLeft(2, '0')}',
        contractor: record.contractor?.name ?? 'Неизвестно',
        plate: record.vehicle?.plateNumber ?? 'Неизвестно',
        area: record.polygonName ?? 'Неизвестно',
        polygon: record.polygonName ?? 'Неизвестно',
        volume: 0.0, // В нарушениях нет объема
        status: record.tripStatus ?? 'UNKNOWN',
      )).toList();
    } catch (e) {
      debugPrint('Error loading last trips: $e');
      return [];
    }
  }

  Future<List<PolygonModel>> _loadPolygons() async {
    try {
      final operationsCollection = ref.read(operationsCollectionProvider);
      final areas = await operationsCollection.getCleaningAreas(onlyActive: true);

      return areas.map((area) => PolygonModel(
        name: area.name,
        contractor: 'ID: ${area.defaultContractorId ?? 'Не назначен'}',
        status: area.status,
        color: _getStatusColor(area.status),
      )).toList();
    } catch (e) {
      debugPrint('Error loading polygons: $e');
      return [];
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return Colors.green;
      case 'WARNING':
        return Colors.orange;
      case 'VIOLATION':
        return Colors.red;
      case 'INACTIVE':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  void refreshData() {
    state = state.copyWith(isLoading: true, error: null);
    _loadRealData();
  }
}

class AkimatHomeState {
  final List<KpiCardModel> kpiCards;
  final List<TripModel> lastTrips;
  final List<PolygonModel> polygons;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  AkimatHomeState({
    required this.kpiCards,
    required this.lastTrips,
    required this.polygons,
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  factory AkimatHomeState.initial() => AkimatHomeState(
        kpiCards: [],
        lastTrips: [],
        polygons: [],
        isLoading: true,
        lastUpdated: null,
      );

  AkimatHomeState copyWith({
    List<KpiCardModel>? kpiCards,
    List<TripModel>? lastTrips,
    List<PolygonModel>? polygons,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) {
    return AkimatHomeState(
      kpiCards: kpiCards ?? this.kpiCards,
      lastTrips: lastTrips ?? this.lastTrips,
      polygons: polygons ?? this.polygons,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
