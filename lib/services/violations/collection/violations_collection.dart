import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../model/appeal.dart';
import '../model/violation.dart';
import '../model/violation_response.dart';

/// Ошибки violations
class ViolationsException implements Exception {
  final String message;
  final int? statusCode;

  ViolationsException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ViolationsCollection {
  final Dio dio;

  ViolationsCollection({required this.dio});

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
          throw ViolationsException(errorMessage, 400);
        case 401:
          throw ViolationsException(errorMessage, 401);
        case 403:
          throw ViolationsException(errorMessage, 403);
        case 404:
          throw ViolationsException(errorMessage, 404);
        default:
          throw ViolationsException(errorMessage, statusCode);
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
      throw ViolationsException(errorMessage, null);
    }
  }

  /// Форматирует DateTime в RFC 3339 формат (UTC с Z в конце)
  String _formatDateTime(DateTime dateTime) {
    final utc = dateTime.toUtc();
    return '${utc.year.toString().padLeft(4, '0')}-'
        '${utc.month.toString().padLeft(2, '0')}-'
        '${utc.day.toString().padLeft(2, '0')}T'
        '${utc.hour.toString().padLeft(2, '0')}:'
        '${utc.minute.toString().padLeft(2, '0')}:'
        '${utc.second.toString().padLeft(2, '0')}Z';
  }

  /// GET /violations
  /// Получить список нарушений
  Future<ViolationsListResponse> getViolations({
    ViolationStatus? status,
    ViolationType? type,
    ViolationSeverity? severity,
    ViolationDetectedBy? detectedBy,
    String? contractorId,
    String? driverId,
    String? ticketId,
    String? cleaningAreaId,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? search,
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status.value;
      if (type != null) queryParams['type'] = type.value;
      if (severity != null) queryParams['severity'] = severity.value;
      if (detectedBy != null) queryParams['detected_by'] = detectedBy.value;
      if (contractorId != null) queryParams['contractor_id'] = contractorId;
      if (driverId != null) queryParams['driver_id'] = driverId;
      if (ticketId != null) queryParams['ticket_id'] = ticketId;
      if (cleaningAreaId != null) queryParams['cleaning_area_id'] = cleaningAreaId;
      if (dateFrom != null) queryParams['date_from'] = _formatDateTime(dateFrom);
      if (dateTo != null) queryParams['date_to'] = _formatDateTime(dateTo);
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (limit != null) queryParams['limit'] = limit;
      if (offset != null) queryParams['offset'] = offset;

      debugPrint('Violations - Request: GET /violations with params: $queryParams');

      final response = await dio.get(
        '/violations',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      return ViolationsListResponse.fromJson(response.data);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// GET /violations/:id
  /// Получить детальную информацию о нарушении
  Future<ViolationDetailResponse> getViolationDetail(String violationId) async {
    try {
      final response = await dio.get('/violations/$violationId');
      return ViolationDetailResponse.fromJson(response.data);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// POST /violations
  /// Создать нарушение вручную (KGU/Akimat)
  Future<ViolationRecord> createViolation({
    required String tripId,
    required ViolationType type,
    required ViolationDetectedBy detectedBy,
    required ViolationSeverity severity,
    String? description,
  }) async {
    try {
      final response = await dio.post(
        '/violations',
        data: {
          'trip_id': tripId,
          'type': type.value,
          'detected_by': detectedBy.value,
          'severity': severity.value,
          'description': description,
        },
      );
      return ViolationRecord.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// PUT /violations/:id/status
  /// Изменить статус нарушения
  Future<void> updateViolationStatus({
    required String violationId,
    required ViolationStatus status,
    String? description,
  }) async {
    try {
      await dio.put(
        '/violations/$violationId/status',
        data: {
          'status': status.value,
          'description': description,
        },
      );
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// GET /appeals
  /// Получить список апелляций
  Future<AppealsListResponse> getAppeals({
    AppealStatus? status,
    AppealReasonCode? reasonCode,
    ViolationType? violationType,
    String? contractorId,
    DateTime? dateFrom,
    DateTime? dateTo,
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status.value;
      if (reasonCode != null) queryParams['reason_code'] = reasonCode.value;
      if (violationType != null) queryParams['violation_type'] = violationType.value;
      if (contractorId != null) queryParams['contractor_id'] = contractorId;
      if (dateFrom != null) queryParams['date_from'] = _formatDateTime(dateFrom);
      if (dateTo != null) queryParams['date_to'] = _formatDateTime(dateTo);
      if (limit != null) queryParams['limit'] = limit;
      if (offset != null) queryParams['offset'] = offset;

      final response = await dio.get(
        '/appeals',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      return AppealsListResponse.fromJson(response.data);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// GET /appeals/:id
  /// Получить детальную информацию об апелляции
  Future<AppealDetailResponse> getAppealDetail(String appealId) async {
    try {
      final response = await dio.get('/appeals/$appealId');
      return AppealDetailResponse.fromJson(response.data);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// POST /violations/:id/appeals
  /// Создать апелляцию (Driver/Contractor)
  Future<AppealRecord> createAppeal({
    required String violationId,
    required AppealReasonCode reasonCode,
    required String reasonText,
    List<Map<String, dynamic>>? attachments,
  }) async {
    try {
      final response = await dio.post(
        '/violations/$violationId/appeals',
        data: {
          'reason_code': reasonCode.value,
          'reason_text': reasonText,
          'attachments': attachments ?? [],
        },
      );
      return AppealRecord.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// POST /appeals/:id/comments
  /// Добавить комментарий к апелляции
  Future<AppealComment> addAppealComment({
    required String appealId,
    required String message,
    List<Map<String, dynamic>>? attachments,
  }) async {
    try {
      final response = await dio.post(
        '/appeals/$appealId/comments',
        data: {
          'message': message,
          'attachments': attachments ?? [],
        },
      );
      return AppealComment.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// POST /appeals/:id/actions
  /// Выполнить действие над апелляцией (KGU/Akimat)
  Future<void> performAppealAction({
    required String appealId,
    required String action, // UNDER_REVIEW, NEED_INFO, APPROVE, REJECT, CLOSE
    String? message,
  }) async {
    try {
      await dio.post(
        '/appeals/$appealId/actions',
        data: {
          'action': action,
          'message': message,
        },
      );
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }
}







