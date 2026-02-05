import 'package:akimat_project/services/anpr/collection/anpr_collection.dart';
import 'package:akimat_project/services/anpr/model/anpr_event.dart';
import 'package:akimat_project/services/anpr/model/anpr_plate.dart';
import 'package:akimat_project/services/anpr/model/anpr_report.dart';
import 'package:akimat_project/modules/auth/src/storage/token_storage.dart';
import 'package:akimat_project/core/utils/file_downloader.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Контроллер для работы с ANPR данными
class AnprController extends StateNotifier<AnprState> {
  AnprController({
    required AnprCollection anprCollection,
  })  : _anprCollection = anprCollection,
        super(const AnprState());

  final AnprCollection _anprCollection;

  int _eventsRequestVersion = 0;
  int _statisticsRequestVersion = 0;
  int _reportsRequestVersion = 0;

  /// Загрузить события ANPR
  Future<void> loadEvents({
    String? plate,
    DateTime? from,
    DateTime? to,
    int? limit,
    int? offset,
  }) async {
    final requestVersion = ++_eventsRequestVersion;

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

      // Если пришел ответ от старого запроса — игнорируем
      if (requestVersion != _eventsRequestVersion) return;

      state = state.copyWith(
        events: AsyncValue.data(response.data),
      );
    } catch (e, stack) {
      if (requestVersion != _eventsRequestVersion) return;
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
    final requestVersion = ++_statisticsRequestVersion;

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

      if (requestVersion != _statisticsRequestVersion) return;

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
      if (requestVersion != _statisticsRequestVersion) return;
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
    final requestVersion = ++_reportsRequestVersion;

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

      if (requestVersion != _reportsRequestVersion) return;

      state = state.copyWith(
        reports: AsyncValue.data(response.data),
      );
    } catch (e, stack) {
      if (requestVersion != _reportsRequestVersion) return;
      state = state.copyWith(
        reports: AsyncValue.error(e, stack),
      );
    }
  }

  /// Скачать отчет в Excel формате
  Future<String?> downloadExcel({
    String? contractorId,
    String? polygonId,
    String? vehicleId,
    String? plate,
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final token = await TokenStorage.getAccessToken();
      final response = await _anprCollection.downloadExcel(
        contractorId: contractorId,
        polygonId: polygonId,
        vehicleId: vehicleId,
        plate: plate,
        from: from,
        to: to,
        jwtToken: token,
      );

      // Получаем имя файла из заголовка Content-Disposition или генерируем свое
      String fileName = 'anpr-events.xlsx';
      final contentDisposition = response.headers['content-disposition'];
      if (contentDisposition != null && contentDisposition.isNotEmpty) {
        final match = RegExp(r'filename="?([^"]+)"?').firstMatch(contentDisposition.first);
        if (match != null) {
          fileName = match.group(1) ?? fileName;
        }
      }

      final bytes = List<int>.from(response.data);
      final extension = fileName.contains('.') ? fileName.split('.').last : 'xlsx';
      final filenameWithoutExtension = fileName.contains('.')
          ? fileName.substring(0, fileName.length - extension.length - 1)
          : fileName;

      // В Web: FileDownloader сделает browser download через Blob.
      // На mobile/desktop: сохранит в Documents/Downloads и вернет путь.
      final savedPath = await FileDownloader.downloadFile(
        bytes: bytes,
        filename: filenameWithoutExtension,
        extension: extension,
      );

      if (kIsWeb) return null;
      return savedPath;
    } catch (e) {
      print('Error in downloadExcel: $e'); // Для отладки
      print('Stack trace: ${StackTrace.current}'); // Для отладки
      throw Exception('Failed to download Excel file: $e');
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

