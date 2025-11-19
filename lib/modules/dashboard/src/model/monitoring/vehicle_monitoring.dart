import 'package:equatable/equatable.dart';

/// Статус техники
enum VehicleStatus {
  inTrip, // Активное движение, точка < 2 мин
  idle, // Простой, точка 2-5 мин
  offline, // Нет данных > 5 мин
}

/// GPS-точка техники
class GpsPoint extends Equatable {
  final double lat;
  final double lon;
  final DateTime capturedAt;
  final double speedKmh;
  final double headingDeg; // Направление движения 0..360
  final bool isSimulated;

  const GpsPoint({
    required this.lat,
    required this.lon,
    required this.capturedAt,
    required this.speedKmh,
    required this.headingDeg,
    this.isSimulated = false,
  });

  factory GpsPoint.fromJson(Map<String, dynamic> json) {
    try {
      return GpsPoint(
        lat: (json['lat'] as num).toDouble(),
        lon: (json['lon'] as num).toDouble(),
        capturedAt: DateTime.parse(json['captured_at'] as String),
        speedKmh: (json['speed_kmh'] as num?)?.toDouble() ?? 0.0,
        headingDeg: (json['heading_deg'] as num?)?.toDouble() ?? 0.0,
        isSimulated: json['is_simulated'] as bool? ?? false,
      );
    } catch (e) {
      throw Exception('Error parsing GpsPoint: $e. JSON: $json');
    }
  }

  @override
  List<Object?> get props => [lat, lon, capturedAt, speedKmh, headingDeg, isSimulated];
}

/// Техника в мониторинге
class VehicleMonitoring extends Equatable {
  final String vehicleId;
  final String plateNumber;
  final String? contractorId;
  final String? contractorName;
  final GpsPoint lastGps;
  final String? lastTicketId;
  final String? lastCleaningAreaId;
  final String? lastPolygonId;
  final VehicleStatus status;

  const VehicleMonitoring({
    required this.vehicleId,
    required this.plateNumber,
    this.contractorId,
    this.contractorName,
    required this.lastGps,
    this.lastTicketId,
    this.lastCleaningAreaId,
    this.lastPolygonId,
    required this.status,
  });

  factory VehicleMonitoring.fromJson(Map<String, dynamic> json) {
    try {
      final statusStr = json['status'] as String? ?? 'OFFLINE';
      VehicleStatus status;
      switch (statusStr) {
        case 'IN_TRIP':
          status = VehicleStatus.inTrip;
          break;
        case 'IDLE':
          status = VehicleStatus.idle;
          break;
        case 'OFFLINE':
        default:
          status = VehicleStatus.offline;
          break;
      }

      final lastGpsJson = json['last_gps'] as Map<String, dynamic>?;
      
      // Если last_gps отсутствует (например, для OFFLINE транспортных средств),
      // создаем фиктивную GPS точку с координатами по умолчанию (центр Петропавловска)
      // или пропускаем транспортное средство, если оно OFFLINE
      GpsPoint? lastGps;
      if (lastGpsJson != null) {
        lastGps = GpsPoint.fromJson(lastGpsJson);
      } else {
        // Для OFFLINE транспортных средств без GPS создаем точку по умолчанию
        // или можно вернуть null и пропустить их при отображении
        if (status == VehicleStatus.offline) {
          // Для OFFLINE транспортных средств без GPS используем координаты по умолчанию
          lastGps = GpsPoint(
            lat: 54.8667, // Центр Петропавловска
            lon: 69.1500,
            capturedAt: DateTime.now().subtract(const Duration(hours: 1)),
            speedKmh: 0.0,
            headingDeg: 0.0,
            isSimulated: false,
          );
        } else {
          // Для других статусов без GPS - ошибка
          throw Exception('last_gps is required but missing in vehicle data for non-OFFLINE vehicle');
        }
      }

      return VehicleMonitoring(
        vehicleId: json['vehicle_id'] as String,
        plateNumber: json['plate_number'] as String,
        contractorId: json['contractor_id'] as String?,
        contractorName: json['contractor_name'] as String?,
        lastGps: lastGps,
        lastTicketId: json['last_ticket_id'] as String?,
        lastCleaningAreaId: json['last_cleaning_area_id'] as String?,
        lastPolygonId: json['last_polygon_id'] as String?,
        status: status,
      );
    } catch (e) {
      throw Exception('Error parsing VehicleMonitoring: $e. JSON: $json');
    }
  }

  @override
  List<Object?> get props => [
        vehicleId,
        plateNumber,
        contractorId,
        contractorName,
        lastGps,
        lastTicketId,
        lastCleaningAreaId,
        lastPolygonId,
        status,
      ];
}

/// Трек техники за период
class VehicleTrack extends Equatable {
  final String vehicleId;
  final DateTime from;
  final DateTime to;
  final List<GpsPoint> points;

  const VehicleTrack({
    required this.vehicleId,
    required this.from,
    required this.to,
    required this.points,
  });

  factory VehicleTrack.fromJson(Map<String, dynamic> json) {
    return VehicleTrack(
      vehicleId: json['vehicle_id'] as String,
      from: DateTime.parse(json['from'] as String),
      to: DateTime.parse(json['to'] as String),
      points: (json['points'] as List<dynamic>)
          .map((p) => GpsPoint.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [vehicleId, from, to, points];
}

