import 'package:akimat_project/services/violations/model/violation_response.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ViolationsState extends Equatable {
  final AsyncValue<ViolationsListResponse>? violations;
  final AsyncValue<ViolationDetailResponse>? violationDetail;
  final AsyncValue<AppealsListResponse>? appeals;
  final AsyncValue<AppealDetailResponse>? appealDetail;

  const ViolationsState({
    this.violations,
    this.violationDetail,
    this.appeals,
    this.appealDetail,
  });

  ViolationsState copyWith({
    AsyncValue<ViolationsListResponse>? violations,
    AsyncValue<ViolationDetailResponse>? violationDetail,
    AsyncValue<AppealsListResponse>? appeals,
    AsyncValue<AppealDetailResponse>? appealDetail,
  }) {
    return ViolationsState(
      violations: violations ?? this.violations,
      violationDetail: violationDetail ?? this.violationDetail,
      appeals: appeals ?? this.appeals,
      appealDetail: appealDetail ?? this.appealDetail,
    );
  }

  @override
  List<Object?> get props => [
        violations,
        violationDetail,
        appeals,
        appealDetail,
      ];
}

