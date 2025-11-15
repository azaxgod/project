// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'camera_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CameraDto _$CameraDtoFromJson(Map<String, dynamic> json) => CameraDto(
      id: json['id'] as String,
      polygonId: json['polygon_id'] as String,
      type: json['type'] as String,
      name: json['name'] as String,
      locationJson: json['location'] as String?,
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$CameraDtoToJson(CameraDto instance) => <String, dynamic>{
      'id': instance.id,
      'polygon_id': instance.polygonId,
      'type': instance.type,
      'name': instance.name,
      'location': instance.locationJson,
      'is_active': instance.isActive,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
