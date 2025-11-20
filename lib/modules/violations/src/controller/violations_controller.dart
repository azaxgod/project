import 'package:akimat_project/modules/violations/src/repository/i_violations_repository.dart';
import 'package:akimat_project/modules/violations/src/controller/violations_state.dart';
import 'package:akimat_project/services/violations/model/appeal.dart';
import 'package:akimat_project/services/violations/model/violation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ViolationsController extends StateNotifier<ViolationsState> {
  ViolationsController({
    required IViolationsRepository repository,
  })  : _repository = repository,
        super(const ViolationsState());

  final IViolationsRepository _repository;

  Future<void> loadViolations({
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
  }) async {
    state = state.copyWith(violations: const AsyncLoading());
    state = state.copyWith(
      violations: await AsyncValue.guard(
        () => _repository.loadViolations(
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
        ),
      ),
    );
  }

  Future<void> loadViolationDetail(String violationId) async {
    state = state.copyWith(violationDetail: const AsyncLoading());
    state = state.copyWith(
      violationDetail: await AsyncValue.guard(
        () => _repository.loadViolationDetail(violationId),
      ),
    );
  }

  Future<void> createViolation({
    required String tripId,
    required ViolationType type,
    required ViolationDetectedBy detectedBy,
    required ViolationSeverity severity,
    String? description,
  }) async {
    await _repository.createViolation(
      tripId: tripId,
      type: type,
      detectedBy: detectedBy,
      severity: severity,
      description: description,
    );
    // Перезагружаем список
    await loadViolations();
  }

  Future<void> updateViolationStatus({
    required String violationId,
    required ViolationStatus status,
    String? description,
  }) async {
    await _repository.updateViolationStatus(
      violationId: violationId,
      status: status,
      description: description,
    );
    // Перезагружаем детали
    await loadViolationDetail(violationId);
    // Перезагружаем список
    await loadViolations();
  }

  Future<void> loadAppeals({
    AppealStatus? status,
    AppealReasonCode? reasonCode,
    ViolationType? violationType,
    String? contractorId,
    DateTime? dateFrom,
    DateTime? dateTo,
    int? limit,
    int? offset,
  }) async {
    state = state.copyWith(appeals: const AsyncLoading());
    state = state.copyWith(
      appeals: await AsyncValue.guard(
        () => _repository.loadAppeals(
          status: status,
          reasonCode: reasonCode,
          violationType: violationType,
          contractorId: contractorId,
          dateFrom: dateFrom,
          dateTo: dateTo,
          limit: limit,
          offset: offset,
        ),
      ),
    );
  }

  Future<void> loadAppealDetail(String appealId) async {
    state = state.copyWith(appealDetail: const AsyncLoading());
    state = state.copyWith(
      appealDetail: await AsyncValue.guard(
        () => _repository.loadAppealDetail(appealId),
      ),
    );
  }

  Future<void> createAppeal({
    required String violationId,
    required AppealReasonCode reasonCode,
    required String reasonText,
    List<Map<String, dynamic>>? attachments,
  }) async {
    await _repository.createAppeal(
      violationId: violationId,
      reasonCode: reasonCode,
      reasonText: reasonText,
      attachments: attachments,
    );
    // Перезагружаем детали нарушения
    await loadViolationDetail(violationId);
    // Перезагружаем список апелляций
    await loadAppeals();
  }

  Future<void> addAppealComment({
    required String appealId,
    required String message,
    List<Map<String, dynamic>>? attachments,
  }) async {
    await _repository.addAppealComment(
      appealId: appealId,
      message: message,
      attachments: attachments,
    );
    // Перезагружаем детали апелляции
    await loadAppealDetail(appealId);
  }

  Future<void> performAppealAction({
    required String appealId,
    required String action,
    String? message,
  }) async {
    await _repository.performAppealAction(
      appealId: appealId,
      action: action,
      message: message,
    );
    // Перезагружаем детали апелляции
    await loadAppealDetail(appealId);
    // Перезагружаем список апелляций
    await loadAppeals();
  }
}



