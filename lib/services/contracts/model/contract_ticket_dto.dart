import 'package:json_annotation/json_annotation.dart';

part 'contract_ticket_dto.g.dart';

@JsonSerializable()
class ContractTicketDto {
  final String id;
  @JsonKey(name: 'cleaning_area_id')
  final String cleaningAreaId;
  @JsonKey(name: 'cleaning_area_name')
  final String cleaningAreaName;
  @JsonKey(name: 'planned_start_at')
  final DateTime plannedStartAt;
  @JsonKey(name: 'planned_end_at')
  final DateTime plannedEndAt;
  final String status;
  @JsonKey(name: 'trip_count')
  final int tripCount;
  @JsonKey(name: 'total_volume_m3')
  final double totalVolumeM3;
  @JsonKey(name: 'active_assignments')
  final int activeAssignments;

  ContractTicketDto({
    required this.id,
    required this.cleaningAreaId,
    required this.cleaningAreaName,
    required this.plannedStartAt,
    required this.plannedEndAt,
    required this.status,
    required this.tripCount,
    required this.totalVolumeM3,
    required this.activeAssignments,
  });

  factory ContractTicketDto.fromJson(Map<String, dynamic> json) =>
      _$ContractTicketDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ContractTicketDtoToJson(this);
}

