import 'package:akimat_project/services/anpr/collection/anpr_collection.dart';
import 'package:akimat_project/services/anpr/model/anpr_event.dart';
import 'package:akimat_project/services/anpr/model/anpr_plate.dart';
import 'package:akimat_project/services/anpr/model/anpr_report.dart';
import 'package:akimat_project/modules/auth/src/storage/token_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Контроллер для работы с ANPR данными
class AnprController extends StateNotifier<AnprState> {
  AnprController({
    required AnprCollection anprCollection,
  })  : _anprCollection = anprCollection,
        super(const AnprState());

  final AnprCollection _anprCollection;

  /// Загрузить события ANPR
  Future<void> loadEvents({
    String? plate,
    DateTime? from,
    DateTime? to,
    int? limit,
    int? offset,
  }) async {
    // Не загружаем если уже загружается
    if (state.events?.isLoading ?? false) return;
    
    state = state.copyWith(
      events: const AsyncLoading(),
    );

    try {
      final token = await TokenStorage.getAccessToken();
      final response = await _anprCollection.getEvents(
        plate: plate,
        from: from,
        to: to,
        limit: limit ?? 50, // Уменьшено с 100 для быстрой загрузки
        offset: offset ?? 0,
        jwtToken: token,
      );

      state = state.copyWith(
        events: AsyncValue.data(response.data),
      );
    } catch (e, stack) {
      state = state.copyWith(
        events: AsyncValue.error(e, stack),
      );
    }
  }

  /// Загрузить статистику по событиям
  Future<void> loadStatistics({
    DateTime? from,
    DateTime? to,
  }) async {
    // Не загружаем если уже загружается
    if (state.statistics?.isLoading ?? false) return;
    
    state = state.copyWith(
      statistics: const AsyncLoading(),
    );

    try {
      final token = await TokenStorage.getAccessToken();
      // Загружаем ограниченное количество событий для статистики (оптимизация)
      // Используем меньший лимит для быстрой загрузки
      final response = await _anprCollection.getEvents(
        from: from,
        to: to,
        limit: 500, // Уменьшено с 1000 для быстрой загрузки
        offset: 0,
        jwtToken: token,
      );

      final events = response.data;
      
      // Вычисляем статистику
      final totalEvents = events.length;
      final uniquePlates = events.map((e) => e.normalizedPlate).toSet().length;
      final enterEvents = events.where((e) => e.direction == 'enter').length;
      final exitEvents = events.where((e) => e.direction == 'exit').length;
      final avgConfidence = events
              .where((e) => e.confidence != null)
              .map((e) => e.confidence!)
              .fold(0.0, (sum, conf) => sum + conf) /
          (events.where((e) => e.confidence != null).length > 0
              ? events.where((e) => e.confidence != null).length
              : 1);

      final statistics = AnprStatistics(
        totalEvents: totalEvents,
        uniquePlates: uniquePlates,
        enterEvents: enterEvents,
        exitEvents: exitEvents,
        avgConfidence: avgConfidence,
      );

      state = state.copyWith(
        statistics: AsyncValue.data(statistics),
      );
    } catch (e, stack) {
      state = state.copyWith(
        statistics: AsyncValue.error(e, stack),
      );
    }
  }

  /// Поиск номеров
  Future<void> searchPlates(String plate) async {
    state = state.copyWith(
      plates: const AsyncLoading(),
    );

    try {
      final token = await TokenStorage.getAccessToken();
      final response = await _anprCollection.searchPlates(
        plate: plate,
        jwtToken: token,
      );

      state = state.copyWith(
        plates: AsyncValue.data(response.data),
      );
    } catch (e, stack) {
      state = state.copyWith(
        plates: AsyncValue.error(e, stack),
      );
    }
  }

  /// Получить событие по ID
  Future<void> loadEventById(String eventId) async {
    state = state.copyWith(
      selectedEvent: const AsyncLoading(),
    );

    try {
      final token = await TokenStorage.getAccessToken();
      final event = await _anprCollection.getEventById(
        eventId: eventId,
        jwtToken: token,
      );

      state = state.copyWith(
        selectedEvent: AsyncValue.data(event),
      );
    } catch (e, stack) {
      state = state.copyWith(
        selectedEvent: AsyncValue.error(e, stack),
      );
    }
  }


  void clearSelectedEvent() {
    state = state.copyWith(
      selectedEvent: null,
    );
  }


  Future<void> loadReports({
    String? contractorId,
    String? polygonId,
    String? vehicleId,
    String? plate,
    DateTime? from,
    DateTime? to,
    int? limit,
    int? offset,
  }) async {

    if (state.reports?.isLoading ?? false) return;
    
    state = state.copyWith(
      reports: const AsyncLoading(),
    );

    try {
      final token = await TokenStorage.getAccessToken();
      final response = await _anprCollection.getReports(
        contractorId: contractorId,
        polygonId: polygonId,
        vehicleId: vehicleId,
        plate: plate,
        from: from,
        to: to,
        limit: limit ?? 50, // Уменьшено с 100 для быстрой загрузки
        offset: offset ?? 0,
        jwtToken: token,
      );

      state = state.copyWith(
        reports: AsyncValue.data(response.data),
      );
    } catch (e, stack) {
      state = state.copyWith(
        reports: AsyncValue.error(e, stack),
      );
    }
  }
}

/// Состояние ANPR контроллера
class AnprState {
  const AnprState({
    this.events,
    this.statistics,
    this.plates,
    this.selectedEvent,
    this.reports,
  });

  final AsyncValue<List<AnprEvent>>? events;
  final AsyncValue<AnprStatistics>? statistics;
  final AsyncValue<List<AnprPlate>>? plates;
  final AsyncValue<AnprEvent>? selectedEvent;
  final AsyncValue<AnprReportData>? reports;

  AnprState copyWith({
    AsyncValue<List<AnprEvent>>? events,
    AsyncValue<AnprStatistics>? statistics,
    AsyncValue<List<AnprPlate>>? plates,
    AsyncValue<AnprEvent>? selectedEvent,
    AsyncValue<AnprReportData>? reports,
  }) {
    return AnprState(
      events: events ?? this.events,
      statistics: statistics ?? this.statistics,
      plates: plates ?? this.plates,
      selectedEvent: selectedEvent ?? this.selectedEvent,
      reports: reports ?? this.reports,
    );
  }
}

/// Статистика ANPR
class AnprStatistics {
  const AnprStatistics({
    required this.totalEvents,
    required this.uniquePlates,
    required this.enterEvents,
    required this.exitEvents,
    required this.avgConfidence,
  });

  final int totalEvents;
  final int uniquePlates;
  final int enterEvents;
  final int exitEvents;
  final double avgConfidence;
}

