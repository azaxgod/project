import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../model/analytics_response.dart';

/// Ошибки аналитики
class AnalyticsException implements Exception {
  final String message;
  final int? statusCode;

  AnalyticsException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class AnalyticsCollection {
  final Dio dio;

  AnalyticsCollection({required this.dio});

  /// Обработка ошибок API
  void _handleError(DioException error) {
    if (error.response != null) {
      final statusCode = error.response!.statusCode;
      final errorData = error.response!.data;

      // Пытаемся извлечь детальное сообщение об ошибке
      String errorMessage;
      if (errorData is Map) {
        if (errorData.containsKey('error')) {
          errorMessage = errorData['error'] is String
              ? errorData['error'] as String
              : errorData['error'].toString();
        } else if (errorData.containsKey('message')) {
          errorMessage = errorData['message'] is String
              ? errorData['message'] as String
              : errorData['message'].toString();
        } else {
          errorMessage = errorData.toString();
        }
      } else if (errorData is String) {
        errorMessage = errorData;
      } else {
        errorMessage = error.message ?? 'Unknown error';
      }

      // Добавляем статус код к сообщению для 500 ошибок
      if (statusCode == 500) {
        errorMessage = 'Internal Server Error (500): $errorMessage\n\n'
            'This is a server-side error. Please check:\n'
            '- Server logs\n'
            '- Database connection\n'
            '- API endpoint implementation';
      }

      switch (statusCode) {
        case 400:
          throw AnalyticsException('Bad Request (400): $errorMessage', 400);
        case 401:
          throw AnalyticsException(
              'Unauthorized (401): Please check your authentication token',
              401);
        case 403:
          throw AnalyticsException('Forbidden (403): $errorMessage', 403);
        case 404:
          throw AnalyticsException('Not Found (404): $errorMessage', 404);
        case 500:
          throw AnalyticsException(errorMessage, 500);
        default:
          throw AnalyticsException(
              'Error ($statusCode): $errorMessage', statusCode);
      }
    } else {
      String errorMessage;
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
          errorMessage =
              'Connection timeout. Please check your internet connection.';
          break;
        case DioExceptionType.sendTimeout:
          errorMessage = 'Send timeout. Please try again.';
          break;
        case DioExceptionType.receiveTimeout:
          errorMessage = 'Receive timeout. Please try again.';
          break;
        case DioExceptionType.connectionError:
          errorMessage =
              'Connection error. Please check your internet connection and try again.';
          break;
        default:
          errorMessage = error.message ?? 'Unknown error';
          break;
      }
      throw AnalyticsException(errorMessage, null);
    }
  }

  /// Форматирует DateTime в RFC 3339 в локальном часовом поясе (без ручного сдвига времени)
  /// Пример: 2024-11-10T11:29:11+05:00
  String _formatDateTime(DateTime dateTime) {
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

  /// GET /analytics/dashboard
  /// Получить данные дашборда
  Future<DashboardResponse> getDashboard({
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (from != null) {
        final formattedFrom = _formatDateTime(from);
        queryParams['from'] = formattedFrom;
        debugPrint(
            'Analytics Dashboard - from: $formattedFrom (original: $from)');
      }
      if (to != null) {
        final formattedTo = _formatDateTime(to);
        queryParams['to'] = formattedTo;
        debugPrint('Analytics Dashboard - to: $formattedTo (original: $to)');
      }

      debugPrint('Analytics Dashboard - Request URL: /analytics/dashboard');
      debugPrint('Analytics Dashboard - Query params: $queryParams');
      debugPrint(
          'Analytics Dashboard - Full URL: ${dio.options.baseUrl}/analytics/dashboard');

      final response = await dio.get(
        '/analytics/dashboard',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      debugPrint(
          'Analytics Dashboard - Response status: ${response.statusCode}');
      debugPrint('Analytics Dashboard - Response headers: ${response.headers}');

      if (response.statusCode != 200) {
        debugPrint('Analytics Dashboard - Error response: ${response.data}');
      }

      return DashboardResponse.fromJson(response.data);
    } on DioException catch (e) {
      debugPrint('Analytics Dashboard - DioException: ${e.type}');
      debugPrint('Analytics Dashboard - Error message: ${e.message}');
      if (e.response != null) {
        debugPrint(
            'Analytics Dashboard - Error status: ${e.response!.statusCode}');
        debugPrint('Analytics Dashboard - Error data: ${e.response!.data}');
        debugPrint(
            'Analytics Dashboard - Error headers: ${e.response!.headers}');
      }
      _handleError(e);
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('Analytics Dashboard - Unexpected error: $e');
      debugPrint('Analytics Dashboard - Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// GET /analytics/trips
  /// Получить аналитику по рейсам
  Future<TripsAnalyticsResponse> getTripsAnalytics({
    DateTime? from,
    DateTime? to,
    String? groupBy,
    String? contractorId,
    String? driverId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (from != null) {
        queryParams['from'] = _formatDateTime(from);
      }
      if (to != null) {
        queryParams['to'] = _formatDateTime(to);
      }
      if (groupBy != null) {
        queryParams['group_by'] = groupBy;
      }
      if (contractorId != null) {
        queryParams['contractor_id'] = contractorId;
      }
      if (driverId != null) {
        queryParams['driver_id'] = driverId;
      }

      final response = await dio.get(
        '/analytics/trips',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      return TripsAnalyticsResponse.fromJson(response.data);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// GET /analytics/trips/{id}
  /// Получить детальную информацию о рейсе
  Future<TripDetailResponse> getTripDetail(String tripId) async {
    try {
      final response = await dio.get('/analytics/trips/$tripId');
      return TripDetailResponse.fromJson(response.data);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// GET /analytics/violations
  /// Получить аналитику по нарушениям
  Future<ViolationsAnalyticsResponse> getViolationsAnalytics({
    DateTime? from,
    DateTime? to,
    String? groupBy,
    String? contractorId,
    String? driverId,
    String? violationType,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (from != null) {
        queryParams['from'] = _formatDateTime(from);
      }
      if (to != null) {
        queryParams['to'] = _formatDateTime(to);
      }
      if (groupBy != null) {
        queryParams['group_by'] = groupBy;
      }
      if (contractorId != null) {
        queryParams['contractor_id'] = contractorId;
      }
      if (driverId != null) {
        queryParams['driver_id'] = driverId;
      }
      if (violationType != null) {
        queryParams['violation_type'] = violationType;
      }

      final response = await dio.get(
        '/analytics/violations',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      return ViolationsAnalyticsResponse.fromJson(response.data);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// GET /analytics/performance
  /// Получить аналитику эффективности
  Future<PerformanceAnalyticsResponse> getPerformanceAnalytics({
    DateTime? from,
    DateTime? to,
    String? groupBy,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (from != null) {
        queryParams['from'] = _formatDateTime(from);
      }
      if (to != null) {
        queryParams['to'] = _formatDateTime(to);
      }
      if (groupBy != null) {
        queryParams['group_by'] = groupBy;
      }

      final response = await dio.get(
        '/analytics/performance',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      return PerformanceAnalyticsResponse.fromJson(response.data);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// GET /analytics/contracts
  /// Получить аналитику по контрактам
  Future<ContractsAnalyticsResponse> getContractsAnalytics({
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (from != null) {
        queryParams['from'] = _formatDateTime(from);
      }
      if (to != null) {
        queryParams['to'] = _formatDateTime(to);
      }

      final response = await dio.get(
        '/analytics/contracts',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );
      return ContractsAnalyticsResponse.fromJson(response.data);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// GET /analytics/areas
  /// Получить аналитику по участкам
  Future<AreasAnalyticsResponse> getAreasAnalytics({
    DateTime? from,
    DateTime? to,
    String? contractorId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (from != null) {
        queryParams['from'] = _formatDateTime(from);
      }
      if (to != null) {
        queryParams['to'] = _formatDateTime(to);
      }
      if (contractorId != null) {
        queryParams['contractor_id'] = contractorId;
      }

      final response = await dio.get(
        '/analytics/areas',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      return AreasAnalyticsResponse.fromJson(response.data);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// GET /analytics/drivers
  /// Получить аналитику по водителям
  Future<DriversAnalyticsResponse> getDriversAnalytics({
    DateTime? from,
    DateTime? to,
    String? contractorId,
    String? driverId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (from != null) {
        queryParams['from'] = _formatDateTime(from);
      }
      if (to != null) {
        queryParams['to'] = _formatDateTime(to);
      }
      if (contractorId != null) {
        queryParams['contractor_id'] = contractorId;
      }
      if (driverId != null) {
        queryParams['driver_id'] = driverId;
      }

      final response = await dio.get(
        '/analytics/drivers',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      return DriversAnalyticsResponse.fromJson(response.data);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// GET /analytics/vehicles
  /// Получить аналитику по транспорту
  Future<VehiclesAnalyticsResponse> getVehiclesAnalytics({
    DateTime? from,
    DateTime? to,
    String? contractorId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (from != null) {
        queryParams['from'] = _formatDateTime(from);
      }
      if (to != null) {
        queryParams['to'] = _formatDateTime(to);
      }
      if (contractorId != null) {
        queryParams['contractor_id'] = contractorId;
      }

      final response = await dio.get(
        '/analytics/vehicles',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      return VehiclesAnalyticsResponse.fromJson(response.data);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// GET /analytics/technical
  /// Получить техническую аналитику (TOO)
  Future<TechnicalAnalyticsResponse> getTechnicalAnalytics({
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (from != null) {
        queryParams['from'] = _formatDateTime(from);
      }
      if (to != null) {
        queryParams['to'] = _formatDateTime(to);
      }

      final response = await dio.get(
        '/analytics/technical',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      return TechnicalAnalyticsResponse.fromJson(response.data);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// GET /api/v1/reports/comparison
  /// Получить сравнение периодов
  Future<Map<String, dynamic>> getPeriodComparison({
    required String mode,
    required DateTime from,
    required DateTime to,
    DateTime? previousFrom,
    DateTime? previousTo,
    String? contractorId,
    String? polygonId,
    String? vehicleId,
    String? plate,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'mode': mode,
        'from': _formatDateTime(from),
        'to': _formatDateTime(to),
      };

      if (previousFrom != null) {
        queryParams['previous_from'] = _formatDateTime(previousFrom);
      }
      if (previousTo != null) {
        queryParams['previous_to'] = _formatDateTime(previousTo);
      }
      if (contractorId != null) {
        queryParams['contractor_id'] = contractorId;
      }
      if (polygonId != null) {
        queryParams['polygon_id'] = polygonId;
      }
      if (vehicleId != null) {
        queryParams['vehicle_id'] = vehicleId;
      }
      if (plate != null) {
        queryParams['plate'] = plate;
      }

      debugPrint('Analytics - Period Comparison request with params: $queryParams');

      final response = await dio.get(
        '/api/v1/reports/comparison',
        queryParameters: queryParams,
      );

      debugPrint('Analytics - Period Comparison response: ${response.data}');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      debugPrint('Analytics - Period Comparison error: ${e.message}');
      _handleError(e);
      rethrow;
    }
  }
}
