// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'camera_polygon_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CameraPolygonDto _$CameraPolygonDtoFromJson(Map<String, dynamic> json) =>
    CameraPolygonDto(
      camera: CameraDto.fromJson(json['camera'] as Map<String, dynamic>),
      polygon: PolygonDto.fromJson(json['polygon'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CameraPolygonDtoToJson(CameraPolygonDto instance) =>
    <String, dynamic>{
      'camera': instance.camera,
      'polygon': instance.polygon,
    };
