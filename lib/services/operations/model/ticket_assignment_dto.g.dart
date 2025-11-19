// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticket_assignment_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TicketAssignmentDto _$TicketAssignmentDtoFromJson(Map<String, dynamic> json) =>
    TicketAssignmentDto(
      id: json['id'] as String,
      ticketId: json['ticket_id'] as String,
      driverId: json['driver_id'] as String?,
      vehicleId: json['vehicle_id'] as String?,
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$TicketAssignmentDtoToJson(
        TicketAssignmentDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'ticket_id': instance.ticketId,
      'driver_id': instance.driverId,
      'vehicle_id': instance.vehicleId,
      'is_active': instance.isActive,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
