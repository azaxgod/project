import 'package:equatable/equatable.dart';

/// Модель события в отчете ANPR
class AnprReportEvent extends Equatable {
  final String id;
  final DateTime eventTime;
  final String plateNumber;
  final String rawPlate;
  final String? vehicleBrand;
  final String? vehicleModel;
  final String? contractorId;
  final String? contractorName;
  final String? polygonId;
  final double? snowVolumeM3;
  final String? platePhotoUrl;
  final String? bodyPhotoUrl;
  final String? vehicleId;

  const AnprReportEvent({
    required this.id,
    required this.eventTime,
    required this.plateNumber,
    required this.rawPlate,
    this.vehicleBrand,
    this.vehicleModel,
    this.contractorId,
    this.contractorName,
    this.polygonId,
    this.snowVolumeM3,
    this.platePhotoUrl,
    this.bodyPhotoUrl,
    this.vehicleId,
  });

  factory AnprReportEvent.fromJson(Map<String, dynamic> json) {
    return AnprReportEvent(
      id: json['id'] as String,
      eventTime: DateTime.parse(json['event_time'] as String),
      plateNumber: json['plate_number'] as String,
      rawPlate: json['raw_plate'] as String,
      vehicleBrand: json['vehicle_brand'] as String?,
      vehicleModel: json['vehicle_model'] as String?,
      contractorId: json['contractor_id'] as String?,
      contractorName: json['contractor_name'] as String?,
      polygonId: json['polygon_id'] as String?,
      snowVolumeM3: (json['snow_volume_m3'] as num?)?.toDouble(),
      platePhotoUrl: json['plate_photo_url'] as String?,
      bodyPhotoUrl: json['body_photo_url'] as String?,
      vehicleId: json['vehicle_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_time': eventTime.toIso8601String(),
      'plate_number': plateNumber,
      'raw_plate': rawPlate,
      if (vehicleBrand != null) 'vehicle_brand': vehicleBrand,
      if (vehicleModel != null) 'vehicle_model': vehicleModel,
      if (contractorId != null) 'contractor_id': contractorId,
      if (contractorName != null) 'contractor_name': contractorName,
      if (polygonId != null) 'polygon_id': polygonId,
      if (snowVolumeM3 != null) 'snow_volume_m3': snowVolumeM3,
      if (platePhotoUrl != null) 'plate_photo_url': platePhotoUrl,
      if (bodyPhotoUrl != null) 'body_photo_url': bodyPhotoUrl,
      if (vehicleId != null) 'vehicle_id': vehicleId,
    };
  }

  @override
  List<Object?> get props => [
        id,
        eventTime,
        plateNumber,
        rawPlate,
        vehicleBrand,
        vehicleModel,
        contractorId,
        contractorName,
        polygonId,
        snowVolumeM3,
        platePhotoUrl,
        bodyPhotoUrl,
        vehicleId,
      ];
}

/// Данные отчета ANPR
class AnprReportData extends Equatable {
  final double totalVolume;
  final int tripCount;
  final List<AnprReportEvent> events;

  const AnprReportData({
    required this.totalVolume,
    required this.tripCount,
    required this.events,
  });

  factory AnprReportData.fromJson(Map<String, dynamic> json) {
    return AnprReportData(
      totalVolume: (json['total_volume'] as num).toDouble(),
      tripCount: json['trip_count'] as int,
      events: (json['events'] as List<dynamic>)
          .map((e) => AnprReportEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_volume': totalVolume,
      'trip_count': tripCount,
      'events': events.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [totalVolume, tripCount, events];
}

/// Ответ на запрос отчета ANPR
class AnprReportResponse extends Equatable {
  final AnprReportData data;

  const AnprReportResponse({required this.data});

  factory AnprReportResponse.fromJson(Map<String, dynamic> json) {
    return AnprReportResponse(
      data: AnprReportData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data.toJson(),
    };
  }

  @override
  List<Object?> get props => [data];
}

