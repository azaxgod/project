import 'package:json_annotation/json_annotation.dart';

part 'cleaning_area_access_dto.g.dart';

@JsonSerializable()
class CleaningAreaAccessDto {
  final String id;
  @JsonKey(name: 'cleaning_area_id')
  final String cleaningAreaId;
  @JsonKey(name: 'contractor_id')
  final String contractorId;
  final String source; // "TICKETS", "MANUAL", etc.
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  CleaningAreaAccessDto({
    required this.id,
    required this.cleaningAreaId,
    required this.contractorId,
    required this.source,
    required this.isActive,
    required this.createdAt,
  });

  factory CleaningAreaAccessDto.fromJson(Map<String, dynamic> json) =>
      _$CleaningAreaAccessDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CleaningAreaAccessDtoToJson(this);
}

