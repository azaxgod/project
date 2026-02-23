import 'package:equatable/equatable.dart';

enum AssignmentStatus {
  notStarted, // NOT_STARTED - назначение создано, водитель еще не начал работу
  inWork, // IN_WORK - водитель начал работу
  completed, // COMPLETED - водитель завершил работу
}

class TicketAssignment extends Equatable {
  final String id;
  final String ticketId; // FK → ticket.id
  final String? driverId; // FK → driver.id (опционально)
  final String? vehicleId; // FK → vehicle.id (опционально)
  final AssignmentStatus? assignmentStatus; // Статус назначения (NOT_STARTED, IN_WORK, COMPLETED)
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TicketAssignment({
    required this.id,
    required this.ticketId,
    this.driverId,
    this.vehicleId,
    this.assignmentStatus,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  TicketAssignment copyWith({
    String? id,
    String? ticketId,
    Object? driverId = _keepDriver,
    Object? vehicleId = _keepVehicle,
    Object? assignmentStatus = _keepStatus,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TicketAssignment(
      id: id ?? this.id,
      ticketId: ticketId ?? this.ticketId,
      driverId: driverId == _keepDriver ? this.driverId : driverId as String?,
      vehicleId: vehicleId == _keepVehicle ? this.vehicleId : vehicleId as String?,
      assignmentStatus: assignmentStatus == _keepStatus ? this.assignmentStatus : assignmentStatus as AssignmentStatus?,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static const _keepDriver = Object();
  static const _keepVehicle = Object();
  static const _keepStatus = Object();

  @override
  List<Object?> get props => [
        id,
        ticketId,
        driverId,
        vehicleId,
        assignmentStatus,
        isActive,
        createdAt,
        updatedAt,
      ];
}

