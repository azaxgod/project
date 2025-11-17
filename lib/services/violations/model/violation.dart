enum ViolationType {
  routeViolation('ROUTE_VIOLATION'),
  foreignArea('FOREIGN_AREA'),
  mismatchPlate('MISMATCH_PLATE'),
  overCapacity('OVER_CAPACITY'),
  noAreaWork('NO_AREA_WORK'),
  noVolumeEvent('NO_VOLUME_EVENT'),
  noLprEvent('NO_LPR_EVENT'),
  noAssignment('NO_ASSIGNMENT'),
  suspiciousVolume('SUSPICIOUS_VOLUME'),
  cameraError('CAMERA_ERROR');

  final String value;
  const ViolationType(this.value);
}

enum ViolationStatus {
  open('OPEN'),
  canceled('CANCELED'),
  fixed('FIXED');

  final String value;
  const ViolationStatus(this.value);
}

enum ViolationSeverity {
  low('LOW'),
  medium('MEDIUM'),
  high('HIGH');

  final String value;
  const ViolationSeverity(this.value);
}

enum ViolationDetectedBy {
  lpr('LPR'),
  volume('VOLUME'),
  gps('GPS'),
  system('SYSTEM');

  final String value;
  const ViolationDetectedBy(this.value);
}

class Violation {
  final String id;
  final String tripId;
  final ViolationType type;
  final ViolationDetectedBy detectedBy;
  final ViolationSeverity severity;
  final ViolationStatus status;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  Violation({
    required this.id,
    required this.tripId,
    required this.type,
    required this.detectedBy,
    required this.severity,
    required this.status,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Violation.fromJson(Map<String, dynamic> json) {
    return Violation(
      id: json['id'] as String,
      tripId: json['trip_id'] as String,
      type: ViolationType.values.firstWhere(
        (e) => e.value == json['type'] as String,
        orElse: () => ViolationType.routeViolation,
      ),
      detectedBy: ViolationDetectedBy.values.firstWhere(
        (e) => e.value == json['detected_by'] as String,
        orElse: () => ViolationDetectedBy.system,
      ),
      severity: ViolationSeverity.values.firstWhere(
        (e) => e.value == json['severity'] as String,
        orElse: () => ViolationSeverity.medium,
      ),
      status: ViolationStatus.values.firstWhere(
        (e) => e.value == json['status'] as String,
        orElse: () => ViolationStatus.open,
      ),
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip_id': tripId,
      'type': type.value,
      'detected_by': detectedBy.value,
      'severity': severity.value,
      'status': status.value,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

