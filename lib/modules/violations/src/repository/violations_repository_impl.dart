import 'package:akimat_project/modules/violations/src/repository/i_violations_repository.dart';
import 'package:akimat_project/services/violations/collection/violations_collection.dart';
import 'package:akimat_project/services/violations/model/appeal.dart';
import 'package:akimat_project/services/violations/model/violation.dart';
import 'package:akimat_project/services/violations/model/violation_response.dart';

class ViolationsRepositoryImpl implements IViolationsRepository {
  final ViolationsCollection collection;

  ViolationsRepositoryImpl({required this.collection});

  @override
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
  }) {
    return collection.getViolations(
      status: status,
      type: type,
      severity: severity,
      detectedBy: detectedBy,
      contractorId: contractorId,
      driverId: driverId,
      ticketId: ticketId,
      cleaningAreaId: cleaningAreaId,
      dateFrom: dateFrom,
      dateTo: dateTo,
      search: search,
      limit: limit,
      offset: offset,
    );
  }

  @override
  Future<ViolationDetailResponse> loadViolationDetail(String violationId) {
    return collection.getViolationDetail(violationId);
  }

  @override
  Future<ViolationRecord> createViolation({
    required String tripId,
    required ViolationType type,
    required ViolationDetectedBy detectedBy,
    required ViolationSeverity severity,
    String? description,
  }) {
    return collection.createViolation(
      tripId: tripId,
      type: type,
      detectedBy: detectedBy,
      severity: severity,
      description: description,
    );
  }

  @override
  Future<void> updateViolationStatus({
    required String violationId,
    required ViolationStatus status,
    String? description,
  }) {
    return collection.updateViolationStatus(
      violationId: violationId,
      status: status,
      description: description,
    );
  }

  @override
  Future<AppealsListResponse> loadAppeals({
    AppealStatus? status,
    AppealReasonCode? reasonCode,
    ViolationType? violationType,
    String? contractorId,
    DateTime? dateFrom,
    DateTime? dateTo,
    int? limit,
    int? offset,
  }) {
    return collection.getAppeals(
      status: status,
      reasonCode: reasonCode,
      violationType: violationType,
      contractorId: contractorId,
      dateFrom: dateFrom,
      dateTo: dateTo,
      limit: limit,
      offset: offset,
    );
  }

  @override
  Future<AppealDetailResponse> loadAppealDetail(String appealId) {
    return collection.getAppealDetail(appealId);
  }

  @override
  Future<AppealRecord> createAppeal({
    required String violationId,
    required AppealReasonCode reasonCode,
    required String reasonText,
    List<Map<String, dynamic>>? attachments,
  }) {
    return collection.createAppeal(
      violationId: violationId,
      reasonCode: reasonCode,
      reasonText: reasonText,
      attachments: attachments,
    );
  }

  @override
  Future<AppealComment> addAppealComment({
    required String appealId,
    required String message,
    List<Map<String, dynamic>>? attachments,
  }) {
    return collection.addAppealComment(
      appealId: appealId,
      message: message,
      attachments: attachments,
    );
  }

  @override
  Future<void> performAppealAction({
    required String appealId,
    required String action,
    String? message,
  }) {
    return collection.performAppealAction(
      appealId: appealId,
      action: action,
      message: message,
    );
  }
}



