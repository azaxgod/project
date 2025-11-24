import 'package:akimat_project/services/violations/model/appeal.dart';
import 'package:akimat_project/services/violations/model/violation.dart';
import 'package:akimat_project/services/violations/model/violation_response.dart';

abstract class IViolationsRepository {
  Future<ViolationsListResponse> loadViolations({
    ViolationStatus? status,
    ViolationType? type,
    ViolationSeverity? severity,
    ViolationDetectedBy? detectedBy,
    String? contractorId,
    String? driverId,
    String? ticketId,
    String? cleaningAreaId,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? search,
    int? limit,
    int? offset,
  });

  Future<ViolationDetailResponse> loadViolationDetail(String violationId);

  Future<ViolationRecord> createViolation({
    required String tripId,
    required ViolationType type,
    required ViolationDetectedBy detectedBy,
    required ViolationSeverity severity,
    String? description,
  });

  Future<void> updateViolationStatus({
    required String violationId,
    required ViolationStatus status,
    String? description,
  });

  Future<AppealsListResponse> loadAppeals({
    AppealStatus? status,
    AppealReasonCode? reasonCode,
    ViolationType? violationType,
    String? contractorId,
    DateTime? dateFrom,
    DateTime? dateTo,
    int? limit,
    int? offset,
  });

  Future<AppealDetailResponse> loadAppealDetail(String appealId);

  Future<AppealRecord> createAppeal({
    required String violationId,
    required AppealReasonCode reasonCode,
    required String reasonText,
    List<Map<String, dynamic>>? attachments,
  });

  Future<AppealComment> addAppealComment({
    required String appealId,
    required String message,
    List<Map<String, dynamic>>? attachments,
  });

  Future<void> performAppealAction({
    required String appealId,
    required String action,
    String? message,
  });
}





