import 'package:akimat_project/modules/dashboard/src/model/contracts/contract.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/organization.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/user_role.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ContractsState extends Equatable {
  const ContractsState({
    required this.data,
    required this.role,
    this.organizationId,
    this.contractorFilter,
    this.statusFilter,
    this.periodStart,
    this.periodEnd,
  });

  final AsyncValue<ContractsData> data;
  final UserRole role;
  final String? organizationId;
  final String? contractorFilter;
  final ContractStatus? statusFilter;
  final DateTime? periodStart;
  final DateTime? periodEnd;

  factory ContractsState.initial({
    required UserRole role,
    required String? organizationId,
  }) {
    return ContractsState(
      data: const AsyncLoading(),
      role: role,
      organizationId: organizationId,
    );
  }

  ContractsState copyWith({
    AsyncValue<ContractsData>? data,
    UserRole? role,
    String? organizationId,
    String? contractorFilter,
    ContractStatus? statusFilter,
    DateTime? periodStart,
    DateTime? periodEnd,
    bool clearContractorFilter = false,
    bool clearStatusFilter = false,
    bool clearPeriodStart = false,
    bool clearPeriodEnd = false,
  }) {
    return ContractsState(
      data: data ?? this.data,
      role: role ?? this.role,
      organizationId: organizationId ?? this.organizationId,
      contractorFilter: clearContractorFilter ? null : (contractorFilter ?? this.contractorFilter),
      statusFilter: clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      periodStart: clearPeriodStart ? null : (periodStart ?? this.periodStart),
      periodEnd: clearPeriodEnd ? null : (periodEnd ?? this.periodEnd),
    );
  }

  @override
  List<Object?> get props => [
        data,
        role,
        organizationId,
        contractorFilter,
        statusFilter,
        periodStart,
        periodEnd,
      ];
}

class ContractsData extends Equatable {
  const ContractsData({
    required this.contracts,
    required this.contractors,
  });

  final List<Contract> contracts;
  final List<Organization> contractors;

  @override
  List<Object?> get props => [contracts, contractors];
}

