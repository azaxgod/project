import 'package:json_annotation/json_annotation.dart';

part 'contract_trip_dto.g.dart';

@JsonSerializable()
class ContractTripDto {
  final String id;
  @JsonKey(name: 'ticket_id')
  final String ticketId;
  @JsonKey(name: 'driver_id')
  final String? driverId;
  @JsonKey(name: 'vehicle_id')
  final String? vehicleId;
  @JsonKey(name: 'entry_at')
  final DateTime? entryAt;
  @JsonKey(name: 'exit_at')
  final DateTime? exitAt;
  final String status;
  @JsonKey(name: 'detected_volume_entry')
  final double? detectedVolumeEntry;
  @JsonKey(name: 'detected_volume_exit')
  final double? detectedVolumeExit;

  ContractTripDto({
    required this.id,
    required this.ticketId,
    this.driverId,
    this.vehicleId,
    this.entryAt,
    this.exitAt,
    required this.status,
    this.detectedVolumeEntry,
    this.detectedVolumeExit,
  });

  factory ContractTripDto.fromJson(Map<String, dynamic> json) =>
      _$ContractTripDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ContractTripDtoToJson(this);
}

