import 'package:akimat_project/modules/dashboard/src/model/areas/cleaning_area.dart';
import 'package:akimat_project/modules/dashboard/src/model/polygons/camera.dart';
import 'package:akimat_project/modules/dashboard/src/model/polygons/polygon.dart';
import 'package:akimat_project/modules/dashboard/src/repository/operations_repository.dart';
import 'package:akimat_project/services/operations/model/camera_dto.dart';
import 'package:akimat_project/services/operations/model/cleaning_area_dto.dart';
import 'package:akimat_project/services/operations/model/polygon_dto.dart';
import 'package:akimat_project/services/operations/services.dart';

class OperationsRepositoryImpl implements OperationsRepository {
  OperationsRepositoryImpl({required OperationsServices services})
      : _services = services;

  final OperationsServices _services;

  String? _statusToString(CleaningAreaStatus? status) {
    if (status == null) return null;
    return CleaningAreaDto.statusToString(status);
  }

  String _cameraTypeToString(CameraType type) {
    return CameraDto.typeToString(type);
  }

  // ==================== Cleaning Areas ====================

  @override
  Future<List<CleaningArea>> loadCleaningAreas({
    CleaningAreaStatus? status,
    bool? onlyActive,
    String? city,
  }) async {
    final dtos = await _services.collection.getCleaningAreas(
      status: _statusToString(status),
      onlyActive: onlyActive,
      city: city,
    );
    return dtos.map((dto) => dto.toDomain()).toList();
  }

  @override
  Future<CleaningArea> getCleaningArea(String id) async {
    final dto = await _services.collection.getCleaningArea(id);
    return dto.toDomain();
  }

  @override
  Future<CleaningArea> createCleaningArea({
    required String name,
    String? description,
    required List<List<double>> geometry,
    String? city,
    String? defaultContractorId,
  }) async {
    final geometryJson = CleaningAreaDto.geometryToJson(geometry);
    final dto = await _services.collection.createCleaningArea(
      name: name,
      description: description,
      geometry: geometryJson,
      city: city,
      defaultContractorId: defaultContractorId,
    );
    return dto.toDomain();
  }

  @override
  Future<CleaningArea> updateCleaningArea(
    String id, {
    String? name,
    String? description,
    CleaningAreaStatus? status,
    String? defaultContractorId,
  }) async {
    final dto = await _services.collection.updateCleaningArea(
      id,
      name: name,
      description: description,
      status: _statusToString(status),
      defaultContractorId: defaultContractorId,
    );
    return dto.toDomain();
  }

  @override
  Future<CleaningArea> updateCleaningAreaGeometry(
    String id, {
    required List<List<double>> geometry,
  }) async {
    final geometryJson = CleaningAreaDto.geometryToJson(geometry);
    final dto = await _services.collection.updateCleaningAreaGeometry(
      id,
      geometry: geometryJson,
    );
    return dto.toDomain();
  }

  @override
  Future<CleaningArea> getCleaningAreaTicketTemplate(String id) async {
    final template = await _services.collection.getCleaningAreaTicketTemplate(id);
    return template.area;
  }

  // ==================== Polygons ====================

  @override
  Future<List<Polygon>> loadPolygons({bool? onlyActive}) async {
    final dtos = await _services.collection.getPolygons(onlyActive: onlyActive);
    return dtos.map((dto) => dto.toDomain()).toList();
  }

  @override
  Future<Polygon> getPolygon(String id) async {
    final dto = await _services.collection.getPolygon(id);
    return dto.toDomain();
  }

  @override
  Future<Polygon> createPolygon({
    required String name,
    String? address,
    String? description,
    required List<List<double>> geometry,
    required bool isActive,
  }) async {
    final geometryJson = PolygonDto.geometryToJson(geometry);
    final dto = await _services.collection.createPolygon(
      name: name,
      address: address,
      description: description,
      geometry: geometryJson,
      isActive: isActive,
    );
    return dto.toDomain();
  }

  @override
  Future<Polygon> updatePolygon(
    String id, {
    String? name,
    String? address,
    String? description,
    bool? isActive,
  }) async {
    final dto = await _services.collection.updatePolygon(
      id,
      name: name,
      address: address,
      description: description,
      isActive: isActive,
    );
    return dto.toDomain();
  }

  @override
  Future<Polygon> updatePolygonGeometry(
    String id, {
    required List<List<double>> geometry,
  }) async {
    final geometryJson = PolygonDto.geometryToJson(geometry);
    final dto = await _services.collection.updatePolygonGeometry(
      id,
      geometry: geometryJson,
    );
    return dto.toDomain();
  }

  // ==================== Cameras ====================

  @override
  Future<List<Camera>> getPolygonCameras(String polygonId) async {
    final dtos = await _services.collection.getPolygonCameras(polygonId);
    return dtos.map((dto) => dto.toDomain()).toList();
  }

  @override
  Future<Camera> createCamera({
    required String polygonId,
    required CameraType type,
    required String name,
    List<double>? location,
    required bool isActive,
  }) async {
    final locationJson = CameraDto.locationToJson(location);
    final dto = await _services.collection.createCamera(
      polygonId,
      type: _cameraTypeToString(type),
      name: name,
      location: locationJson,
      isActive: isActive,
    );
    return dto.toDomain();
  }

  @override
  Future<Camera> updateCamera(
    String polygonId,
    String cameraId, {
    CameraType? type,
    String? name,
    List<double>? location,
    bool? isActive,
  }) async {
    final locationJson = CameraDto.locationToJson(location);
    final dto = await _services.collection.updateCamera(
      polygonId,
      cameraId,
      type: type != null ? _cameraTypeToString(type) : null,
      name: name,
      location: locationJson,
      isActive: isActive,
    );
    return dto.toDomain();
  }

  // ==================== Integrations ====================

  @override
  Future<bool> checkPointInPolygon(
    String polygonId, {
    required double lat,
    required double lng,
  }) async {
    return await _services.collection.checkPointInPolygon(
      polygonId,
      lat: lat,
      lng: lng,
    );
  }

  @override
  Future<CameraPolygonResult> getCameraPolygon(String cameraId) async {
    final dto = await _services.collection.getCameraPolygon(cameraId);
    return CameraPolygonResult(
      camera: dto.cameraDomain,
      polygon: dto.polygonDomain,
    );
  }
}

