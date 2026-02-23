import 'package:akimat_project/modules/dashboard/src/model/areas/cleaning_area.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/organization.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/user_role.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AreasData {
  final List<CleaningArea> areas;
  final List<Organization> contractors;

  const AreasData({
    required this.areas,
    required this.contractors,
  });
}

class AreasState {
  final AsyncValue<AreasData> data;
  final UserRole role;
  final String? organizationId;
  final CleaningAreaStatus? statusFilter;
  final String? contractorFilter;
  final CleaningArea? selectedArea;

  AreasState({
    required this.data,
    required this.role,
    this.organizationId,
    this.statusFilter,
    this.contractorFilter,
    this.selectedArea,
  });

  factory AreasState.initial({
    required UserRole role,
    String? organizationId,
  }) {
    return AreasState(
      data: const AsyncLoading(),
      role: role,
      organizationId: organizationId,
    );
  }

  AreasState copyWith({
    AsyncValue<AreasData>? data,
    UserRole? role,
    String? organizationId,
    CleaningAreaStatus? statusFilter,
    String? contractorFilter,
    CleaningArea? selectedArea,
  }) {
    return AreasState(
      data: data ?? this.data,
      role: role ?? this.role,
      organizationId: organizationId ?? this.organizationId,
      statusFilter: statusFilter ?? this.statusFilter,
      contractorFilter: contractorFilter ?? this.contractorFilter,
      selectedArea: selectedArea ?? this.selectedArea,
    );
  }
}

