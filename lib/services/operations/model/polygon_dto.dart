import 'dart:convert';

import 'package:akimat_project/modules/dashboard/src/model/polygons/polygon.dart';
import 'package:json_annotation/json_annotation.dart';

part 'polygon_dto.g.dart';

@JsonSerializable()
class PolygonDto {
  final String id;
  final String name;
  final String? address;
  final String? description;
  @JsonKey(name: 'geometry')
  final String geometryJson; // GeoJSON as string
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  PolygonDto({
    required this.id,
    required this.name,
    this.address,
    this.description,
    required this.geometryJson,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  factory PolygonDto.fromJson(Map<String, dynamic> json) =>
      _$PolygonDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PolygonDtoToJson(this);

  Polygon toDomain() {
    return Polygon(
      id: id,
      name: name,
      address: address,
      description: description,
      geometry: _parseGeometry(geometryJson),
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? createdAt,
    );
  }

  /// Парсит GeoJSON строку в координаты полигона
  List<List<double>> _parseGeometry(String geometryJson) {
    try {
      final geoJson = jsonDecode(geometryJson) as Map<String, dynamic>;
      final type = geoJson['type'] as String;
      final coordinates = geoJson['coordinates'] as dynamic;

      if (type == 'Polygon' && coordinates is List) {
        // Polygon coordinates: [[[lng, lat], [lng, lat], ...]]
        final outerRing = coordinates[0] as List;
        return outerRing
            .map((coord) => [
                  (coord[0] as num).toDouble(), // longitude
                  (coord[1] as num).toDouble(), // latitude
                ])
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Преобразует координаты в GeoJSON строку
  static String geometryToJson(List<List<double>> coordinates) {
    final geoJson = {
      'type': 'Polygon',
      'coordinates': [
        coordinates.map((coord) => [coord[0], coord[1]]).toList(),
      ],
    };
    return jsonEncode(geoJson);
  }
}

