import 'dart:convert';

import 'package:akimat_project/modules/dashboard/src/model/polygons/camera.dart';
import 'package:json_annotation/json_annotation.dart';

part 'camera_dto.g.dart';

@JsonSerializable()
class CameraDto {
  final String id;
  @JsonKey(name: 'polygon_id')
  final String polygonId;
  final String type; // "LPR" or "VOLUME"
  final String name;
  @JsonKey(name: 'location')
  final String? locationJson; // GeoJSON Point as string
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  CameraDto({
    required this.id,
    required this.polygonId,
    required this.type,
    required this.name,
    this.locationJson,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  factory CameraDto.fromJson(Map<String, dynamic> json) =>
      _$CameraDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CameraDtoToJson(this);

  Camera toDomain() {
    return Camera(
      id: id,
      polygonId: polygonId,
      type: _parseType(type),
      name: name,
      location: _parseLocation(locationJson),
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? createdAt,
    );
  }

  /// Парсит GeoJSON Point строку в координаты [longitude, latitude]
  List<double>? _parseLocation(String? locationJson) {
    if (locationJson == null || locationJson.isEmpty) return null;
    try {
      final geoJson = jsonDecode(locationJson) as Map<String, dynamic>;
      final type = geoJson['type'] as String;
      final coordinates = geoJson['coordinates'] as List;

      if (type == 'Point' && coordinates.length >= 2) {
        return [
          (coordinates[0] as num).toDouble(), // longitude
          (coordinates[1] as num).toDouble(), // latitude
        ];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Преобразует координаты в GeoJSON Point строку
  static String? locationToJson(List<double>? location) {
    if (location == null || location.length < 2) return null;
    final geoJson = {
      'type': 'Point',
      'coordinates': [location[0], location[1]],
    };
    return jsonEncode(geoJson);
  }

  CameraType _parseType(String type) {
    switch (type.toUpperCase()) {
      case 'LPR':
        return CameraType.lpr;
      case 'VOLUME':
        return CameraType.volume;
      default:
        return CameraType.lpr;
    }
  }

  static String typeToString(CameraType type) {
    switch (type) {
      case CameraType.lpr:
        return 'LPR';
      case CameraType.volume:
        return 'VOLUME';
    }
  }
}

