import 'package:akimat_project/services/operations/model/camera_dto.dart';
import 'package:akimat_project/services/operations/model/camera_polygon_dto.dart';
import 'package:akimat_project/services/operations/model/cleaning_area_access_dto.dart';
import 'package:akimat_project/services/operations/model/cleaning_area_dto.dart';
import 'package:akimat_project/services/operations/model/polygon_access_dto.dart';
import 'package:akimat_project/services/operations/model/polygon_dto.dart';
import 'package:akimat_project/services/operations/model/ticket_assignment_dto.dart';
import 'package:akimat_project/services/operations/model/ticket_dto.dart';
import 'package:akimat_project/services/operations/model/ticket_template_dto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Ошибки Operations Service
class OperationsException implements Exception {
  final String message;
  final int? statusCode;

  OperationsException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class OperationsCollection {
  final Dio dio;

  OperationsCollection({required this.dio});

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
          throw OperationsException(errorMessage, 400);
        case 401:
          throw OperationsException(errorMessage, 401);
        case 403:
          throw OperationsException(errorMessage, 403);
        case 404:
          throw OperationsException(errorMessage, 404);
        case 409:
          throw OperationsException(errorMessage, 409);
        default:
          throw OperationsException(errorMessage, statusCode);
      }
    } else {
      throw OperationsException(
        error.message ?? 'Network error: ${error.type}',
        null,
      );
    }
  }

  // ==================== Cleaning Areas ====================

  /// GET /cleaning-areas - Получить список участков
  Future<List<CleaningAreaDto>> getCleaningAreas({
    String? status,
    bool? onlyActive,
    String? city,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) {
        queryParams['status'] = status;
      }
      if (onlyActive != null) {
        // Go бэкенды обычно ожидают строку "true"/"false" для булевых query параметров
        queryParams['only_active'] = onlyActive ? 'true' : 'false';
      }
      if (city != null) {
        queryParams['city'] = city;
      }

      debugPrint('OperationsCollection.getCleaningAreas: Request URL: /cleaning-areas');
      debugPrint('OperationsCollection.getCleaningAreas: Query params: $queryParams');

      final response = await dio.get(
        '/cleaning-areas',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      debugPrint('OperationsCollection.getCleaningAreas: Response status: ${response.statusCode}');
      debugPrint('OperationsCollection.getCleaningAreas: Response data: ${response.data}');

      final responseData = response.data;
      if (responseData is! Map<String, dynamic>) {
        throw OperationsException('Invalid response format: expected Map, got ${responseData.runtimeType}');
      }

      if (!responseData.containsKey('data')) {
        debugPrint('OperationsCollection.getCleaningAreas: Response missing "data" key. Full response: $responseData');
        throw OperationsException('Response missing "data" key');
      }

      final List<dynamic> data = responseData['data'] as List<dynamic>? ?? [];
      debugPrint('OperationsCollection.getCleaningAreas: Parsed ${data.length} areas');
      
      return data
          .map((json) => CleaningAreaDto.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      debugPrint('OperationsCollection.getCleaningAreas: DioException: ${e.type}');
      debugPrint('OperationsCollection.getCleaningAreas: Status code: ${e.response?.statusCode}');
      debugPrint('OperationsCollection.getCleaningAreas: Response data: ${e.response?.data}');
      debugPrint('OperationsCollection.getCleaningAreas: Error message: ${e.message}');
      
      // Для 500 ошибок выводим более детальную информацию
      if (e.response?.statusCode == 500) {
        final errorData = e.response?.data;
        if (errorData is Map<String, dynamic> && errorData.containsKey('error')) {
          debugPrint('OperationsCollection.getCleaningAreas: Server error: ${errorData['error']}');
        }
      }
      
      _handleError(e);
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('OperationsCollection.getCleaningAreas: Unexpected error: $e');
      debugPrint('OperationsCollection.getCleaningAreas: Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// POST /cleaning-areas - Создать участок
  Future<CleaningAreaDto> createCleaningArea({
    required String name,
    String? description,
    required String geometry, // GeoJSON string
    String? city,
    String? defaultContractorId,
  }) async {
    try {
      final requestData = {
        'name': name,
        if (description != null) 'description': description,
        'geometry': geometry,
        if (city != null) 'city': city,
        if (defaultContractorId != null)
          'default_contractor_id': defaultContractorId,
      };

      debugPrint('OperationsCollection.createCleaningArea: Request URL: /cleaning-areas');
      debugPrint('OperationsCollection.createCleaningArea: Request data: ${requestData.keys}');
      debugPrint('OperationsCollection.createCleaningArea: Geometry length: ${geometry.length}');
      debugPrint('OperationsCollection.createCleaningArea: Geometry preview: ${geometry.length > 100 ? "${geometry.substring(0, 100)}..." : geometry}');

      final response = await dio.post(
        '/cleaning-areas',
        data: requestData,
      );

      debugPrint('OperationsCollection.createCleaningArea: Response status: ${response.statusCode}');
      debugPrint('OperationsCollection.createCleaningArea: Response data: ${response.data}');

      final responseData = response.data;
      if (responseData is! Map<String, dynamic>) {
        throw OperationsException('Invalid response format: expected Map, got ${responseData.runtimeType}');
      }

      if (!responseData.containsKey('data')) {
        debugPrint('OperationsCollection.createCleaningArea: Response missing "data" key. Full response: $responseData');
        throw OperationsException('Response missing "data" key');
      }

      return CleaningAreaDto.fromJson(responseData['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('OperationsCollection.createCleaningArea: DioException: ${e.type}');
      debugPrint('OperationsCollection.createCleaningArea: Status code: ${e.response?.statusCode}');
      debugPrint('OperationsCollection.createCleaningArea: Response data: ${e.response?.data}');
      debugPrint('OperationsCollection.createCleaningArea: Error message: ${e.message}');
      
      // Для 500 ошибок выводим более детальную информацию
      if (e.response?.statusCode == 500) {
        final errorData = e.response?.data;
        if (errorData is Map<String, dynamic> && errorData.containsKey('error')) {
          debugPrint('OperationsCollection.createCleaningArea: Server error: ${errorData['error']}');
        }
      }
      
      _handleError(e);
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('OperationsCollection.createCleaningArea: Unexpected error: $e');
      debugPrint('OperationsCollection.createCleaningArea: Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// GET /cleaning-areas/:id - Получить участок по ID
  Future<CleaningAreaDto> getCleaningArea(String id) async {
    try {
      final response = await dio.get('/cleaning-areas/$id');
      return CleaningAreaDto.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// PATCH /cleaning-areas/:id - Обновить метаданные участка
  Future<CleaningAreaDto> updateCleaningArea(
    String id, {
    String? name,
    String? description,
    String? status,
    String? defaultContractorId,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) {
        data['name'] = name;
      }
      if (description != null) {
        data['description'] = description;
      }
      if (status != null) {
        data['status'] = status;
      }
      if (defaultContractorId != null) {
        data['default_contractor_id'] = defaultContractorId;
      }

      final response = await dio.patch('/cleaning-areas/$id', data: data);
      return CleaningAreaDto.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// PATCH /cleaning-areas/:id/geometry - Обновить геометрию участка
  Future<CleaningAreaDto> updateCleaningAreaGeometry(
    String id, {
    required String geometry, // GeoJSON string
  }) async {
    try {
      final response = await dio.patch(
        '/cleaning-areas/$id/geometry',
        data: {'geometry': geometry},
      );
      return CleaningAreaDto.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// GET /cleaning-areas/:id/access - История доступа подрядчиков
  Future<List<CleaningAreaAccessDto>> getCleaningAreaAccess(String id) async {
    try {
      final response = await dio.get('/cleaning-areas/$id/access');
      final List<dynamic> data = response.data['data'] ?? [];
      return data
          .map((json) =>
              CleaningAreaAccessDto.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// POST /cleaning-areas/:id/access - Выдать доступ подрядчику
  Future<CleaningAreaAccessDto> grantCleaningAreaAccess(
    String id, {
    required String contractorId,
    required String source, // "TICKETS" or "MANUAL"
  }) async {
    try {
      final response = await dio.post(
        '/cleaning-areas/$id/access',
        data: {
          'contractor_id': contractorId,
          'source': source,
        },
      );
      return CleaningAreaAccessDto.fromJson(
          response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// DELETE /cleaning-areas/:id/access/:contractorId - Отозвать доступ
  Future<void> revokeCleaningAreaAccess(
    String id,
    String contractorId,
  ) async {
    try {
      await dio.delete('/cleaning-areas/$id/access/$contractorId');
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// GET /cleaning-areas/:id/ticket-template - Шаблон для создания тикета
  Future<TicketTemplateDto> getCleaningAreaTicketTemplate(String id) async {
    try {
      final response = await dio.get('/cleaning-areas/$id/ticket-template');
      return TicketTemplateDto.fromJson(
          response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // ==================== Polygons ====================

  /// GET /polygons - Получить список полигонов
  Future<List<PolygonDto>> getPolygons({bool? onlyActive}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (onlyActive != null) {
        // Go бэкенды обычно ожидают строку "true"/"false" для булевых query параметров
        queryParams['only_active'] = onlyActive ? 'true' : 'false';
      }

      debugPrint('OperationsCollection.getPolygons: Request URL: /polygons');
      debugPrint('OperationsCollection.getPolygons: Query params: $queryParams');

      final response = await dio.get(
        '/polygons',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      debugPrint('OperationsCollection.getPolygons: Response status: ${response.statusCode}');

      final List<dynamic> data = response.data['data'] ?? [];
      return data
          .map((json) => PolygonDto.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// POST /polygons - Создать полигон
  Future<PolygonDto> createPolygon({
    required String name,
    String? address,
    String? description,
    required String geometry, // GeoJSON string
    required bool isActive,
  }) async {
    try {
      final response = await dio.post(
        '/polygons',
        data: {
          'name': name,
          if (address != null) 'address': address,
          if (description != null) 'description': description,
          'geometry': geometry,
          'is_active': isActive,
        },
      );
      return PolygonDto.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// GET /polygons/:id - Получить полигон по ID
  Future<PolygonDto> getPolygon(String id) async {
    try {
      final response = await dio.get('/polygons/$id');
      return PolygonDto.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// PATCH /polygons/:id - Обновить метаданные полигона
  Future<PolygonDto> updatePolygon(
    String id, {
    String? name,
    String? address,
    String? description,
    bool? isActive,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (address != null) data['address'] = address;
      if (description != null) data['description'] = description;
      if (isActive != null) data['is_active'] = isActive;

      final response = await dio.patch('/polygons/$id', data: data);
      return PolygonDto.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// PATCH /polygons/:id/geometry - Обновить геометрию полигона
  Future<PolygonDto> updatePolygonGeometry(
    String id, {
    required String geometry, // GeoJSON string
  }) async {
    try {
      final response = await dio.patch(
        '/polygons/$id/geometry',
        data: {'geometry': geometry},
      );
      return PolygonDto.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// GET /polygons/:id/access - История доступа подрядчиков
  Future<List<PolygonAccessDto>> getPolygonAccess(String id) async {
    try {
      final response = await dio.get('/polygons/$id/access');
      final List<dynamic> data = response.data['data'] ?? [];
      return data
          .map((json) => PolygonAccessDto.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// POST /polygons/:id/access - Выдать доступ подрядчику
  Future<PolygonAccessDto> grantPolygonAccess(
    String id, {
    required String contractorId,
    required String source, // "TICKETS" or "MANUAL"
  }) async {
    try {
      final response = await dio.post(
        '/polygons/$id/access',
        data: {
          'contractor_id': contractorId,
          'source': source,
        },
      );
      return PolygonAccessDto.fromJson(
          response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// DELETE /polygons/:id/access/:contractorId - Отозвать доступ
  Future<void> revokePolygonAccess(String id, String contractorId) async {
    try {
      await dio.delete('/polygons/$id/access/$contractorId');
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // ==================== Cameras ====================

  /// GET /polygons/:id/cameras - Список камер полигона
  Future<List<CameraDto>> getPolygonCameras(String polygonId) async {
    try {
      final response = await dio.get('/polygons/$polygonId/cameras');
      final List<dynamic> data = response.data['data'] ?? [];
      return data
          .map((json) => CameraDto.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// POST /polygons/:id/cameras - Создать камеру
  Future<CameraDto> createCamera(
    String polygonId, {
    required String type, // "LPR" or "VOLUME"
    required String name,
    String? location, // GeoJSON Point string
    required bool isActive,
  }) async {
    try {
      final response = await dio.post(
        '/polygons/$polygonId/cameras',
        data: {
          'type': type,
          'name': name,
          if (location != null) 'location': location,
          'is_active': isActive,
        },
      );
      return CameraDto.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// PATCH /polygons/:id/cameras/:cameraId - Обновить камеру
  Future<CameraDto> updateCamera(
    String polygonId,
    String cameraId, {
    String? type,
    String? name,
    String? location,
    bool? isActive,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (type != null) data['type'] = type;
      if (name != null) data['name'] = name;
      if (location != null) data['location'] = location;
      if (isActive != null) data['is_active'] = isActive;

      final response =
          await dio.patch('/polygons/$polygonId/cameras/$cameraId', data: data);
      return CameraDto.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // ==================== Integrations ====================

  /// POST /integrations/polygons/:id/contains - Проверка точки в полигоне
  Future<bool> checkPointInPolygon(
    String polygonId, {
    required double lat,
    required double lng,
  }) async {
    try {
      final response = await dio.post(
        '/integrations/polygons/$polygonId/contains',
        data: {
          'lat': lat,
          'lng': lng,
        },
      );
      final inside = response.data['data']?['inside'] as bool?;
      return inside ?? false;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// GET /integrations/cameras/:id/polygon - Получить камеру и полигон
  Future<CameraPolygonDto> getCameraPolygon(String cameraId) async {
    try {
      final response = await dio.get('/integrations/cameras/$cameraId/polygon');
      return CameraPolygonDto.fromJson(
          response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // ==================== Monitoring ====================

  /// GET /monitoring/vehicles-live - Получить список техники с последними GPS-координатами
  Future<Map<String, dynamic>> getVehiclesLive({
    double? minLat,
    double? minLon,
    double? maxLat,
    double? maxLon,
    String? contractorId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (minLat != null) queryParams['min_lat'] = minLat;
      if (minLon != null) queryParams['min_lon'] = minLon;
      if (maxLat != null) queryParams['max_lat'] = maxLat;
      if (maxLon != null) queryParams['max_lon'] = maxLon;
      if (contractorId != null) queryParams['contractor_id'] = contractorId;

      debugPrint('OperationsCollection.getVehiclesLive: Request URL: /monitoring/vehicles-live');
      debugPrint('OperationsCollection.getVehiclesLive: Query params: $queryParams');

      final response = await dio.get(
        '/monitoring/vehicles-live',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      debugPrint('OperationsCollection.getVehiclesLive: Response status: ${response.statusCode}');
      
      final responseData = response.data;
      if (responseData is! Map<String, dynamic> || !responseData.containsKey('data')) {
        throw OperationsException('Invalid response format: expected {data: {...}}');
      }

      final data = responseData['data'] as Map<String, dynamic>;
      final vehicles = data['vehicles'] as List<dynamic>? ?? [];
      debugPrint('OperationsCollection.getVehiclesLive: Received ${vehicles.length} vehicles');
      
      if (vehicles.isNotEmpty) {
        final firstVehicle = vehicles.first as Map<String, dynamic>;
        debugPrint('OperationsCollection.getVehiclesLive: First vehicle ID: ${firstVehicle['vehicle_id']}');
        debugPrint('OperationsCollection.getVehiclesLive: First vehicle status: ${firstVehicle['status']}');
      }

      return data;
    } on DioException catch (e) {
      debugPrint('OperationsCollection.getVehiclesLive: DioException: ${e.type}');
      debugPrint('OperationsCollection.getVehiclesLive: Status code: ${e.response?.statusCode}');
      debugPrint('OperationsCollection.getVehiclesLive: Response data: ${e.response?.data}');
      _handleError(e);
      rethrow;
    }
  }

  /// GET /monitoring/vehicles/:id/track - Получить трек машины за период
  /// Формат дат: RFC 3339 (например: 2025-11-16T18:00:00Z)
  Future<Map<String, dynamic>> getVehicleTrack(
    String vehicleId, {
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (from != null) {
        // RFC 3339 формат: YYYY-MM-DDTHH:mm:ssZ
        final fromUtc = from.toUtc();
        queryParams['from'] = '${fromUtc.toIso8601String().split('.')[0]}Z';
      }
      if (to != null) {
        // RFC 3339 формат: YYYY-MM-DDTHH:mm:ssZ
        final toUtc = to.toUtc();
        queryParams['to'] = '${toUtc.toIso8601String().split('.')[0]}Z';
      }

      final response = await dio.get(
        '/monitoring/vehicles/$vehicleId/track',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // ==================== Tickets ====================

  /// GET /tickets - Получить список тикетов
  Future<List<TicketDto>> getTickets({
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
    String? driverId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) {
        queryParams['status'] = status;
      }
      if (contractorId != null) {
        queryParams['contractor_id'] = contractorId;
      }
      if (cleaningAreaId != null) {
        queryParams['cleaning_area_id'] = cleaningAreaId;
      }
      if (contractId != null) {
        queryParams['contract_id'] = contractId;
      }
      if (plannedStartFrom != null) {
        queryParams['planned_start_from'] = plannedStartFrom.toIso8601String();
      }
      if (plannedStartTo != null) {
        queryParams['planned_start_to'] = plannedStartTo.toIso8601String();
      }
      if (plannedEndFrom != null) {
        queryParams['planned_end_from'] = plannedEndFrom.toIso8601String();
      }
      if (plannedEndTo != null) {
        queryParams['planned_end_to'] = plannedEndTo.toIso8601String();
      }
      if (factStartFrom != null) {
        queryParams['fact_start_from'] = factStartFrom.toIso8601String();
      }
      if (factStartTo != null) {
        queryParams['fact_start_to'] = factStartTo.toIso8601String();
      }
      if (factEndFrom != null) {
        queryParams['fact_end_from'] = factEndFrom.toIso8601String();
      }
      if (factEndTo != null) {
        queryParams['fact_end_to'] = factEndTo.toIso8601String();
      }
      if (driverId != null) {
        queryParams['driver_id'] = driverId;
      }

      debugPrint('OperationsCollection.getTickets: Request URL: /tickets');
      debugPrint('OperationsCollection.getTickets: Query params: $queryParams');

      final response = await dio.get(
        '/tickets',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      debugPrint('OperationsCollection.getTickets: Response status: ${response.statusCode}');

      final responseData = response.data;
      if (responseData is! Map<String, dynamic>) {
        throw OperationsException('Invalid response format: expected Map, got ${responseData.runtimeType}');
      }

      if (!responseData.containsKey('data')) {
        debugPrint('OperationsCollection.getTickets: Response missing "data" key. Full response: $responseData');
        throw OperationsException('Response missing "data" key');
      }

      final List<dynamic> data = responseData['data'] as List<dynamic>? ?? [];
      debugPrint('OperationsCollection.getTickets: Parsed ${data.length} tickets');

      return data
          .map((json) => TicketDto.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      debugPrint('OperationsCollection.getTickets: DioException: ${e.type}');
      debugPrint('OperationsCollection.getTickets: Status code: ${e.response?.statusCode}');
      debugPrint('OperationsCollection.getTickets: Response data: ${e.response?.data}');
      debugPrint('OperationsCollection.getTickets: Error message: ${e.message}');
      _handleError(e);
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('OperationsCollection.getTickets: Unexpected error: $e');
      debugPrint('OperationsCollection.getTickets: Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// GET /tickets/:id - Получить тикет по ID
  Future<TicketDto> getTicket(String id) async {
    try {
      final response = await dio.get('/tickets/$id');
      final responseData = response.data;
      if (responseData is! Map<String, dynamic> || !responseData.containsKey('data')) {
        throw OperationsException('Invalid response format');
      }
      return TicketDto.fromJson(responseData['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// POST /tickets - Создать тикет
  Future<TicketDto> createTicket({
    required String cleaningAreaId,
    required String contractorId,
    required String contractId,
    required DateTime plannedStartAt,
    required DateTime plannedEndAt,
    String? description,
    String? createdByOrgId,
  }) async {
    try {
      final data = {
        'cleaning_area_id': cleaningAreaId,
        'contractor_id': contractorId,
        'contract_id': contractId,
        'planned_start_at': plannedStartAt.toIso8601String(),
        'planned_end_at': plannedEndAt.toIso8601String(),
        if (description != null) 'description': description,
        if (createdByOrgId != null) 'created_by_org_id': createdByOrgId,
      };

      debugPrint('OperationsCollection.createTicket: Request data: $data');

      final response = await dio.post('/tickets', data: data);

      debugPrint('OperationsCollection.createTicket: Response status: ${response.statusCode}');

      final responseData = response.data;
      if (responseData is! Map<String, dynamic> || !responseData.containsKey('data')) {
        throw OperationsException('Invalid response format');
      }

      return TicketDto.fromJson(responseData['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('OperationsCollection.createTicket: DioException: ${e.type}');
      debugPrint('OperationsCollection.createTicket: Status code: ${e.response?.statusCode}');
      debugPrint('OperationsCollection.createTicket: Response data: ${e.response?.data}');
      _handleError(e);
      rethrow;
    }
  }

  /// PUT /tickets/:id - Обновить тикет
  Future<TicketDto> updateTicket(
    String id, {
    String? cleaningAreaId,
    String? contractorId,
    String? contractId,
    DateTime? plannedStartAt,
    DateTime? plannedEndAt,
    String? description,
    String? status,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (cleaningAreaId != null) data['cleaning_area_id'] = cleaningAreaId;
      if (contractorId != null) data['contractor_id'] = contractorId;
      if (contractId != null) data['contract_id'] = contractId;
      if (plannedStartAt != null) data['planned_start_at'] = plannedStartAt.toIso8601String();
      if (plannedEndAt != null) data['planned_end_at'] = plannedEndAt.toIso8601String();
      if (description != null) data['description'] = description;
      if (status != null) data['status'] = status;

      debugPrint('OperationsCollection.updateTicket: Request data: $data');

      final response = await dio.put('/tickets/$id', data: data);

      final responseData = response.data;
      if (responseData is! Map<String, dynamic> || !responseData.containsKey('data')) {
        throw OperationsException('Invalid response format');
      }

      return TicketDto.fromJson(responseData['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// PUT /tickets/:id/status - Изменить статус тикета
  Future<TicketDto> updateTicketStatus(
    String id, {
    required String status,
  }) async {
    try {
      final response = await dio.put(
        '/tickets/$id/status',
        data: {'status': status},
      );

      final responseData = response.data;
      if (responseData is! Map<String, dynamic> || !responseData.containsKey('data')) {
        throw OperationsException('Invalid response format');
      }

      return TicketDto.fromJson(responseData['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // ==================== Ticket Assignments ====================

  /// GET /tickets/:id/assignments - Получить назначения тикета
  Future<List<TicketAssignmentDto>> getTicketAssignments(String ticketId) async {
    try {
      final response = await dio.get('/tickets/$ticketId/assignments');
      final responseData = response.data;
      if (responseData is! Map<String, dynamic> || !responseData.containsKey('data')) {
        throw OperationsException('Invalid response format');
      }
      final List<dynamic> data = responseData['data'] as List<dynamic>? ?? [];
      return data
          .map((json) => TicketAssignmentDto.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// POST /tickets/:id/assignments - Создать назначение
  Future<TicketAssignmentDto> createTicketAssignment(
    String ticketId, {
    String? driverId,
    String? vehicleId,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (driverId != null) data['driver_id'] = driverId;
      if (vehicleId != null) data['vehicle_id'] = vehicleId;

      final response = await dio.post('/tickets/$ticketId/assignments', data: data);

      final responseData = response.data;
      if (responseData is! Map<String, dynamic> || !responseData.containsKey('data')) {
        throw OperationsException('Invalid response format');
      }

      return TicketAssignmentDto.fromJson(responseData['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// DELETE /tickets/:id/assignments/:assignmentId - Удалить назначение
  Future<void> deleteTicketAssignment(String ticketId, String assignmentId) async {
    try {
      await dio.delete('/tickets/$ticketId/assignments/$assignmentId');
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // ==================== LANDFILL Reception Journal ====================

  /// GET /landfill/reception-journal - Журнал приёма снега для LANDFILL
  /// Доступ: только LANDFILL_ADMIN и LANDFILL_USER
  /// Возвращает все заезды на полигоны, принадлежащие организации LANDFILL
  Future<Map<String, dynamic>> getLandfillReceptionJournal({
    String? polygonId,
    String? contractorId,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (polygonId != null) {
        queryParams['polygon_id'] = polygonId;
      }
      if (contractorId != null) {
        queryParams['contractor_id'] = contractorId;
      }
      if (dateFrom != null) {
        queryParams['date_from'] = dateFrom.toUtc().toIso8601String();
      }
      if (dateTo != null) {
        queryParams['date_to'] = dateTo.toUtc().toIso8601String();
      }
      if (status != null) {
        queryParams['status'] = status;
      }

      final response = await dio.get(
        '/landfill/reception-journal',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }
}

