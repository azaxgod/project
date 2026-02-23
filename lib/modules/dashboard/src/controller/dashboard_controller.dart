import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/operations/module.dart';
import '../../../../services/tickets/module.dart';
import '../../../../services/violations/module.dart';
import '../../../../services/anpr/module.dart';
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

  Future<T?> _safeLoad<T>(Future<T> Function() loader, String label) async {
    try {
      return await loader();
    } catch (e) {
      debugPrint('Error loading $label: $e');
      return null;
    }
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
    final operationsCollection = ref.read(operationsCollectionProvider);
    final ticketsCollection = ref.read(ticketsCollectionProvider);
    final violationsCollection = ref.read(violationsCollectionProvider);
    final anprCollection = ref.read(anprCollectionProvider);

    // Загружаем активные участки и полигоны - они должны показываться всегда
    int areasCount = 0;
    int polygonsCount = 0;
    try {
      final areas = await operationsCollection.getCleaningAreas(onlyActive: true);
      areasCount = areas.length;
    } catch (e) {
      debugPrint('Error loading active areas: $e');
    }

    try {
      final polygons = await operationsCollection.getPolygons(onlyActive: true);
      polygonsCount = polygons.length;
    } catch (e) {
      debugPrint('Error loading active polygons: $e');
    }

    // Загружаем остальные данные безопасно
    final tickets = await _safeLoad(
      () => ticketsCollection.getTicketsAkimat(),
      'tickets',
    );

    final violationsCount = await _safeLoad<int>(
      () async {
        final violations = await violationsCollection.getViolations();
        return violations.items.length;
      },
      'violations',
    );

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    final reportsTripCount = await _safeLoad<int>(
      () async {
        final reports = await anprCollection.getReports(
          from: todayStart,
          to: now,
          minVolume: 0.01,
          limit: 1000,
          offset: 0,
        );
        return reports.data.tripCount;
      },
      'anpr reports (tripCount)',
    );

    return [
      KpiCardModel(
        title: 'Активные участки',
        value: areasCount.toString(),
        clickable: true,
      ),
      KpiCardModel(
        title: 'Активные полигоны',
        value: polygonsCount.toString(),
        clickable: false,
      ),
      KpiCardModel(
        title: 'Активные тикеты',
        value: tickets?.length.toString() ?? '--',
        clickable: true,
      ),
      KpiCardModel(
        title: 'Нарушения',
        value: violationsCount?.toString() ?? '--',
        clickable: true,
      ),
      KpiCardModel(
        title: 'Рейсы сегодня',
        value: reportsTripCount?.toString() ?? '--',
        clickable: false,
      ),
    ];
  }

  Future<List<TripModel>> _loadLastTrips() async {
    try {
      final anprCollection = ref.read(anprCollectionProvider);
      final operationsCollection = ref.read(operationsCollectionProvider);

      final now = DateTime.now();
      final from = DateTime(now.year, now.month, 1);

      final Map<String, String> areaNameById = {};
      try {
        final areas = await operationsCollection.getCleaningAreas(onlyActive: true);
        for (final a in areas) {
          areaNameById[a.id] = a.name;
        }
      } catch (e) {
        debugPrint('Error loading cleaning areas for trip mapping: $e');
      }

      final Map<String, String> polygonNameById = {};
      try {
        final polygons = await operationsCollection.getPolygons(onlyActive: null);
        for (final p in polygons) {
          polygonNameById[p.id] = p.name;
        }
      } catch (e) {
        debugPrint('Error loading polygons for trip mapping: $e');
      }

      final reports = await anprCollection.getReports(
        from: from,
        to: now,
        minVolume: 0.01,
        limit: 20,
        offset: 0,
      );

      final events = reports.data.events;
      // Сортируем по времени события (последние сверху)
      final sorted = [...events]..sort((a, b) => b.eventTime.compareTo(a.eventTime));

      return sorted.take(10).map((e) {
        final t = e.eventTime.toLocal();
        final date = '${t.day.toString().padLeft(2, '0')}.${t.month.toString().padLeft(2, '0')}.${t.year}';

        final polygonId = e.polygonId;
        final areaName = polygonId != null ? areaNameById[polygonId] : null;
        final polygonName = polygonId != null ? polygonNameById[polygonId] : null;

        final displayArea = areaName ?? polygonId ?? '—';
        final displayPolygon = polygonName ?? polygonId ?? '—';
        return TripModel(
          date: date,
          time: '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
          contractor: e.contractorName ?? 'Неизвестно',
          plate: e.plateNumber,
          area: displayArea,
          polygon: displayPolygon,
          volume: e.snowVolumeM3 ?? 0.0,
          status: e.snowVolumeM3 != null ? 'MEASURED' : 'NO_VOLUME',
        );
      }).toList();
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
