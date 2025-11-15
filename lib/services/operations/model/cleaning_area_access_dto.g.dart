// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cleaning_area_access_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CleaningAreaAccessDto _$CleaningAreaAccessDtoFromJson(
        Map<String, dynamic> json) =>
    CleaningAreaAccessDto(
      id: json['id'] as String,
      cleaningAreaId: json['cleaning_area_id'] as String,
      contractorId: json['contractor_id'] as String,
      source: json['source'] as String,
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$CleaningAreaAccessDtoToJson(
        CleaningAreaAccessDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'cleaning_area_id': instance.cleaningAreaId,
      'contractor_id': instance.contractorId,
      'source': instance.source,
      'is_active': instance.isActive,
      'created_at': instance.createdAt.toIso8601String(),
    };
