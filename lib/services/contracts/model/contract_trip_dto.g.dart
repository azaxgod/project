// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contract_trip_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContractTripDto _$ContractTripDtoFromJson(Map<String, dynamic> json) =>
    ContractTripDto(
      id: json['id'] as String,
      ticketId: json['ticket_id'] as String,
      driverId: json['driver_id'] as String?,
      vehicleId: json['vehicle_id'] as String?,
      entryAt: json['entry_at'] == null
          ? null
          : DateTime.parse(json['entry_at'] as String),
      exitAt: json['exit_at'] == null
          ? null
          : DateTime.parse(json['exit_at'] as String),
      status: json['status'] as String,
      detectedVolumeEntry: (json['detected_volume_entry'] as num?)?.toDouble(),
      detectedVolumeExit: (json['detected_volume_exit'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$ContractTripDtoToJson(ContractTripDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'ticket_id': instance.ticketId,
      'driver_id': instance.driverId,
      'vehicle_id': instance.vehicleId,
      'entry_at': instance.entryAt?.toIso8601String(),
      'exit_at': instance.exitAt?.toIso8601String(),
      'status': instance.status,
      'detected_volume_entry': instance.detectedVolumeEntry,
      'detected_volume_exit': instance.detectedVolumeExit,
    };
