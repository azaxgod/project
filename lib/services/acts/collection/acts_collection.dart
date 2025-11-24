import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Ошибки Acts API
class ActsException implements Exception {
  final String message;
  final int? statusCode;
  
  ActsException(this.message, [this.statusCode]);
  
  @override
  String toString() => message;
}

class ActsCollection {
  final Dio dio;
  
  ActsCollection({required this.dio});

  /// Обработка ошибок API
  void _handleError(DioException error) {
    if (error.response != null) {
      final statusCode = error.response!.statusCode;
      final errorData = error.response!.data;
      
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

      switch (statusCode) {
        case 400:
          throw ActsException('Bad Request (400): $errorMessage', 400);
        case 401:
          throw ActsException('Unauthorized (401): Please check your authentication token', 401);
        case 403:
          throw ActsException('Forbidden (403): You do not have permission to generate acts for this contract', 403);
        case 404:
          throw ActsException('Not Found (404): Contract not found', 404);
        case 422:
          throw ActsException('Unprocessable Entity (422): $errorMessage', 422);
        case 500:
          throw ActsException('Internal Server Error (500): $errorMessage', 500);
        default:
          throw ActsException('Error ($statusCode): $errorMessage', statusCode);
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
          errorMessage = 'Receive timeout. PDF generation may take longer. Please try again.';
          break;
        case DioExceptionType.connectionError:
          errorMessage = 'Connection error. Please check your internet connection and try again.';
          break;
        default:
          errorMessage = error.message ?? 'Unknown error';
          break;
      }
      throw ActsException(errorMessage, null);
    }
  }

  /// POST /contracts/{contract_id}/acts/generate-pdf
  /// Генерация акта выполненных работ (форма Р-1) в формате PDF
  /// 
  /// [contractId] - ID контракта
  /// [periodStart] - Начало периода (дата, опционально - если null, бэкенд использует start_at контракта)
  /// [periodEnd] - Конец периода (дата, опционально - если null, бэкенд использует end_at контракта)
  /// 
  /// Возвращает байты PDF файла
  Future<List<int>> generateActPdf({
    required String contractId,
    DateTime? periodStart,
    DateTime? periodEnd,
  }) async {
    try {
      final requestBody = <String, dynamic>{};
      
      // Добавляем даты только если они указаны
      // Если не указаны, бэкенд использует период действия контракта (start_at, end_at)
      if (periodStart != null) {
        final formattedStart = '${periodStart.year.toString().padLeft(4, '0')}-'
            '${periodStart.month.toString().padLeft(2, '0')}-'
            '${periodStart.day.toString().padLeft(2, '0')}';
        requestBody['period_start'] = formattedStart;
      }
      
      if (periodEnd != null) {
        final formattedEnd = '${periodEnd.year.toString().padLeft(4, '0')}-'
            '${periodEnd.month.toString().padLeft(2, '0')}-'
            '${periodEnd.day.toString().padLeft(2, '0')}';
        requestBody['period_end'] = formattedEnd;
      }

      debugPrint('Acts API - Generating PDF for contract: $contractId');
      if (periodStart != null && periodEnd != null) {
        debugPrint('Acts API - Period: ${requestBody['period_start']} to ${requestBody['period_end']}');
      } else {
        debugPrint('Acts API - Period: будет использован период действия контракта (start_at, end_at)');
      }
      
      // Временно меняем responseType для этого запроса
      final originalResponseType = dio.options.responseType;
      dio.options.responseType = ResponseType.bytes;
      
      try {
        final response = await dio.post(
          '/contracts/$contractId/acts/generate-pdf',
          data: requestBody,
        );
        
        // Восстанавливаем оригинальный responseType
        dio.options.responseType = originalResponseType;
      
        debugPrint('Acts API - PDF generated successfully: ${response.data?.length ?? 0} bytes');
        
        if (response.data is List<int>) {
          return response.data as List<int>;
        } else if (response.data is List) {
          return (response.data as List).cast<int>();
        } else if (response.data is Uint8List) {
          return (response.data as Uint8List).toList();
        } else {
          throw ActsException('Unexpected response format', null);
        }
      } finally {
        // Восстанавливаем оригинальный responseType в любом случае
        dio.options.responseType = originalResponseType;
      }
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('Acts API - Unexpected error: $e');
      debugPrint('Acts API - Stack trace: $stackTrace');
      rethrow;
    }
  }

  // ==================== Acts Management ====================

  /// GET /acts/contractors - Список актов КГУ ↔ подрядчики
  /// Доступ: KGU_ZKH_ADMIN, CONTRACTOR_ADMIN
  Future<Map<String, dynamic>> getContractorActs({
    String? contractorId,
    DateTime? periodStart,
    DateTime? periodEnd,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (contractorId != null) {
        queryParams['contractor_id'] = contractorId;
      }
      if (periodStart != null) {
        queryParams['period_start'] = periodStart.toUtc().toIso8601String();
      }
      if (periodEnd != null) {
        queryParams['period_end'] = periodEnd.toUtc().toIso8601String();
      }

      final response = await dio.get(
        '/acts/contractors',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// GET /acts/landfill - Список актов КГУ ↔ LANDFILL
  /// Доступ: KGU_ZKH_ADMIN, LANDFILL_ADMIN
  Future<Map<String, dynamic>> getLandfillActs({
    String? landfillId,
    DateTime? periodStart,
    DateTime? periodEnd,
    String? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (landfillId != null) {
        queryParams['landfill_id'] = landfillId;
      }
      if (periodStart != null) {
        queryParams['period_start'] = periodStart.toUtc().toIso8601String();
      }
      if (periodEnd != null) {
        queryParams['period_end'] = periodEnd.toUtc().toIso8601String();
      }
      if (status != null) {
        queryParams['status'] = status;
      }

      final response = await dio.get(
        '/acts/landfill',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// GET /acts/landfill/:id - Получить акт приёма по ID
  /// Доступ: KGU_ZKH_ADMIN, LANDFILL_ADMIN
  Future<Map<String, dynamic>> getLandfillAct(String actId) async {
    try {
      final response = await dio.get('/acts/landfill/$actId');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// POST /acts/landfill - Создать акт приёма снега
  /// Доступ: только KGU_ZKH_ADMIN
  Future<Map<String, dynamic>> createLandfillAct({
    required String contractId,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) async {
    try {
      final response = await dio.post(
        '/acts/landfill',
        data: {
          'contract_id': contractId,
          'period_start': periodStart.toUtc().toIso8601String(),
          'period_end': periodEnd.toUtc().toIso8601String(),
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// PUT /acts/landfill/:id/approve - Подтвердить акт приёма
  /// Доступ: только LANDFILL_ADMIN
  Future<Map<String, dynamic>> approveLandfillAct(
    String actId, {
    String? comment,
  }) async {
    try {
      final response = await dio.put(
        '/acts/landfill/$actId/approve',
        data: comment != null ? {'comment': comment} : null,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// PUT /acts/landfill/:id/reject - Отклонить акт приёма
  /// Доступ: только LANDFILL_ADMIN
  Future<Map<String, dynamic>> rejectLandfillAct(
    String actId, {
    required String reason,
  }) async {
    try {
      final response = await dio.put(
        '/acts/landfill/$actId/reject',
        data: {
          'reason': reason,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// PUT /acts/landfill/:id/send - Отправить акт оператору полигона
  /// Доступ: только KGU_ZKH_ADMIN
  Future<Map<String, dynamic>> sendLandfillActToOperator(String actId) async {
    try {
      final response = await dio.put(
        '/acts/landfill/$actId/send',
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }
}

