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
      final errorMessage = errorData is Map && errorData.containsKey('error')
          ? errorData['error'] as String
          : error.message ?? 'Unknown error';

      switch (statusCode) {
        case 400:
          throw AnalyticsException(errorMessage, 400);
        case 401:
          throw AnalyticsException(errorMessage, 401);
        case 403:
          throw AnalyticsException(errorMessage, 403);
        case 404:
          throw AnalyticsException(errorMessage, 404);
        default:
          throw AnalyticsException(errorMessage, statusCode);
      }
    } else {
      String errorMessage;
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
          errorMessage = 'Connection timeout. Please check your internet connection.';
          break;
        case DioExceptionType.sendTimeout:
          errorMessage = 'Send timeout. Please try again.';
          break;
        case DioExceptionType.receiveTimeout:
          errorMessage = 'Receive timeout. Please try again.';
          break;
        case DioExceptionType.connectionError:
          errorMessage = 'Connection error. Please check your internet connection and try again.';
          break;
        default:
          errorMessage = error.message ?? 'Unknown error';
          break;
      }
      throw AnalyticsException(errorMessage, null);
    }
  }

  /// Форматирует DateTime в RFC 3339 формат (UTC с Z в конце)
  /// Пример: 2024-11-10T06:29:11Z
  String _formatDateTime(DateTime dateTime) {
    // Конвертируем в UTC
    final utc = dateTime.toUtc();
    // Форматируем в RFC 3339 (без миллисекунд, с Z в конце)
    return '${utc.year.toString().padLeft(4, '0')}-'
        '${utc.month.toString().padLeft(2, '0')}-'
        '${utc.day.toString().padLeft(2, '0')}T'
        '${utc.hour.toString().padLeft(2, '0')}:'
        '${utc.minute.toString().padLeft(2, '0')}:'
        '${utc.second.toString().padLeft(2, '0')}Z';
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
        debugPrint('Analytics Dashboard - from: $formattedFrom (original: $from)');
      }
      if (to != null) {
        final formattedTo = _formatDateTime(to);
        queryParams['to'] = formattedTo;
        debugPrint('Analytics Dashboard - to: $formattedTo (original: $to)');
      }

      debugPrint('Analytics Dashboard - Request URL: /analytics/dashboard');
      debugPrint('Analytics Dashboard - Query params: $queryParams');
      
      final response = await dio.get(
        '/analytics/dashboard',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );
      
      debugPrint('Analytics Dashboard - Response status: ${response.statusCode}');
      
      return DashboardResponse.fromJson(response.data);
    } on DioException catch (e) {
      _handleError(e);
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
  Future<ContractsAnalyticsResponse> getContractsAnalytics() async {
    try {
      final response = await dio.get('/analytics/contracts');
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
}

