// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cleaning_area_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CleaningAreaDto _$CleaningAreaDtoFromJson(Map<String, dynamic> json) =>
    CleaningAreaDto(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      geometryJson: json['geometry'] as String,
      city: json['city'] as String?,
      status: json['status'] as String,
      defaultContractorId: json['default_contractor_id'] as String?,
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$CleaningAreaDtoToJson(CleaningAreaDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'geometry': instance.geometryJson,
      'city': instance.city,
      'status': instance.status,
      'default_contractor_id': instance.defaultContractorId,
      'is_active': instance.isActive,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
