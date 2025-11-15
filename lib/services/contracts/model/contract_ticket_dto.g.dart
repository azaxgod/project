// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contract_ticket_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContractTicketDto _$ContractTicketDtoFromJson(Map<String, dynamic> json) =>
    ContractTicketDto(
      id: json['id'] as String,
      cleaningAreaId: json['cleaning_area_id'] as String,
      cleaningAreaName: json['cleaning_area_name'] as String,
      plannedStartAt: DateTime.parse(json['planned_start_at'] as String),
      plannedEndAt: DateTime.parse(json['planned_end_at'] as String),
      status: json['status'] as String,
      tripCount: (json['trip_count'] as num).toInt(),
      totalVolumeM3: (json['total_volume_m3'] as num).toDouble(),
      activeAssignments: (json['active_assignments'] as num).toInt(),
    );

Map<String, dynamic> _$ContractTicketDtoToJson(ContractTicketDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'cleaning_area_id': instance.cleaningAreaId,
      'cleaning_area_name': instance.cleaningAreaName,
      'planned_start_at': instance.plannedStartAt.toIso8601String(),
      'planned_end_at': instance.plannedEndAt.toIso8601String(),
      'status': instance.status,
      'trip_count': instance.tripCount,
      'total_volume_m3': instance.totalVolumeM3,
      'active_assignments': instance.activeAssignments,
    };
