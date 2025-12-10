import 'package:akimat_project/services/operations/model/ticket_assignment_dto.dart';
import 'package:akimat_project/services/operations/model/ticket_dto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Ошибки Ticket Service
class TicketsException implements Exception {
  final String message;
  final int? statusCode;

  TicketsException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class TicketsCollection {
  final Dio dio;

  TicketsCollection({required this.dio});

  /// Форматирование даты в RFC 3339 формат (YYYY-MM-DDTHH:mm:ssZ)
  String _formatDateTimeRfc3339(DateTime dateTime) {
    // Преобразуем в UTC
    final utc = dateTime.toUtc();
    // Форматируем в RFC 3339: YYYY-MM-DDTHH:mm:ssZ
    final year = utc.year.toString().padLeft(4, '0');
    final month = utc.month.toString().padLeft(2, '0');
    final day = utc.day.toString().padLeft(2, '0');
    final hour = utc.hour.toString().padLeft(2, '0');
    final minute = utc.minute.toString().padLeft(2, '0');
    final second = utc.second.toString().padLeft(2, '0');
    return '$year-$month-${day}T$hour:$minute:${second}Z';
  }

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
          throw TicketsException(errorMessage, 400);
        case 401:
          throw TicketsException(errorMessage, 401);
        case 403:
          throw TicketsException(errorMessage, 403);
        case 404:
          throw TicketsException(errorMessage, 404);
        case 409:
          throw TicketsException(errorMessage, 409);
        default:
          throw TicketsException(errorMessage, statusCode);
      }
    } else {
      throw TicketsException(
        error.message ?? 'Network error: ${error.type}',
        null,
      );
    }
  }

  // ==================== KGU Tickets ====================

  /// POST /kgu/tickets - Создать тикет (KGU)
  Future<TicketDto> createTicketKgu({
    required String cleaningAreaId,
    required String contractorId,
    required String contractId,
    required DateTime plannedStartAt,
    required DateTime plannedEndAt,
    String? description,
  }) async {
    try {
      final data = {
        'cleaning_area_id': cleaningAreaId,
        'contractor_id': contractorId,
        'contract_id': contractId,
        'planned_start_at': _formatDateTimeRfc3339(plannedStartAt),
        'planned_end_at': _formatDateTimeRfc3339(plannedEndAt),
        if (description != null) 'description': description,
      };

      debugPrint('TicketsCollection.createTicketKgu: Request URL: /kgu/tickets');
      debugPrint('TicketsCollection.createTicketKgu: Request data: $data');

      final response = await dio.post('/kgu/tickets', data: data);

      debugPrint('TicketsCollection.createTicketKgu: Response status: ${response.statusCode}');
      debugPrint('TicketsCollection.createTicketKgu: Response data: ${response.data}');

      final responseData = response.data;
      if (responseData is! Map<String, dynamic> || !responseData.containsKey('data')) {
        throw TicketsException('Invalid response format');
      }

      return TicketDto.fromJson(responseData['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('TicketsCollection.createTicketKgu: DioException: ${e.type}');
      debugPrint('TicketsCollection.createTicketKgu: Status code: ${e.response?.statusCode}');
      debugPrint('TicketsCollection.createTicketKgu: Response data: ${e.response?.data}');
      _handleError(e);
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('TicketsCollection.createTicketKgu: Unexpected error: $e');
      debugPrint('TicketsCollection.createTicketKgu: Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// GET /kgu/tickets - Получить тикеты KGU
  Future<List<TicketDto>> getTicketsKgu({
    String? status,
    String? contractorId,
    String? cleaningAreaId,
    String? contractId,
    DateTime? plannedStartFrom,
    DateTime? plannedStartTo,
    DateTime? plannedEndFrom,
    DateTime? plannedEndTo,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;
      if (contractorId != null) queryParams['contractor_id'] = contractorId;
      if (cleaningAreaId != null) queryParams['cleaning_area_id'] = cleaningAreaId;
      if (contractId != null) queryParams['contract_id'] = contractId;
      if (plannedStartFrom != null) queryParams['planned_start_from'] = _formatDateTimeRfc3339(plannedStartFrom);
      if (plannedStartTo != null) queryParams['planned_start_to'] = _formatDateTimeRfc3339(plannedStartTo);
      if (plannedEndFrom != null) queryParams['planned_end_from'] = _formatDateTimeRfc3339(plannedEndFrom);
      if (plannedEndTo != null) queryParams['planned_end_to'] = _formatDateTimeRfc3339(plannedEndTo);

      debugPrint('TicketsCollection.getTicketsKgu: Request URL: /kgu/tickets');
      debugPrint('TicketsCollection.getTicketsKgu: Query params: $queryParams');

      final response = await dio.get(
        '/kgu/tickets',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      final responseData = response.data;
      if (responseData is! Map<String, dynamic> || !responseData.containsKey('data')) {
        throw TicketsException('Invalid response format');
      }

      final List<dynamic> data = responseData['data'] as List<dynamic>? ?? [];
      return data.map((json) => TicketDto.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// GET /kgu/tickets/:id - Получить тикет KGU
  Future<TicketDto> getTicketKgu(String id) async {
    try {
      final response = await dio.get('/kgu/tickets/$id');
      final responseData = response.data;
      if (responseData is! Map<String, dynamic> || !responseData.containsKey('data')) {
        throw TicketsException('Invalid response format');
      }
      return TicketDto.fromJson(responseData['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// PUT /kgu/tickets/:id/cancel - Отменить тикет
  Future<TicketDto> cancelTicketKgu(String id) async {
    try {
      debugPrint('TicketsCollection.cancelTicketKgu: Request URL: /kgu/tickets/$id/cancel');
      
      final response = await dio.put('/kgu/tickets/$id/cancel');
      
      debugPrint('TicketsCollection.cancelTicketKgu: Response status: ${response.statusCode}');
      debugPrint('TicketsCollection.cancelTicketKgu: Response data type: ${response.data.runtimeType}');
      debugPrint('TicketsCollection.cancelTicketKgu: Response data: ${response.data}');
      
      final responseData = response.data;
      
      // Проверяем формат ответа
      if (responseData is! Map<String, dynamic>) {
        debugPrint('TicketsCollection.cancelTicketKgu: Response is not a Map, it is: ${responseData.runtimeType}');
        throw TicketsException('Invalid response format: expected Map, got ${responseData.runtimeType}');
      }
      
      if (!responseData.containsKey('data')) {
        debugPrint('TicketsCollection.cancelTicketKgu: Response missing "data" key. Full response: $responseData');
        throw TicketsException('Invalid response format: missing "data" key');
      }
      
      final data = responseData['data'] as Map<String, dynamic>;
      
      // Проверяем, содержит ли ответ только message (успешная отмена без полного объекта тикета)
      if (data.containsKey('message') && data.length == 1) {
        debugPrint('TicketsCollection.cancelTicketKgu: Response contains only message, fetching updated ticket');
        // Если ответ содержит только message, получаем актуальный тикет через GET
        try {
          return await getTicketKgu(id);
        } catch (e) {
          // Если не удалось получить тикет, но отмена успешна (200 OK),
          // выбрасываем специальное исключение с кодом 200, которое будет обработано в контроллере
          debugPrint('TicketsCollection.cancelTicketKgu: Failed to fetch updated ticket, but cancellation was successful (200). Error: $e');
          // Выбрасываем исключение с кодом 200, чтобы контроллер понял, что отмена успешна
          throw TicketsException('Ticket cancelled successfully', 200);
        }
      }
      
      // Если ответ содержит полный объект тикета, парсим его
      return TicketDto.fromJson(data);
    } on DioException catch (e) {
      debugPrint('TicketsCollection.cancelTicketKgu: DioException: ${e.type}');
      debugPrint('TicketsCollection.cancelTicketKgu: Status code: ${e.response?.statusCode}');
      debugPrint('TicketsCollection.cancelTicketKgu: Response data: ${e.response?.data}');
      _handleError(e);
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('TicketsCollection.cancelTicketKgu: Unexpected error: $e');
      debugPrint('TicketsCollection.cancelTicketKgu: Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// PUT /kgu/tickets/:id/close - Закрыть тикет
  Future<TicketDto> closeTicketKgu(String id) async {
    try {
      final response = await dio.put('/kgu/tickets/$id/close');
      final responseData = response.data;
      if (responseData is! Map<String, dynamic> || !responseData.containsKey('data')) {
        throw TicketsException('Invalid response format');
      }
      return TicketDto.fromJson(responseData['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // ==================== Contractor Tickets ====================

  /// GET /contractor/tickets - Получить тикеты подрядчика
  Future<List<TicketDto>> getTicketsContractor({
    String? status,
    String? cleaningAreaId,
    String? contractId,
    DateTime? plannedStartFrom,
    DateTime? plannedStartTo,
    DateTime? plannedEndFrom,
    DateTime? plannedEndTo,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;
      if (cleaningAreaId != null) queryParams['cleaning_area_id'] = cleaningAreaId;
      if (contractId != null) queryParams['contract_id'] = contractId;
      if (plannedStartFrom != null) queryParams['planned_start_from'] = _formatDateTimeRfc3339(plannedStartFrom);
      if (plannedStartTo != null) queryParams['planned_start_to'] = _formatDateTimeRfc3339(plannedStartTo);
      if (plannedEndFrom != null) queryParams['planned_end_from'] = _formatDateTimeRfc3339(plannedEndFrom);
      if (plannedEndTo != null) queryParams['planned_end_to'] = _formatDateTimeRfc3339(plannedEndTo);

      debugPrint('TicketsCollection.getTicketsContractor: Request URL: /contractor/tickets');
      debugPrint('TicketsCollection.getTicketsContractor: Query params: $queryParams');
      debugPrint('TicketsCollection.getTicketsContractor: Note: contractor_id is automatically determined from JWT token');

      final response = await dio.get(
        '/contractor/tickets',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );
      
      debugPrint('TicketsCollection.getTicketsContractor: Response status: ${response.statusCode}');

      final responseData = response.data;
      if (responseData is! Map<String, dynamic> || !responseData.containsKey('data')) {
        throw TicketsException('Invalid response format');
      }

      final List<dynamic> data = responseData['data'] as List<dynamic>? ?? [];
      debugPrint('TicketsCollection.getTicketsContractor: Received ${data.length} tickets');
      final tickets = data.map((json) => TicketDto.fromJson(json as Map<String, dynamic>)).toList();
      if (tickets.isNotEmpty) {
        debugPrint('TicketsCollection.getTicketsContractor: First ticket contractor_id: ${tickets.first.contractorId}');
      }
      return tickets;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// GET /contractor/tickets/:id - Получить тикет подрядчика
  Future<TicketDto> getTicketContractor(String id) async {
    try {
      final response = await dio.get('/contractor/tickets/$id');
      final responseData = response.data;
      if (responseData is! Map<String, dynamic> || !responseData.containsKey('data')) {
        throw TicketsException('Invalid response format');
      }
      return TicketDto.fromJson(responseData['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// PUT /contractor/tickets/:id/complete - Завершить тикет
  Future<TicketDto> completeTicketContractor(String id) async {
    try {
      final response = await dio.put('/contractor/tickets/$id/complete');
      final responseData = response.data;
      if (responseData is! Map<String, dynamic> || !responseData.containsKey('data')) {
        throw TicketsException('Invalid response format');
      }
      return TicketDto.fromJson(responseData['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // ==================== Contractor Assignments ====================

  /// POST /contractor/tickets/:id/assignments - Создать назначение
  Future<TicketAssignmentDto> createAssignmentContractor(
    String ticketId, {
    required String driverId,
    required String vehicleId,
  }) async {
    try {
      final data = {
        'driver_id': driverId,
        'vehicle_id': vehicleId,
      };

      debugPrint('TicketsCollection.createAssignmentContractor: Request URL: /contractor/tickets/$ticketId/assignments');
      debugPrint('TicketsCollection.createAssignmentContractor: Request data: $data');

      final response = await dio.post('/contractor/tickets/$ticketId/assignments', data: data);
      
      debugPrint('TicketsCollection.createAssignmentContractor: Response status: ${response.statusCode}');

      final responseData = response.data;
      if (responseData is! Map<String, dynamic> || !responseData.containsKey('data')) {
        throw TicketsException('Invalid response format');
      }

      return TicketAssignmentDto.fromJson(responseData['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('TicketsCollection.createAssignmentContractor: DioException: ${e.type}');
      debugPrint('TicketsCollection.createAssignmentContractor: Status code: ${e.response?.statusCode}');
      debugPrint('TicketsCollection.createAssignmentContractor: Response data: ${e.response?.data}');
      _handleError(e);
      rethrow;
    }
  }

  /// GET /contractor/tickets/:id/assignments - Получить назначения
  Future<List<TicketAssignmentDto>> getAssignmentsContractor(String ticketId) async {
    try {
      debugPrint('TicketsCollection.getAssignmentsContractor: Request URL: /contractor/tickets/$ticketId/assignments');
      
      final response = await dio.get('/contractor/tickets/$ticketId/assignments');
      
      debugPrint('TicketsCollection.getAssignmentsContractor: Response status: ${response.statusCode}');
      
      final responseData = response.data;
      if (responseData is! Map<String, dynamic> || !responseData.containsKey('data')) {
        throw TicketsException('Invalid response format');
      }
      final List<dynamic> data = responseData['data'] as List<dynamic>? ?? [];
      debugPrint('TicketsCollection.getAssignmentsContractor: Received ${data.length} assignments');
      return data.map((json) => TicketAssignmentDto.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      debugPrint('TicketsCollection.getAssignmentsContractor: DioException: ${e.type}');
      debugPrint('TicketsCollection.getAssignmentsContractor: Status code: ${e.response?.statusCode}');
      debugPrint('TicketsCollection.getAssignmentsContractor: Response data: ${e.response?.data}');
      _handleError(e);
      rethrow;
    }
  }

  /// DELETE /contractor/assignments/:id - Удалить назначение
  Future<void> deleteAssignmentContractor(String assignmentId) async {
    try {
      debugPrint('TicketsCollection.deleteAssignmentContractor: Request URL: /contractor/assignments/$assignmentId');
      
      await dio.delete('/contractor/assignments/$assignmentId');
      
      debugPrint('TicketsCollection.deleteAssignmentContractor: Successfully deleted assignment $assignmentId');
    } on DioException catch (e) {
      debugPrint('TicketsCollection.deleteAssignmentContractor: DioException: ${e.type}');
      debugPrint('TicketsCollection.deleteAssignmentContractor: Status code: ${e.response?.statusCode}');
      debugPrint('TicketsCollection.deleteAssignmentContractor: Response data: ${e.response?.data}');
      _handleError(e);
      rethrow;
    }
  }

  // ==================== Akimat Tickets ====================

  /// GET /akimat/tickets - Получить все тикеты (Акимат)
  Future<List<TicketDto>> getTicketsAkimat({
    String? status,
    String? contractorId,
    String? cleaningAreaId,
    String? contractId,
    DateTime? plannedStartFrom,
    DateTime? plannedStartTo,
    DateTime? plannedEndFrom,
    DateTime? plannedEndTo,
    DateTime? factStartFrom,
    DateTime? factStartTo,
    DateTime? factEndFrom,
    DateTime? factEndTo,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;
      if (contractorId != null) queryParams['contractor_id'] = contractorId;
      if (cleaningAreaId != null) queryParams['cleaning_area_id'] = cleaningAreaId;
      if (contractId != null) queryParams['contract_id'] = contractId;
      if (plannedStartFrom != null) queryParams['planned_start_from'] = _formatDateTimeRfc3339(plannedStartFrom);
      if (plannedStartTo != null) queryParams['planned_start_to'] = _formatDateTimeRfc3339(plannedStartTo);
      if (plannedEndFrom != null) queryParams['planned_end_from'] = _formatDateTimeRfc3339(plannedEndFrom);
      if (plannedEndTo != null) queryParams['planned_end_to'] = _formatDateTimeRfc3339(plannedEndTo);
      if (factStartFrom != null) queryParams['fact_start_from'] = _formatDateTimeRfc3339(factStartFrom);
      if (factStartTo != null) queryParams['fact_start_to'] = _formatDateTimeRfc3339(factStartTo);
      if (factEndFrom != null) queryParams['fact_end_from'] = _formatDateTimeRfc3339(factEndFrom);
      if (factEndTo != null) queryParams['fact_end_to'] = _formatDateTimeRfc3339(factEndTo);

      debugPrint('TicketsCollection.getTicketsAkimat: Request URL: /akimat/tickets');
      debugPrint('TicketsCollection.getTicketsAkimat: Query params: $queryParams');

      final response = await dio.get(
        '/akimat/tickets',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );
      
      debugPrint('TicketsCollection.getTicketsAkimat: Response status: ${response.statusCode}');

      final responseData = response.data;
      if (responseData is! Map<String, dynamic> || !responseData.containsKey('data')) {
        throw TicketsException('Invalid response format');
      }

      final List<dynamic> data = responseData['data'] as List<dynamic>? ?? [];
      debugPrint('TicketsCollection.getTicketsAkimat: Received ${data.length} tickets');
      final tickets = data.map((json) => TicketDto.fromJson(json as Map<String, dynamic>)).toList();
      if (tickets.isNotEmpty) {
        debugPrint('TicketsCollection.getTicketsAkimat: First ticket ID: ${tickets.first.id}');
        debugPrint('TicketsCollection.getTicketsAkimat: First ticket status: ${tickets.first.status}');
      }
      return tickets;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// GET /akimat/tickets/:id - Получить тикет (Акимат)
  Future<TicketDto> getTicketAkimat(String id) async {
    try {
      final response = await dio.get('/akimat/tickets/$id');
      final responseData = response.data;
      if (responseData is! Map<String, dynamic> || !responseData.containsKey('data')) {
        throw TicketsException('Invalid response format');
      }
      return TicketDto.fromJson(responseData['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // ==================== Driver Tickets ====================

  /// GET /driver/tickets - Получить тикеты водителя
  Future<List<TicketDto>> getTicketsDriver({
    String? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;

      debugPrint('TicketsCollection.getTicketsDriver: Request URL: /driver/tickets');
      debugPrint('TicketsCollection.getTicketsDriver: Query params: $queryParams');

      final response = await dio.get(
        '/driver/tickets',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      debugPrint('TicketsCollection.getTicketsDriver: Response status: ${response.statusCode}');

      final responseData = response.data;
      if (responseData is! Map<String, dynamic> || !responseData.containsKey('data')) {
        throw TicketsException('Invalid response format');
      }

      final List<dynamic> data = responseData['data'] as List<dynamic>? ?? [];
      debugPrint('TicketsCollection.getTicketsDriver: Received ${data.length} tickets');
      return data.map((json) => TicketDto.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// GET /driver/tickets/:id - Получить тикет водителя
  Future<TicketDto> getTicketDriver(String id) async {
    try {
      final response = await dio.get('/driver/tickets/$id');
      final responseData = response.data;
      if (responseData is! Map<String, dynamic> || !responseData.containsKey('data')) {
        throw TicketsException('Invalid response format');
      }
      return TicketDto.fromJson(responseData['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // ==================== Driver Assignments ====================

  /// PUT /driver/assignments/:id/mark-in-work - Установить статус назначения IN_WORK
  Future<TicketAssignmentDto> markAssignmentInWork(String assignmentId) async {
    try {
      debugPrint('TicketsCollection.markAssignmentInWork: Request URL: /driver/assignments/$assignmentId/mark-in-work');
      
      final response = await dio.put('/driver/assignments/$assignmentId/mark-in-work');
      
      debugPrint('TicketsCollection.markAssignmentInWork: Response status: ${response.statusCode}');

      final responseData = response.data;
      if (responseData is! Map<String, dynamic> || !responseData.containsKey('data')) {
        throw TicketsException('Invalid response format');
      }

      return TicketAssignmentDto.fromJson(responseData['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('TicketsCollection.markAssignmentInWork: DioException: ${e.type}');
      debugPrint('TicketsCollection.markAssignmentInWork: Status code: ${e.response?.statusCode}');
      debugPrint('TicketsCollection.markAssignmentInWork: Response data: ${e.response?.data}');
      _handleError(e);
      rethrow;
    }
  }

  /// PUT /driver/assignments/:id/mark-completed - Установить статус назначения COMPLETED
  Future<TicketAssignmentDto> markAssignmentCompleted(String assignmentId) async {
    try {
      debugPrint('TicketsCollection.markAssignmentCompleted: Request URL: /driver/assignments/$assignmentId/mark-completed');
      
      final response = await dio.put('/driver/assignments/$assignmentId/mark-completed');
      
      debugPrint('TicketsCollection.markAssignmentCompleted: Response status: ${response.statusCode}');

      final responseData = response.data;
      if (responseData is! Map<String, dynamic> || !responseData.containsKey('data')) {
        throw TicketsException('Invalid response format');
      }

      return TicketAssignmentDto.fromJson(responseData['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('TicketsCollection.markAssignmentCompleted: DioException: ${e.type}');
      debugPrint('TicketsCollection.markAssignmentCompleted: Status code: ${e.response?.statusCode}');
      debugPrint('TicketsCollection.markAssignmentCompleted: Response data: ${e.response?.data}');
      _handleError(e);
      rethrow;
    }
  }
}

