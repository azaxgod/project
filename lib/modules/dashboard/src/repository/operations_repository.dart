import 'package:akimat_project/modules/dashboard/src/model/areas/cleaning_area.dart';
import 'package:akimat_project/modules/dashboard/src/model/monitoring/vehicle_monitoring.dart';
import 'package:akimat_project/modules/dashboard/src/model/polygons/camera.dart';
import 'package:akimat_project/modules/dashboard/src/model/polygons/polygon.dart';
import 'package:akimat_project/modules/dashboard/src/model/polygons/polygon_access.dart';
import 'package:akimat_project/modules/dashboard/src/model/tickets/ticket.dart';
import 'package:akimat_project/modules/dashboard/src/model/tickets/ticket_assignment.dart';

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
    String? contractorId,
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

  /// Получить историю доступа подрядчиков к полигону
  Future<List<PolygonAccess>> getPolygonAccess(String id);

  /// Выдать доступ подрядчику к полигону
  Future<PolygonAccess> grantPolygonAccess(
    String id, {
    required String contractorId,
    required String source, // "TICKETS" or "MANUAL"
  });

  /// Отозвать доступ подрядчика к полигону
  Future<void> revokePolygonAccess(String id, String contractorId);

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

  // ==================== Monitoring ====================

  /// Получить список техники с последними GPS-координатами
  Future<List<VehicleMonitoring>> getVehiclesLive({
    double? minLat,
    double? minLon,
    double? maxLat,
    double? maxLon,
    String? contractorId,
  });

  /// Получить трек машины за период
  Future<VehicleTrack> getVehicleTrack(
    String vehicleId, {
    DateTime? from,
    DateTime? to,
  });

  // ==================== Tickets ====================

  /// Получить список тикетов
  Future<List<Ticket>> loadTickets({
    TicketStatus? status,
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
  });

  /// Получить тикет по ID
  Future<Ticket> getTicket(String id);

  /// Создать тикет
  Future<Ticket> createTicket({
    required String cleaningAreaId,
    required String contractorId,
    required String contractId,
    required DateTime plannedStartAt,
    required DateTime plannedEndAt,
    String? description,
    String? createdByOrgId,
  });

  /// Обновить тикет
  Future<Ticket> updateTicket(
    String id, {
    String? cleaningAreaId,
    String? contractorId,
    String? contractId,
    DateTime? plannedStartAt,
    DateTime? plannedEndAt,
    String? description,
    TicketStatus? status,
  });

  /// Изменить статус тикета
  Future<Ticket> updateTicketStatus(
    String id, {
    required TicketStatus status,
  });

  // ==================== Ticket Assignments ====================

  /// Получить назначения тикета
  Future<List<TicketAssignment>> getTicketAssignments(String ticketId);

  /// Создать назначение
  Future<TicketAssignment> createTicketAssignment(
    String ticketId, {
    String? driverId,
    String? vehicleId,
  });

  /// Удалить назначение
  Future<void> deleteTicketAssignment(String ticketId, String assignmentId);

  // ==================== Driver Assignments ====================

  /// Установить статус назначения IN_WORK (для водителя)
  Future<TicketAssignment> markAssignmentInWork(String assignmentId);

  /// Установить статус назначения COMPLETED (для водителя)
  Future<TicketAssignment> markAssignmentCompleted(String assignmentId);

  // ==================== Driver Appeals ====================

  /// Создать апелляцию водителя
  Future<Map<String, dynamic>> createDriverAppeal({
    required String tripId,
    required String appealReasonType, // ERROR_CAMERA, TRANSIT_PATH, WRONG_ASSIGNMENT, OTHER
    required String comment,
  });

  /// Получить список апелляций водителя
  Future<List<Map<String, dynamic>>> getDriverAppeals({
    String? ticketId,
  });

  /// Получить детали апелляции водителя
  Future<Map<String, dynamic>> getDriverAppeal(String appealId);

  /// Добавить комментарий к апелляции водителя
  Future<Map<String, dynamic>> addDriverAppealComment({
    required String appealId,
    required String comment,
  });

  /// Получить комментарии к апелляции водителя
  Future<List<Map<String, dynamic>>> getDriverAppealComments(String appealId);

  // ==================== Landfill Reception Journal ====================

  /// Получить журнал приёма снега для LANDFILL
  Future<Map<String, dynamic>> getLandfillReceptionJournal({
    String? polygonId,
    String? contractorId,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? status,
  });

  // ==================== Driver Locations ====================

  /// Отправить текущую GPS-локацию водителя
  Future<void> sendDriverLocation({
    required double lat,
    required double lon,
    double? accuracy,
  });

  /// Получить локации водителей
  Future<Map<String, dynamic>> getDriversLocations();
}
