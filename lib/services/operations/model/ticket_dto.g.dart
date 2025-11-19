// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticket_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TicketDto _$TicketDtoFromJson(Map<String, dynamic> json) => TicketDto(
      id: json['id'] as String,
      cleaningAreaId: json['cleaning_area_id'] as String,
      contractorId: json['contractor_id'] as String,
      contractId: json['contract_id'] as String,
      plannedStartAt: DateTime.parse(json['planned_start_at'] as String),
      plannedEndAt: DateTime.parse(json['planned_end_at'] as String),
      factStartAt: json['fact_start_at'] == null
          ? null
          : DateTime.parse(json['fact_start_at'] as String),
      factEndAt: json['fact_end_at'] == null
          ? null
          : DateTime.parse(json['fact_end_at'] as String),
      description: json['description'] as String?,
      status: json['status'] as String,
      tripsCount: (json['trips_count'] as num?)?.toInt(),
      volumeShippedM3: (json['volume_shipped_m3'] as num?)?.toDouble(),
      hasViolations: json['has_violations'] as bool? ?? false,
      createdByOrgId: json['created_by_org_id'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$TicketDtoToJson(TicketDto instance) => <String, dynamic>{
      'id': instance.id,
      'cleaning_area_id': instance.cleaningAreaId,
      'contractor_id': instance.contractorId,
      'contract_id': instance.contractId,
      'planned_start_at': instance.plannedStartAt.toIso8601String(),
      'planned_end_at': instance.plannedEndAt.toIso8601String(),
      'fact_start_at': instance.factStartAt?.toIso8601String(),
      'fact_end_at': instance.factEndAt?.toIso8601String(),
      'description': instance.description,
      'status': instance.status,
      'trips_count': instance.tripsCount,
      'volume_shipped_m3': instance.volumeShippedM3,
      'has_violations': instance.hasViolations,
      'created_by_org_id': instance.createdByOrgId,
      'is_active': instance.isActive,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
