import 'package:akimat_project/modules/dashboard/src/model/areas/cleaning_area.dart';
import 'package:akimat_project/modules/dashboard/src/model/polygons/camera.dart';
import 'package:akimat_project/modules/dashboard/src/model/polygons/polygon.dart';

/// Результат получения камеры и полигона
class CameraPolygonResult {
  final Camera camera;
  final Polygon polygon;

  CameraPolygonResult({
    required this.camera,
    required this.polygon,
  });
}

abstract class OperationsRepository {
  // ==================== Cleaning Areas ====================

  /// Получить список участков уборки
  Future<List<CleaningArea>> loadCleaningAreas({
    CleaningAreaStatus? status,
    bool? onlyActive,
    String? city,
  });

  /// Получить участок по ID
  Future<CleaningArea> getCleaningArea(String id);

  /// Создать участок уборки
  Future<CleaningArea> createCleaningArea({
    required String name,
    String? description,
    required List<List<double>> geometry,
    String? city,
    String? defaultContractorId,
  });

  /// Обновить метаданные участка
  Future<CleaningArea> updateCleaningArea(
    String id, {
    String? name,
    String? description,
    CleaningAreaStatus? status,
    String? defaultContractorId,
  });

  /// Обновить геометрию участка
  Future<CleaningArea> updateCleaningAreaGeometry(
    String id, {
    required List<List<double>> geometry,
  });

  /// Получить шаблон для создания тикета
  Future<CleaningArea> getCleaningAreaTicketTemplate(String id);

  // ==================== Polygons ====================

  /// Получить список полигонов
  Future<List<Polygon>> loadPolygons({bool? onlyActive});

  /// Получить полигон по ID
  Future<Polygon> getPolygon(String id);

  /// Создать полигон
  Future<Polygon> createPolygon({
    required String name,
    String? address,
    String? description,
    required List<List<double>> geometry,
    required bool isActive,
  });

  /// Обновить метаданные полигона
  Future<Polygon> updatePolygon(
    String id, {
    String? name,
    String? address,
    String? description,
    bool? isActive,
  });

  /// Обновить геометрию полигона
  Future<Polygon> updatePolygonGeometry(
    String id, {
    required List<List<double>> geometry,
  });

  // ==================== Cameras ====================

  /// Получить список камер полигона
  Future<List<Camera>> getPolygonCameras(String polygonId);

  /// Создать камеру
  Future<Camera> createCamera({
    required String polygonId,
    required CameraType type,
    required String name,
    List<double>? location,
    required bool isActive,
  });

  /// Обновить камеру
  Future<Camera> updateCamera(
    String polygonId,
    String cameraId, {
    CameraType? type,
    String? name,
    List<double>? location,
    bool? isActive,
  });

  // ==================== Integrations ====================

  /// Проверить, входит ли точка в полигон
  Future<bool> checkPointInPolygon(
    String polygonId, {
    required double lat,
    required double lng,
  });

  /// Получить камеру и связанный полигон
  Future<CameraPolygonResult> getCameraPolygon(String cameraId);
}
