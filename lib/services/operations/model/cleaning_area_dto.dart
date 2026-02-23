import 'dart:convert';

import 'package:akimat_project/modules/dashboard/src/model/areas/cleaning_area.dart';
import 'package:json_annotation/json_annotation.dart';

part 'cleaning_area_dto.g.dart';

@JsonSerializable()
class CleaningAreaDto {
  final String id;
  final String name;
  final String? description;
  @JsonKey(name: 'geometry')
  final String geometryJson; // GeoJSON as string
  final String? city;
  final String status; // "ACTIVE" or "INACTIVE"
  @JsonKey(name: 'default_contractor_id')
  final String? defaultContractorId;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  CleaningAreaDto({
    required this.id,
    required this.name,
    this.description,
    required this.geometryJson,
    this.city,
    required this.status,
    this.defaultContractorId,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  factory CleaningAreaDto.fromJson(Map<String, dynamic> json) =>
      _$CleaningAreaDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CleaningAreaDtoToJson(this);

  CleaningArea toDomain() {
    return CleaningArea(
      id: id,
      name: name,
      description: description,
      geometry: _parseGeometry(geometryJson),
      city: city ?? 'Петропавловск',
      status: _parseStatus(status),
      defaultContractorId: defaultContractorId,
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

  CleaningAreaStatus _parseStatus(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return CleaningAreaStatus.active;
      case 'INACTIVE':
        return CleaningAreaStatus.inactive;
      default:
        return CleaningAreaStatus.inactive;
    }
  }

  static String statusToString(CleaningAreaStatus status) {
    switch (status) {
      case CleaningAreaStatus.active:
        return 'ACTIVE';
      case CleaningAreaStatus.inactive:
        return 'INACTIVE';
    }
  }
}

