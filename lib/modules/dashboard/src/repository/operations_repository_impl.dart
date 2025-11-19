import 'package:akimat_project/modules/dashboard/src/model/areas/cleaning_area.dart';
import 'package:akimat_project/modules/dashboard/src/model/monitoring/vehicle_monitoring.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/user_role.dart';
import 'package:akimat_project/modules/dashboard/src/model/polygons/camera.dart';
import 'package:akimat_project/modules/dashboard/src/model/polygons/polygon.dart';
import 'package:akimat_project/modules/dashboard/src/model/tickets/ticket.dart';
import 'package:akimat_project/modules/dashboard/src/model/tickets/ticket_assignment.dart';
import 'package:akimat_project/modules/dashboard/src/repository/operations_repository.dart';
import 'package:akimat_project/services/operations/model/camera_dto.dart';
import 'package:akimat_project/services/operations/model/cleaning_area_dto.dart';
import 'package:akimat_project/services/operations/model/polygon_dto.dart';
import 'package:akimat_project/services/operations/model/ticket_dto.dart';
import 'package:akimat_project/services/operations/services.dart';
import 'package:akimat_project/services/tickets/services.dart';
import 'package:flutter/foundation.dart';

class OperationsRepositoryImpl implements OperationsRepository {
  OperationsRepositoryImpl({
    required OperationsServices services,
    TicketsServices? ticketsServices,
    UserRole? userRole,
  })  : _services = services,
        _ticketsServices = ticketsServices,
        _userRole = userRole;

  final OperationsServices _services;
  final TicketsServices? _ticketsServices;
  final UserRole? _userRole;

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

  // ==================== Monitoring ====================

  @override
  Future<List<VehicleMonitoring>> getVehiclesLive({
    double? minLat,
    double? minLon,
    double? maxLat,
    double? maxLon,
    String? contractorId,
  }) async {
    try {
      final data = await _services.collection.getVehiclesLive(
        minLat: minLat,
        minLon: minLon,
        maxLat: maxLat,
        maxLon: maxLon,
        contractorId: contractorId,
      );

      final vehiclesList = data['vehicles'] as List<dynamic>? ?? [];
      debugPrint('OperationsRepositoryImpl.getVehiclesLive: Parsing ${vehiclesList.length} vehicles');

      final vehicles = vehiclesList
          .map((v) {
            try {
              return VehicleMonitoring.fromJson(v as Map<String, dynamic>);
            } catch (e, stackTrace) {
              debugPrint('OperationsRepositoryImpl.getVehiclesLive: Error parsing vehicle: $e');
              debugPrint('OperationsRepositoryImpl.getVehiclesLive: Vehicle data: $v');
              debugPrint('OperationsRepositoryImpl.getVehiclesLive: Stack trace: $stackTrace');
              rethrow;
            }
          })
          .toList();

      debugPrint('OperationsRepositoryImpl.getVehiclesLive: Successfully parsed ${vehicles.length} vehicles');
      return vehicles;
    } catch (e, stackTrace) {
      debugPrint('OperationsRepositoryImpl.getVehiclesLive: Error: $e');
      debugPrint('OperationsRepositoryImpl.getVehiclesLive: Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<VehicleTrack> getVehicleTrack(
    String vehicleId, {
    DateTime? from,
    DateTime? to,
  }) async {
    final data = await _services.collection.getVehicleTrack(
      vehicleId,
      from: from,
      to: to,
    );

    return VehicleTrack.fromJson(data);
  }

  // ==================== Tickets ====================

  String? _ticketStatusToString(TicketStatus? status) {
    if (status == null) return null;
    return TicketDto.statusToString(status);
  }

  @override
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
  }) async {
    // Используем Ticket Service если доступен, иначе fallback на Operations Service
    if (_ticketsServices != null && _userRole != null) {
      final statusStr = _ticketStatusToString(status);
      
      switch (_userRole!) {
        case UserRole.akimatAdmin:
          final dtos = await _ticketsServices!.collection.getTicketsAkimat(
            status: statusStr,
            contractorId: contractorId,
            cleaningAreaId: cleaningAreaId,
            contractId: contractId,
            plannedStartFrom: plannedStartFrom,
            plannedStartTo: plannedStartTo,
            plannedEndFrom: plannedEndFrom,
            plannedEndTo: plannedEndTo,
            factStartFrom: factStartFrom,
            factStartTo: factStartTo,
            factEndFrom: factEndFrom,
            factEndTo: factEndTo,
          );
          return dtos.map((dto) => dto.toDomain()).toList();
          
        case UserRole.kguZkhAdmin:
          final dtos = await _ticketsServices!.collection.getTicketsKgu(
            status: statusStr,
            contractorId: contractorId,
            cleaningAreaId: cleaningAreaId,
            contractId: contractId,
            plannedStartFrom: plannedStartFrom,
            plannedStartTo: plannedStartTo,
            plannedEndFrom: plannedEndFrom,
            plannedEndTo: plannedEndTo,
          );
          return dtos.map((dto) => dto.toDomain()).toList();
          
        case UserRole.contractorAdmin:
          // Для подрядчика endpoint /contractor/tickets автоматически фильтрует по contractor_id из JWT токена
          // НЕ передаем contractorId в query параметрах, так как сервер сам определяет подрядчика из токена
          final dtos = await _ticketsServices!.collection.getTicketsContractor(
            status: statusStr,
            cleaningAreaId: cleaningAreaId,
            contractId: contractId,
            plannedStartFrom: plannedStartFrom,
            plannedStartTo: plannedStartTo,
            plannedEndFrom: plannedEndFrom,
            plannedEndTo: plannedEndTo,
          );
          // debugPrint('OperationsRepositoryImpl.loadTickets: Loaded ${dtos.length} tickets for contractor');
          return dtos.map((dto) => dto.toDomain()).toList();
          
        default:
          // Fallback на Operations Service для других ролей
          break;
      }
    }
    
    // Fallback на Operations Service
    final dtos = await _services.collection.getTickets(
      status: _ticketStatusToString(status),
      contractorId: contractorId,
      cleaningAreaId: cleaningAreaId,
      contractId: contractId,
      plannedStartFrom: plannedStartFrom,
      plannedStartTo: plannedStartTo,
      plannedEndFrom: plannedEndFrom,
      plannedEndTo: plannedEndTo,
      factStartFrom: factStartFrom,
      factStartTo: factStartTo,
      factEndFrom: factEndFrom,
      factEndTo: factEndTo,
      driverId: driverId,
    );
    return dtos.map((dto) => dto.toDomain()).toList();
  }

  @override
  Future<Ticket> getTicket(String id) async {
    final dto = await _services.collection.getTicket(id);
    return dto.toDomain();
  }

  @override
  Future<Ticket> createTicket({
    required String cleaningAreaId,
    required String contractorId,
    required String contractId,
    required DateTime plannedStartAt,
    required DateTime plannedEndAt,
    String? description,
    String? createdByOrgId,
  }) async {
    // Используем Ticket Service для KGU, иначе fallback на Operations Service
    if (_ticketsServices != null && _userRole == UserRole.kguZkhAdmin) {
      final dto = await _ticketsServices!.collection.createTicketKgu(
        cleaningAreaId: cleaningAreaId,
        contractorId: contractorId,
        contractId: contractId,
        plannedStartAt: plannedStartAt,
        plannedEndAt: plannedEndAt,
        description: description,
      );
      return dto.toDomain();
    }
    
    // Fallback на Operations Service
    final dto = await _services.collection.createTicket(
      cleaningAreaId: cleaningAreaId,
      contractorId: contractorId,
      contractId: contractId,
      plannedStartAt: plannedStartAt,
      plannedEndAt: plannedEndAt,
      description: description,
      createdByOrgId: createdByOrgId,
    );
    return dto.toDomain();
  }

  @override
  Future<Ticket> updateTicket(
    String id, {
    String? cleaningAreaId,
    String? contractorId,
    String? contractId,
    DateTime? plannedStartAt,
    DateTime? plannedEndAt,
    String? description,
    TicketStatus? status,
  }) async {
    final dto = await _services.collection.updateTicket(
      id,
      cleaningAreaId: cleaningAreaId,
      contractorId: contractorId,
      contractId: contractId,
      plannedStartAt: plannedStartAt,
      plannedEndAt: plannedEndAt,
      description: description,
      status: _ticketStatusToString(status),
    );
    return dto.toDomain();
  }

  @override
  Future<Ticket> updateTicketStatus(
    String id, {
    required TicketStatus status,
  }) async {
    final dto = await _services.collection.updateTicketStatus(
      id,
      status: TicketDto.statusToString(status),
    );
    return dto.toDomain();
  }

  // ==================== Ticket Assignments ====================

  @override
  Future<List<TicketAssignment>> getTicketAssignments(String ticketId) async {
    // Используем Ticket Service для назначений, если доступен
    if (_ticketsServices != null && _userRole != null) {
      switch (_userRole!) {
        case UserRole.contractorAdmin:
          final dtos = await _ticketsServices!.collection.getAssignmentsContractor(ticketId);
          return dtos.map((dto) => dto.toDomain()).toList();
        case UserRole.akimatAdmin:
        case UserRole.kguZkhAdmin:
          // Для Akimat и KGU ZKH можно использовать общий endpoint или contractor endpoint
          // Пока используем contractor endpoint, так как он доступен для всех
          try {
            final dtos = await _ticketsServices!.collection.getAssignmentsContractor(ticketId);
            return dtos.map((dto) => dto.toDomain()).toList();
          } catch (e) {
            debugPrint('OperationsRepositoryImpl.getTicketAssignments: Failed to get assignments from Ticket Service, falling back to Operations Service: $e');
            // Fallback на Operations Service
            break;
          }
        default:
          // Fallback на Operations Service для других ролей
          break;
      }
    }
    
    // Fallback на Operations Service
    final dtos = await _services.collection.getTicketAssignments(ticketId);
    return dtos.map((dto) => dto.toDomain()).toList();
  }

  @override
  Future<TicketAssignment> createTicketAssignment(
    String ticketId, {
    String? driverId,
    String? vehicleId,
  }) async {
    // Используем Ticket Service для назначений, если доступен и роль - подрядчик
    if (_ticketsServices != null && _userRole == UserRole.contractorAdmin) {
      if (driverId == null || vehicleId == null) {
        throw Exception('driverId and vehicleId are required for contractor assignments');
      }
      final dto = await _ticketsServices!.collection.createAssignmentContractor(
        ticketId,
        driverId: driverId,
        vehicleId: vehicleId,
      );
      return dto.toDomain();
    }
    
    // Fallback на Operations Service
    final dto = await _services.collection.createTicketAssignment(
      ticketId,
      driverId: driverId,
      vehicleId: vehicleId,
    );
    return dto.toDomain();
  }

  @override
  Future<void> deleteTicketAssignment(String ticketId, String assignmentId) async {
    // Используем Ticket Service для назначений, если доступен и роль - подрядчик
    if (_ticketsServices != null && _userRole == UserRole.contractorAdmin) {
      await _ticketsServices!.collection.deleteAssignmentContractor(assignmentId);
      return;
    }
    
    // Fallback на Operations Service
    await _services.collection.deleteTicketAssignment(ticketId, assignmentId);
  }
}

