enum AppealStatus {
  submitted('SUBMITTED'),
  underReview('UNDER_REVIEW'),
  needInfo('NEED_INFO'),
  approved('APPROVED'),
  rejected('REJECTED'),
  closed('CLOSED');

  final String value;
  const AppealStatus(this.value);
}

enum AppealReasonCode {
  cameraError('CAMERA_ERROR'),
  transitPath('TRANSIT_PATH'),
  wrongAssignment('WRONG_ASSIGNMENT'),
  other('OTHER');

  final String value;
  const AppealReasonCode(this.value);
}

enum AttachmentFileType {
  image('IMAGE'),
  video('VIDEO'),
  doc('DOC');

  final String value;
  const AttachmentFileType(this.value);
}

class Appeal {
  final String id;
  final String violationId;
  final String tripId;
  final String? ticketId;
  final String driverId;
  final String contractorId;
  final AppealReasonCode reasonCode;
  final String reasonText;
  final AppealStatus status;
  final String? resolvedBy;
  final DateTime? resolvedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Appeal({
    required this.id,
    required this.violationId,
    required this.tripId,
    this.ticketId,
    required this.driverId,
    required this.contractorId,
    required this.reasonCode,
    required this.reasonText,
    required this.status,
    this.resolvedBy,
    this.resolvedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Appeal.fromJson(Map<String, dynamic> json) {
    return Appeal(
      id: json['id'] as String,
      violationId: json['violation_id'] as String,
      tripId: json['trip_id'] as String,
      ticketId: json['ticket_id'] as String?,
      driverId: json['driver_id'] as String,
      contractorId: json['contractor_id'] as String,
      reasonCode: AppealReasonCode.values.firstWhere(
        (e) => e.value == json['reason_code'] as String,
        orElse: () => AppealReasonCode.other,
      ),
      reasonText: json['reason_text'] as String,
      status: AppealStatus.values.firstWhere(
        (e) => e.value == json['status'] as String,
        orElse: () => AppealStatus.submitted,
      ),
      resolvedBy: json['resolved_by'] as String?,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'violation_id': violationId,
      'trip_id': tripId,
      'ticket_id': ticketId,
      'driver_id': driverId,
      'contractor_id': contractorId,
      'reason_code': reasonCode.value,
      'reason_text': reasonText,
      'status': status.value,
      'resolved_by': resolvedBy,
      'resolved_at': resolvedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class AppealAttachment {
  final String id;
  final String appealId;
  final String fileUrl;
  final AttachmentFileType fileType;
  final String uploadedBy;
  final DateTime createdAt;

  AppealAttachment({
    required this.id,
    required this.appealId,
    required this.fileUrl,
    required this.fileType,
    required this.uploadedBy,
    required this.createdAt,
  });

  factory AppealAttachment.fromJson(Map<String, dynamic> json) {
    return AppealAttachment(
      id: json['id'] as String,
      appealId: json['appeal_id'] as String,
      fileUrl: json['file_url'] as String,
      fileType: AttachmentFileType.values.firstWhere(
        (e) => e.value == json['file_type'] as String,
        orElse: () => AttachmentFileType.image,
      ),
      uploadedBy: json['uploaded_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'appeal_id': appealId,
      'file_url': fileUrl,
      'file_type': fileType.value,
      'uploaded_by': uploadedBy,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class AppealComment {
  final String id;
  final String appealId;
  final String authorId;
  final String authorRole;
  final String message;
  final DateTime createdAt;

  AppealComment({
    required this.id,
    required this.appealId,
    required this.authorId,
    required this.authorRole,
    required this.message,
    required this.createdAt,
  });

  factory AppealComment.fromJson(Map<String, dynamic> json) {
    return AppealComment(
      id: json['id'] as String,
      appealId: json['appeal_id'] as String,
      authorId: json['author_id'] as String,
      authorRole: json['author_role'] as String,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'appeal_id': appealId,
      'author_id': authorId,
      'author_role': authorRole,
      'message': message,
      'created_at': createdAt.toIso8601String(),
    };
  }
}





