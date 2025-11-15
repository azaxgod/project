import 'package:akimat_project/services/operations/model/camera_dto.dart';
import 'package:akimat_project/services/operations/model/camera_polygon_dto.dart';
import 'package:akimat_project/services/operations/model/cleaning_area_access_dto.dart';
import 'package:akimat_project/services/operations/model/cleaning_area_dto.dart';
import 'package:akimat_project/services/operations/model/polygon_access_dto.dart';
import 'package:akimat_project/services/operations/model/polygon_dto.dart';
import 'package:akimat_project/services/operations/model/ticket_template_dto.dart';
import 'package:dio/dio.dart';

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
        queryParams['only_active'] = onlyActive;
      }
      if (city != null) {
        queryParams['city'] = city;
      }

      final response = await dio.get(
        '/cleaning-areas',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      final List<dynamic> data = response.data['data'] ?? [];
      return data
          .map((json) => CleaningAreaDto.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      _handleError(e);
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
      final response = await dio.post(
        '/cleaning-areas',
        data: {
          'name': name,
          if (description != null) 'description': description,
          'geometry': geometry,
          if (city != null) 'city': city,
          if (defaultContractorId != null)
            'default_contractor_id': defaultContractorId,
        },
      );

      return CleaningAreaDto.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleError(e);
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
      if (onlyActive != null) queryParams['only_active'] = onlyActive;

      final response = await dio.get(
        '/polygons',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

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
}

