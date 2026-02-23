import 'package:equatable/equatable.dart';

/// Локация водителя
class DriverLocation extends Equatable {
  final String driverId;
  final double lat;
  final double lon;
  final double? accuracy; // Точность в метрах
  final DateTime updatedAt;

  const DriverLocation({
    required this.driverId,
    required this.lat,
    required this.lon,
    this.accuracy,
    required this.updatedAt,
  });

  factory DriverLocation.fromJson(Map<String, dynamic> json) {
    return DriverLocation(
      driverId: json['driver_id'] as String,
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      accuracy: json['accuracy'] != null
          ? (json['accuracy'] as num).toDouble()
          : null,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'driver_id': driverId,
      'lat': lat,
      'lon': lon,
      if (accuracy != null) 'accuracy': accuracy,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [driverId, lat, lon, accuracy, updatedAt];
}

