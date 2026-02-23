import 'package:json_annotation/json_annotation.dart';

part 'polygon_access_dto.g.dart';

@JsonSerializable()
class PolygonAccessDto {
  final String id;
  @JsonKey(name: 'polygon_id')
  final String polygonId;
  @JsonKey(name: 'contractor_id')
  final String contractorId;
  final String source; // "TICKETS", "MANUAL", etc.
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  PolygonAccessDto({
    required this.id,
    required this.polygonId,
    required this.contractorId,
    required this.source,
    required this.isActive,
    required this.createdAt,
  });

  factory PolygonAccessDto.fromJson(Map<String, dynamic> json) =>
      _$PolygonAccessDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PolygonAccessDtoToJson(this);
}

