import 'package:equatable/equatable.dart';

/// Модель события распознавания номера от ANPR камеры
class AnprEvent extends Equatable {
  final String id;
  final String? plateId;
  final String cameraId;
  final String? cameraModel;
  final String normalizedPlate;
  final String rawPlate;
  final DateTime eventTime;
  final double? confidence;
  final String? direction; // "enter" or "exit"
  final int? lane;
  final VehicleInfo? vehicle;
  final List<String> photos; // URLs фотографий

  const AnprEvent({
    required this.id,
    this.plateId,
    required this.cameraId,
    this.cameraModel,
    required this.normalizedPlate,
    required this.rawPlate,
    required this.eventTime,
    this.confidence,
    this.direction,
    this.lane,
    this.vehicle,
    this.photos = const [],
  });

  factory AnprEvent.fromJson(Map<String, dynamic> json) {
    return AnprEvent(
      id: json['id'] as String,
      plateId: json['plate_id'] as String?,
      cameraId: json['camera_id'] as String,
      cameraModel: json['camera_model'] as String?,
      normalizedPlate: json['normalized_plate'] as String,
      rawPlate: json['raw_plate'] as String,
      eventTime: DateTime.parse(json['event_time'] as String),
      confidence: (json['confidence'] as num?)?.toDouble(),
      direction: json['direction'] as String?,
      lane: json['lane'] as int?,
      vehicle: json['vehicle'] != null
          ? VehicleInfo.fromJson(json['vehicle'] as Map<String, dynamic>)
          : null,
      photos: (json['photos'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (plateId != null) 'plate_id': plateId,
      'camera_id': cameraId,
      if (cameraModel != null) 'camera_model': cameraModel,
      'normalized_plate': normalizedPlate,
      'raw_plate': rawPlate,
      'event_time': eventTime.toIso8601String(),
      if (confidence != null) 'confidence': confidence,
      if (direction != null) 'direction': direction,
      if (lane != null) 'lane': lane,
      if (vehicle != null) 'vehicle': vehicle!.toJson(),
      'photos': photos,
    };
  }

  @override
  List<Object?> get props => [
        id,
        plateId,
        cameraId,
        cameraModel,
        normalizedPlate,
        rawPlate,
        eventTime,
        confidence,
        direction,
        lane,
        vehicle,
        photos,
      ];
}

/// Информация о транспортном средстве
class VehicleInfo extends Equatable {
  final String? color;
  final String? type; // "car", "truck", etc.
  final String? brand;
  final String? model;

  const VehicleInfo({
    this.color,
    this.type,
    this.brand,
    this.model,
  });

  factory VehicleInfo.fromJson(Map<String, dynamic> json) {
    return VehicleInfo(
      color: json['color'] as String?,
      type: json['type'] as String?,
      brand: json['brand'] as String?,
      model: json['model'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (color != null) 'color': color,
      if (type != null) 'type': type,
      if (brand != null) 'brand': brand,
      if (model != null) 'model': model,
    };
  }

  @override
  List<Object?> get props => [color, type, brand, model];
}

/// Ответ на создание события
class AnprEventResponse extends Equatable {
  final String status;
  final String eventId;
  final String? plateId;
  final String plate;
  final bool vehicleExists;
  final List<String> hits; // whitelist/blacklist hits
  final List<String> photos;

  const AnprEventResponse({
    required this.status,
    required this.eventId,
    this.plateId,
    required this.plate,
    required this.vehicleExists,
    this.hits = const [],
    this.photos = const [],
  });

  factory AnprEventResponse.fromJson(Map<String, dynamic> json) {
    return AnprEventResponse(
      status: json['status'] as String,
      eventId: json['event_id'] as String,
      plateId: json['plate_id'] as String?,
      plate: json['plate'] as String,
      vehicleExists: json['vehicle_exists'] as bool? ?? false,
      hits: (json['hits'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      photos: (json['photos'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [
        status,
        eventId,
        plateId,
        plate,
        vehicleExists,
        hits,
        photos,
      ];
}

/// Запрос на создание события
class AnprEventRequest extends Equatable {
  final String cameraId;
  final String? cameraModel;
  final String plate;
  final double? confidence;
  final String? direction;
  final int? lane;
  final DateTime? eventTime;
  final VehicleInfo? vehicle;
  final String? snapshotUrl;

  const AnprEventRequest({
    required this.cameraId,
    this.cameraModel,
    required this.plate,
    this.confidence,
    this.direction,
    this.lane,
    this.eventTime,
    this.vehicle,
    this.snapshotUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'camera_id': cameraId,
      if (cameraModel != null) 'camera_model': cameraModel,
      'plate': plate,
      if (confidence != null) 'confidence': confidence,
      if (direction != null) 'direction': direction,
      if (lane != null) 'lane': lane,
      if (eventTime != null) 'event_time': eventTime!.toIso8601String(),
      if (vehicle != null) 'vehicle': vehicle!.toJson(),
      if (snapshotUrl != null) 'snapshot_url': snapshotUrl,
    };
  }

  @override
  List<Object?> get props => [
        cameraId,
        cameraModel,
        plate,
        confidence,
        direction,
        lane,
        eventTime,
        vehicle,
        snapshotUrl,
      ];
}

