// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'polygon_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PolygonDto _$PolygonDtoFromJson(Map<String, dynamic> json) => PolygonDto(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String?,
      description: json['description'] as String?,
      geometryJson: json['geometry'] as String,
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$PolygonDtoToJson(PolygonDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'address': instance.address,
      'description': instance.description,
      'geometry': instance.geometryJson,
      'is_active': instance.isActive,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
