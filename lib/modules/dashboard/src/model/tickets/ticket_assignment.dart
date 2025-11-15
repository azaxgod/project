import 'package:equatable/equatable.dart';

class TicketAssignment extends Equatable {
  final String id;
  final String ticketId; // FK → ticket.id
  final String? driverId; // FK → driver.id (опционально)
  final String? vehicleId; // FK → vehicle.id (опционально)
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TicketAssignment({
    required this.id,
    required this.ticketId,
    this.driverId,
    this.vehicleId,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  TicketAssignment copyWith({
    String? id,
    String? ticketId,
    Object? driverId = _keepDriver,
    Object? vehicleId = _keepVehicle,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TicketAssignment(
      id: id ?? this.id,
      ticketId: ticketId ?? this.ticketId,
      driverId: driverId == _keepDriver ? this.driverId : driverId as String?,
      vehicleId: vehicleId == _keepVehicle ? this.vehicleId : vehicleId as String?,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static const _keepDriver = Object();
  static const _keepVehicle = Object();

  @override
  List<Object?> get props => [
        id,
        ticketId,
        driverId,
        vehicleId,
        isActive,
        createdAt,
        updatedAt,
      ];
}

