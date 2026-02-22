import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:akimat_project/services/anpr/model/anpr_event.dart';
import 'package:akimat_project/services/anpr/model/anpr_plate.dart';
import 'package:akimat_project/services/anpr/model/anpr_report.dart';

import 'package:equatable/equatable.dart';

/// Коллекция для работы с ANPR сервисом
class AnprCollection {
  final Dio dio;

  AnprCollection({required Dio dio}) : dio = dio;

  /// Форматирует DateTime в RFC 3339 в локальном часовом поясе (без ручного сдвига времени)
  String _formatDateTimeRfc3339(DateTime dateTime) {
    final local = dateTime.toLocal();
    final offset = local.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final offsetHours = offset.inHours.abs().toString().padLeft(2, '0');
    final offsetMinutes =
        (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');

    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}T'
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}:'
        '${local.second.toString().padLeft(2, '0')}'
        '$sign$offsetHours:$offsetMinutes';
  }

  /// POST /api/v1/anpr/events - Приём события от камеры
  ///
  /// Поддерживает два формата:
  /// 1. JSON (application/json)
  /// 2. Multipart Form Data (multipart/form-data) с фотографиями
  Future<AnprEventResponse> createEvent({
    required AnprEventRequest request,
    List<String>? photoPaths, // Пути к файлам фотографий
  }) async {
    try {
      if (photoPaths != null && photoPaths.isNotEmpty) {
        // Multipart Form Data с фотографиями
        // Сериализуем JSON в строку для multipart формы (как указано в API документации)
        final eventJsonString = jsonEncode(request.toJson());
        final formData = FormData.fromMap({
          'event': eventJsonString,
        });

        for (var photoPath in photoPaths) {
          formData.files.add(
            MapEntry(
              'photos',
              await MultipartFile.fromFile(photoPath),
            ),
          );
        }

        final response = await dio.post(
          '/api/v1/anpr/events',
          data: formData,
        );

        return AnprEventResponse.fromJson(response.data);
      } else {
        // JSON формат
        final response = await dio.post(
          '/api/v1/anpr/events',
          data: request.toJson(),
          options: Options(
            headers: {'Content-Type': 'application/json'},
          ),
        );

        return AnprEventResponse.fromJson(response.data);
      }
    } on DioException catch (e) {
      throw Exception('Failed to create ANPR event: ${e.message}');
    }
  }

  /// GET /api/v1/plates?plate=123ABC02 - Поиск номеров
  /// Требует авторизацию (JWT токен)
  Future<AnprPlatesResponse> searchPlates({
    required String plate,
    String? jwtToken,
  }) async {
    try {
      final response = await dio.get(
        '/api/v1/plates',
        queryParameters: {'plate': plate},
        options: Options(
          headers:
              jwtToken != null ? {'Authorization': 'Bearer $jwtToken'} : null,
        ),
      );

      return AnprPlatesResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to search plates: ${e.message}');
    }
  }

  /// GET /api/v1/events - Список событий
  /// Требует авторизацию (JWT токен)
  Future<AnprEventsResponse> getEvents({
    String? plate,
    DateTime? from,
    DateTime? to,
    String? direction, // "enter" or "exit"
    int? limit,
    int? offset,
    String? jwtToken,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (plate != null) queryParams['plate'] = plate;
      if (from != null) queryParams['from'] = _formatDateTimeRfc3339(from);
      if (to != null) queryParams['to'] = _formatDateTimeRfc3339(to);
      if (direction != null) queryParams['direction'] = direction;
      if (limit != null) queryParams['limit'] = limit;
      if (offset != null) queryParams['offset'] = offset;

      final response = await dio.get(
        '/api/v1/events',
        queryParameters: queryParams,
        options: Options(
          headers:
              jwtToken != null ? {'Authorization': 'Bearer $jwtToken'} : null,
        ),
      );

      return AnprEventsResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to get events: ${e.message}');
    }
  }

  /// GET /api/v1/events/:id - Получение события по ID с фотографиями
  /// Требует авторизацию (JWT токен)
  Future<AnprEvent> getEventById({
    required String eventId,
    String? jwtToken,
  }) async {
    try {
      final response = await dio.get(
        '/api/v1/events/$eventId',
        options: Options(
          headers:
              jwtToken != null ? {'Authorization': 'Bearer $jwtToken'} : null,
        ),
      );

      return AnprEvent.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception('Failed to get event: ${e.message}');
    }
  }

  /// POST /api/v1/anpr/sync-vehicle - Синхронизация транспорта
  /// Требует авторизацию (JWT токен)
  /// Согласно документации, принимает только plate_number
  Future<Map<String, dynamic>> syncVehicle({
    required String plateNumber,
    String? jwtToken,
  }) async {
    try {
      final response = await dio.post(
        '/api/v1/anpr/sync-vehicle',
        data: {
          'plate_number': plateNumber,
        },
        options: Options(
          headers:
              jwtToken != null ? {'Authorization': 'Bearer $jwtToken'} : null,
        ),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception('Failed to sync vehicle: ${e.message}');
    }
  }

  /// GET /api/v1/anpr/hikvision - Проверка доступности камеры
  Future<bool> checkCameraStatus({
    required String cameraId,
  }) async {
    try {
      final response = await dio.get(
        '/api/v1/anpr/hikvision',
        queryParameters: {'camera_id': cameraId},
      );

      return response.statusCode == 200;
    } on DioException catch (e) {
      return false;
    }
  }

  /// GET /api/v1/camera/status - Статус камеры
  Future<Map<String, dynamic>> getCameraStatus({
    required String cameraId,
  }) async {
    try {
      final response = await dio.get(
        '/api/v1/camera/status',
        queryParameters: {'camera_id': cameraId},
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception('Failed to get camera status: ${e.message}');
    }
  }

  /// GET /health/live - Проверка работоспособности
  Future<bool> healthCheck() async {
    try {
      final response = await dio.get('/health/live');
      return response.statusCode == 200;
    } on DioException catch (e) {
      return false;
    }
  }

  /// GET /health/ready - Проверка готовности (включая БД)
  Future<bool> readinessCheck() async {
    try {
      final response = await dio.get('/health/ready');
      return response.statusCode == 200;
    } on DioException catch (e) {
      return false;
    }
  }

  /// GET /api/v1/reports - Получение отчетов по объему снега и поездкам
  /// Требует авторизацию (JWT токен)
  Future<AnprReportResponse> getReports({
    String? contractorId,
    String? polygonId,
    String? vehicleId,
    String? plate,
    DateTime? from,
    DateTime? to,
    int? limit,
    int? offset,
    String? jwtToken,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (contractorId != null) queryParams['contractor_id'] = contractorId;
      if (polygonId != null) queryParams['polygon_id'] = polygonId;
      if (vehicleId != null) queryParams['vehicle_id'] = vehicleId;
      if (plate != null) queryParams['plate'] = plate;
      if (from != null) queryParams['from'] = _formatDateTimeRfc3339(from);
      if (to != null) queryParams['to'] = _formatDateTimeRfc3339(to);
      if (limit != null) queryParams['limit'] = limit;
      if (offset != null) queryParams['offset'] = offset;

      final response = await dio.get(
        '/api/v1/reports',
        queryParameters: queryParams,
        options: Options(
          headers:
              jwtToken != null ? {'Authorization': 'Bearer $jwtToken'} : null,
        ),
      );

      return AnprReportResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to get reports: ${e.message}');
    }
  }
}

/// Ответ на получение списка событий
class AnprEventsResponse extends Equatable {
  final List<AnprEvent> data;

  const AnprEventsResponse({required this.data});

  factory AnprEventsResponse.fromJson(Map<String, dynamic> json) {
    return AnprEventsResponse(
      data: (json['data'] as List<dynamic>)
          .map((e) => AnprEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [data];
}
