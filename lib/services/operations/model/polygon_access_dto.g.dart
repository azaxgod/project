// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'polygon_access_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PolygonAccessDto _$PolygonAccessDtoFromJson(Map<String, dynamic> json) =>
    PolygonAccessDto(
      id: json['id'] as String,
      polygonId: json['polygon_id'] as String,
      contractorId: json['contractor_id'] as String,
      source: json['source'] as String,
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$PolygonAccessDtoToJson(PolygonAccessDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'polygon_id': instance.polygonId,
      'contractor_id': instance.contractorId,
      'source': instance.source,
      'is_active': instance.isActive,
      'created_at': instance.createdAt.toIso8601String(),
    };
