import 'package:equatable/equatable.dart';

enum TripStatus {
  ok, // OK - рейс валиден
  routeViolation, // ROUTE_VIOLATION - нарушение маршрута
  mismatchPlate, // MISMATCH_PLATE - несовпадение номера
  noAssignment, // NO_ASSIGNMENT - нет назначения
  suspiciousVolume, // SUSPICIOUS_VOLUME - подозрительный объем
}

class Trip extends Equatable {
  final String id;
  final String? ticketId; // FK → ticket.id (может быть NULL для NO_ASSIGNMENT)
  final String? driverId; // FK → driver.id
  final String? vehicleId; // FK → vehicle.id
  final String? polygonId; // FK → polygon.id
  final DateTime? entryTime; // Время въезда
  final DateTime? exitTime; // Время выезда
  final String? entryLprEventId; // FK → lpr_event.id (въезд)
  final String? exitLprEventId; // FK → lpr_event.id (выезд)
  final String? entryVolumeEventId; // FK → volume_event.id (въезд)
  final String? exitVolumeEventId; // FK → volume_event.id (выезд)
  final double? detectedVolumeEntry; // Объем на въезде (м³)
  final double? detectedVolumeExit; // Объем на выезде (м³)
  final TripStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Trip({
    required this.id,
    this.ticketId,
    this.driverId,
    this.vehicleId,
    this.polygonId,
    this.entryTime,
    this.exitTime,
    this.entryLprEventId,
    this.exitLprEventId,
    this.entryVolumeEventId,
    this.exitVolumeEventId,
    this.detectedVolumeEntry,
    this.detectedVolumeExit,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  Trip copyWith({
    String? id,
    Object? ticketId = _keepTicket,
    Object? driverId = _keepDriver,
    Object? vehicleId = _keepVehicle,
    Object? polygonId = _keepPolygon,
    Object? entryTime = _keepEntryTime,
    Object? exitTime = _keepExitTime,
    Object? entryLprEventId = _keepEntryLpr,
    Object? exitLprEventId = _keepExitLpr,
    Object? entryVolumeEventId = _keepEntryVolume,
    Object? exitVolumeEventId = _keepExitVolume,
    Object? detectedVolumeEntry = _keepVolumeEntry,
    Object? detectedVolumeExit = _keepVolumeExit,
    TripStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Trip(
      id: id ?? this.id,
      ticketId: ticketId == _keepTicket ? this.ticketId : ticketId as String?,
      driverId: driverId == _keepDriver ? this.driverId : driverId as String?,
      vehicleId: vehicleId == _keepVehicle ? this.vehicleId : vehicleId as String?,
      polygonId: polygonId == _keepPolygon ? this.polygonId : polygonId as String?,
      entryTime: entryTime == _keepEntryTime ? this.entryTime : entryTime as DateTime?,
      exitTime: exitTime == _keepExitTime ? this.exitTime : exitTime as DateTime?,
      entryLprEventId: entryLprEventId == _keepEntryLpr ? this.entryLprEventId : entryLprEventId as String?,
      exitLprEventId: exitLprEventId == _keepExitLpr ? this.exitLprEventId : exitLprEventId as String?,
      entryVolumeEventId: entryVolumeEventId == _keepEntryVolume ? this.entryVolumeEventId : entryVolumeEventId as String?,
      exitVolumeEventId: exitVolumeEventId == _keepExitVolume ? this.exitVolumeEventId : exitVolumeEventId as String?,
      detectedVolumeEntry: detectedVolumeEntry == _keepVolumeEntry ? this.detectedVolumeEntry : detectedVolumeEntry as double?,
      detectedVolumeExit: detectedVolumeExit == _keepVolumeExit ? this.detectedVolumeExit : detectedVolumeExit as double?,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static const _keepTicket = Object();
  static const _keepDriver = Object();
  static const _keepVehicle = Object();
  static const _keepPolygon = Object();
  static const _keepEntryTime = Object();
  static const _keepExitTime = Object();
  static const _keepEntryLpr = Object();
  static const _keepExitLpr = Object();
  static const _keepEntryVolume = Object();
  static const _keepExitVolume = Object();
  static const _keepVolumeEntry = Object();
  static const _keepVolumeExit = Object();

  @override
  List<Object?> get props => [
        id,
        ticketId,
        driverId,
        vehicleId,
        polygonId,
        entryTime,
        exitTime,
        entryLprEventId,
        exitLprEventId,
        entryVolumeEventId,
        exitVolumeEventId,
        detectedVolumeEntry,
        detectedVolumeExit,
        status,
        createdAt,
        updatedAt,
      ];
}

