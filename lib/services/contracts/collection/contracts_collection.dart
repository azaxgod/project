import 'package:akimat_project/services/contracts/model/contract_dto.dart';
import 'package:akimat_project/services/contracts/model/contract_ticket_dto.dart';
import 'package:akimat_project/services/contracts/model/contract_trip_dto.dart';
import 'package:dio/dio.dart';

/// Ошибки Contract Service
class ContractException implements Exception {
  final String message;
  final int? statusCode;

  ContractException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ContractsCollection {
  final Dio dio;

  ContractsCollection({required this.dio});

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
          throw ContractException(errorMessage, 400);
        case 401:
          throw ContractException(errorMessage, 401);
        case 403:
          throw ContractException(errorMessage, 403);
        case 404:
          throw ContractException(errorMessage, 404);
        case 409:
          throw ContractException(errorMessage, 409);
        default:
          throw ContractException(errorMessage, statusCode);
      }
    } else {
      // Обработка ошибок подключения (network errors)
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
        case DioExceptionType.badCertificate:
          errorMessage = 'Certificate error. Please contact support.';
          break;
        case DioExceptionType.badResponse:
          errorMessage = 'Bad response from server.';
          break;
        case DioExceptionType.cancel:
          errorMessage = 'Request cancelled.';
          break;
        case DioExceptionType.connectionError:
          errorMessage = 'Connection error. Please check your internet connection and try again.';
          break;
        case DioExceptionType.unknown:
        default:
          final message = error.message ?? 'Unknown error';
          if (message.contains('Failed host lookup') || 
              message.contains('failed host lookup') ||
              message.contains('getaddrinfo failed')) {
            errorMessage = 'Cannot connect to server. Please check your internet connection and try again.';
          } else {
            errorMessage = message;
          }
          break;
      }
      throw ContractException(errorMessage, null);
    }
  }

  /// GET /contracts - Получить список контрактов
  Future<List<ContractDto>> getContracts({
    String? contractorId,
    String? workType,
    String? status,
    bool? onlyActive,
    DateTime? startFrom,
    DateTime? startTo,
    DateTime? endFrom,
    DateTime? endTo,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (contractorId != null) queryParams['contractor_id'] = contractorId;
      if (workType != null) queryParams['work_type'] = workType;
      if (status != null) queryParams['status'] = status;
      if (onlyActive != null) queryParams['only_active'] = onlyActive;
      // Форматируем даты в формат YYYY-MM-DD (только дата, без времени)
      if (startFrom != null) {
        queryParams['start_from'] = 
            '${startFrom.year.toString().padLeft(4, '0')}-'
            '${startFrom.month.toString().padLeft(2, '0')}-'
            '${startFrom.day.toString().padLeft(2, '0')}';
      }
      if (startTo != null) {
        queryParams['start_to'] = 
            '${startTo.year.toString().padLeft(4, '0')}-'
            '${startTo.month.toString().padLeft(2, '0')}-'
            '${startTo.day.toString().padLeft(2, '0')}';
      }
      if (endFrom != null) {
        queryParams['end_from'] = 
            '${endFrom.year.toString().padLeft(4, '0')}-'
            '${endFrom.month.toString().padLeft(2, '0')}-'
            '${endFrom.day.toString().padLeft(2, '0')}';
      }
      if (endTo != null) {
        queryParams['end_to'] = 
            '${endTo.year.toString().padLeft(4, '0')}-'
            '${endTo.month.toString().padLeft(2, '0')}-'
            '${endTo.day.toString().padLeft(2, '0')}';
      }

      final response = await dio.get(
        '/contracts',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      final List<dynamic> data = response.data['data'] ?? [];
      return data.map((json) => ContractDto.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// POST /contracts - Создать новый контракт
  /// Поддерживает создание контрактов CONTRACTOR_SERVICE и LANDFILL_SERVICE
  Future<ContractDto> createContract({
    required String contractType, // "CONTRACTOR_SERVICE" или "LANDFILL_SERVICE"
    String? contractorId, // Для CONTRACTOR_SERVICE
    String? landfillId, // Для LANDFILL_SERVICE
    required String name,
    String? workType, // Только для CONTRACTOR_SERVICE
    required double pricePerM3,
    double? budgetTotal, // Опционально для LANDFILL_SERVICE
    double? minimalVolumeM3, // Опционально для LANDFILL_SERVICE
    List<String>? polygonIds, // Для LANDFILL_SERVICE
    double? vatRate, // Ставка НДС
    required DateTime startAt,
    required DateTime endAt,
    required bool isActive,
    String? createdByOrgId, // ID организации KGU ZKH, создающей контракт
  }) async {
    try {
      // Форматируем даты: пробуем ISO 8601 формат (API может ожидать полный формат с временем)
      // Используем UTC время для консистентности
      final startAtFormatted = startAt.toUtc().toIso8601String();
      final endAtFormatted = endAt.toUtc().toIso8601String();
      
      final data = <String, dynamic>{
        'contract_type': contractType,
        'name': name,
        'price_per_m3': pricePerM3,
        'start_at': startAtFormatted, // ISO 8601 формат
        'end_at': endAtFormatted, // ISO 8601 формат
        'is_active': isActive,
        if (contractorId != null) 'contractor_id': contractorId,
        if (landfillId != null) 'landfill_id': landfillId,
        if (workType != null) 'work_type': workType,
        if (budgetTotal != null) 'budget_total': budgetTotal,
        if (minimalVolumeM3 != null) 'minimal_volume_m3': minimalVolumeM3,
        if (polygonIds != null && polygonIds.isNotEmpty) 'polygon_ids': polygonIds,
        if (vatRate != null) 'vat_rate': vatRate,
        if (createdByOrgId != null) 'created_by_org_id': createdByOrgId,
      };
      
      final response = await dio.post(
        '/contracts',
        data: data,
      );

      // POST /contracts возвращает 201 Created с контрактом, возможно обёрнутым в data
      final responseData = response.data;
      if (responseData is Map && responseData.containsKey('data')) {
        return ContractDto.fromJson(responseData['data'] as Map<String, dynamic>);
      } else {
        return ContractDto.fromJson(responseData as Map<String, dynamic>);
      }
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// GET /contracts/:id - Получить контракт по ID
  Future<ContractDto> getContract(String id) async {
    try {
      final response = await dio.get('/contracts/$id');
      return ContractDto.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// GET /contracts/:id/tickets - Получить тикеты контракта
  Future<List<ContractTicketDto>> getContractTickets(String contractId) async {
    try {
      final response = await dio.get('/contracts/$contractId/tickets');
      final List<dynamic> data = response.data['data'] ?? [];
      return data.map((json) => ContractTicketDto.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// GET /contracts/:id/trips - Получить рейсы контракта
  Future<List<ContractTripDto>> getContractTrips(String contractId) async {
    try {
      final response = await dio.get('/contracts/$contractId/trips');
      final List<dynamic> data = response.data['data'] ?? [];
      return data.map((json) => ContractTripDto.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// PUT /tickets/:ticket_id/contract - Сопоставить тикет с контрактом
  Future<void> linkTicketToContract(String ticketId, String contractId) async {
    try {
      await dio.put(
        '/tickets/$ticketId/contract',
        data: {'contract_id': contractId},
      );
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// POST /trips/usage - Зафиксировать рейс и обновить contract_usage
  Future<void> recordTripUsage({
    required String tripId,
    required String ticketId,
    required double detectedVolumeM3,
  }) async {
    try {
      await dio.post(
        '/trips/usage',
        data: {
          'trip_id': tripId,
          'ticket_id': ticketId,
          'detected_volume_m3': detectedVolumeM3,
        },
      );
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }
}

