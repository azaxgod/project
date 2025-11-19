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
}

