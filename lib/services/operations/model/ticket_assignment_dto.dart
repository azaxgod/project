import 'package:akimat_project/modules/dashboard/src/model/tickets/ticket_assignment.dart';
import 'package:json_annotation/json_annotation.dart';

part 'ticket_assignment_dto.g.dart';

@JsonSerializable()
class TicketAssignmentDto {
  @JsonKey(name: 'id')
  final String id;

  @JsonKey(name: 'ticket_id')
  final String ticketId;

  @JsonKey(name: 'driver_id')
  final String? driverId;

  @JsonKey(name: 'vehicle_id')
  final String? vehicleId;

  @JsonKey(name: 'assignment_status')
  final String? assignmentStatus;

  @JsonKey(name: 'driver_mark_status')
  final String? driverMarkStatus;

  @JsonKey(name: 'is_active')
  final bool isActive;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  TicketAssignmentDto({
    required this.id,
    required this.ticketId,
    this.driverId,
    this.vehicleId,
    this.assignmentStatus,
    this.driverMarkStatus,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TicketAssignmentDto.fromJson(Map<String, dynamic> json) =>
      _$TicketAssignmentDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TicketAssignmentDtoToJson(this);

  AssignmentStatus? _parseAssignmentStatus(String? status) {
    if (status == null) return null;
    switch (status.toUpperCase()) {
      case 'NOT_STARTED':
        return AssignmentStatus.notStarted;
      case 'IN_WORK':
        return AssignmentStatus.inWork;
      case 'COMPLETED':
        return AssignmentStatus.completed;
      default:
        return null;
    }
  }

  TicketAssignment toDomain() {
    // Используем driver_mark_status, если assignment_status не задан
    // Это нужно для совместимости с API, где используется driver_mark_status
    final status = assignmentStatus ?? driverMarkStatus;
    return TicketAssignment(
      id: id,
      ticketId: ticketId,
      driverId: driverId,
      vehicleId: vehicleId,
      assignmentStatus: _parseAssignmentStatus(status),
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}






