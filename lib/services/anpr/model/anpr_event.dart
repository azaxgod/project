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
  final double? snowVolumeM3; // Объем снега в м³
  final String? polygonId; // ID полигона
  final double? bodyVolumeM3; // Объем кузова в м³
  // Поля водителя (из vehicles через номер)
  final String? driverId;
  final String? driverFullName;
  final String? driverIin;
  final String? driverPhone;
  // Поля подрядчика (из vehicles через номер)
  final String? contractorId;
  final String? contractorName;
  final String? contractorBin;

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
    this.snowVolumeM3,
    this.polygonId,
    this.bodyVolumeM3,
    this.driverId,
    this.driverFullName,
    this.driverIin,
    this.driverPhone,
    this.contractorId,
    this.contractorName,
    this.contractorBin,
  });

  /// Вычисляет объем снега: confidence * body_volume_m3
  /// Если расчет невозможен, возвращает готовый snow_volume_m3 из API
  double? get calculatedSnowVolume {
    // Приоритет 1: Вычисляем из confidence * body_volume_m3
    if (confidence != null && bodyVolumeM3 != null && confidence! > 0 && bodyVolumeM3! > 0) {
      return confidence! * bodyVolumeM3!;
    }
    // Приоритет 2: Используем готовый объем из API
    if (snowVolumeM3 != null && snowVolumeM3! > 0) {
      return snowVolumeM3;
    }
    // Если есть только confidence, но нет body_volume_m3, возвращаем null
    // (нужно будет получать body_volume_m3 из другого источника)
    return null;
  }

  factory AnprEvent.fromJson(Map<String, dynamic> json) {
    // Парсим body_volume_m3 из разных возможных мест в ответе
    double? bodyVolumeM3;
    
    // Пробуем разные варианты названий полей
    if (json['body_volume_m3'] != null) {
      bodyVolumeM3 = (json['body_volume_m3'] as num).toDouble();
    } else if (json['vehicle_body_volume_m3'] != null) {
      bodyVolumeM3 = (json['vehicle_body_volume_m3'] as num).toDouble();
    } else if (json['bodyVolumeM3'] != null) {
      bodyVolumeM3 = (json['bodyVolumeM3'] as num).toDouble();
    } else if (json['BodyVolumeM3'] != null) {
      bodyVolumeM3 = (json['BodyVolumeM3'] as num).toDouble();
    } else if (json['vehicle'] != null && json['vehicle'] is Map) {
      final vehicle = json['vehicle'] as Map<String, dynamic>;
      if (vehicle['body_volume_m3'] != null) {
        bodyVolumeM3 = (vehicle['body_volume_m3'] as num).toDouble();
      } else if (vehicle['bodyVolumeM3'] != null) {
        bodyVolumeM3 = (vehicle['bodyVolumeM3'] as num).toDouble();
      } else if (vehicle['BodyVolumeM3'] != null) {
        bodyVolumeM3 = (vehicle['BodyVolumeM3'] as num).toDouble();
      }
    }
    
    // Парсим vehicle - может быть вложенным объектом или плоскими полями
    VehicleInfo? vehicle;
    if (json['vehicle'] != null && json['vehicle'] is Map) {
      vehicle = VehicleInfo.fromJson(json['vehicle'] as Map<String, dynamic>);
    } else if (json['vehicle_color'] != null || 
               json['vehicle_brand'] != null || 
               json['vehicle_type'] != null) {
      // Плоская структура из API (vehicle_color, vehicle_brand, etc.)
      vehicle = VehicleInfo(
        color: json['vehicle_color'] as String?,
        type: json['vehicle_type'] as String?,
        brand: json['vehicle_brand'] as String?,
        model: json['vehicle_model'] as String?,
        country: json['vehicle_country'] as String?,
        plateColor: json['vehicle_plate_color'] as String?,
        speed: (json['vehicle_speed'] as num?)?.toDouble(),
      );
    }
    
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
      vehicle: vehicle,
      photos: (json['photos'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      snowVolumeM3: (json['snow_volume_m3'] as num?)?.toDouble(),
      polygonId: json['polygon_id'] as String?,
      bodyVolumeM3: bodyVolumeM3,
      driverId: json['driver_id'] as String?,
      driverFullName: json['driver_full_name'] as String?,
      driverIin: json['driver_iin'] as String?,
      driverPhone: json['driver_phone'] as String?,
      contractorId: json['contractor_id'] as String?,
      contractorName: json['contractor_name'] as String?,
      contractorBin: json['contractor_bin'] as String?,
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
      if (snowVolumeM3 != null) 'snow_volume_m3': snowVolumeM3,
      if (polygonId != null) 'polygon_id': polygonId,
      if (bodyVolumeM3 != null) 'body_volume_m3': bodyVolumeM3,
      if (driverId != null) 'driver_id': driverId,
      if (driverFullName != null) 'driver_full_name': driverFullName,
      if (driverIin != null) 'driver_iin': driverIin,
      if (driverPhone != null) 'driver_phone': driverPhone,
      if (contractorId != null) 'contractor_id': contractorId,
      if (contractorName != null) 'contractor_name': contractorName,
      if (contractorBin != null) 'contractor_bin': contractorBin,
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
        snowVolumeM3,
        polygonId,
        bodyVolumeM3,
        driverId,
        driverFullName,
        driverIin,
        driverPhone,
        contractorId,
        contractorName,
        contractorBin,
      ];
}

/// Информация о транспортном средстве
class VehicleInfo extends Equatable {
  final String? color;
  final String? type; // "car", "truck", etc.
  final String? brand;
  final String? model;
  final String? country; // Страна регистрации (например, "KZ")
  final String? plateColor; // Цвет номерного знака
  final double? speed; // Скорость (км/ч)

  const VehicleInfo({
    this.color,
    this.type,
    this.brand,
    this.model,
    this.country,
    this.plateColor,
    this.speed,
  });

  factory VehicleInfo.fromJson(Map<String, dynamic> json) {
    return VehicleInfo(
      color: json['color'] as String?,
      type: json['type'] as String?,
      brand: json['brand'] as String?,
      model: json['model'] as String?,
      country: json['country'] as String?,
      plateColor: json['plate_color'] as String? ?? json['plateColor'] as String?,
      speed: (json['speed'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (color != null) 'color': color,
      if (type != null) 'type': type,
      if (brand != null) 'brand': brand,
      if (model != null) 'model': model,
      if (country != null) 'country': country,
      if (plateColor != null) 'plate_color': plateColor,
      if (speed != null) 'speed': speed,
    };
  }

  @override
  List<Object?> get props => [color, type, brand, model, country, plateColor, speed];
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
  // Поля для анализа объема снега
  final double? snowVolumePercentage; // Процент заполнения кузова снегом (0-100)
  final double? snowVolumeConfidence; // Уверенность определения объема снега (0.0-1.0)
  final bool? matchedSnow; // Обнаружен ли снег в кузове
  final Map<String, dynamic>? rawPayload; // Дополнительные поля для хранения

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
    this.snowVolumePercentage,
    this.snowVolumeConfidence,
    this.matchedSnow,
    this.rawPayload,
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
      if (snowVolumePercentage != null) 'snow_volume_percentage': snowVolumePercentage,
      if (snowVolumeConfidence != null) 'snow_volume_confidence': snowVolumeConfidence,
      if (matchedSnow != null) 'matched_snow': matchedSnow,
      if (rawPayload != null) 'raw_payload': rawPayload,
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
        snowVolumePercentage,
        snowVolumeConfidence,
        matchedSnow,
        rawPayload,
      ];
}



