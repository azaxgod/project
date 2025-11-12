import 'package:akimat_project/modules/dashboard/src/model/organizations/driver.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/organization.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/user_role.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/vehicle.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OrganizationsState extends Equatable {
  const OrganizationsState({
    required this.data,
    required this.lastAction,
    required this.role,
    this.organizationId,
    this.message,
  });

  final AsyncValue<OrganizationsData> data;
  final AsyncValue<void> lastAction;
  final String? message;
  final UserRole role;
  final String? organizationId;

  factory OrganizationsState.initial({
    required UserRole role,
    required String? organizationId,
  }) {
    return OrganizationsState(
      data: const AsyncLoading(),
      lastAction: const AsyncData(null),
      role: role,
      organizationId: organizationId,
    );
  }

  OrganizationsState copyWith({
    AsyncValue<OrganizationsData>? data,
    AsyncValue<void>? lastAction,
    String? message,
    UserRole? role,
    String? organizationId,
  }) {
    return OrganizationsState(
      data: data ?? this.data,
      lastAction: lastAction ?? this.lastAction,
      message: message ?? this.message,
      role: role ?? this.role,
      organizationId: organizationId ?? this.organizationId,
    );
  }

  @override
  List<Object?> get props => [data, lastAction, message, role, organizationId];
}

class OrganizationsData extends Equatable {
  const OrganizationsData({
    required this.organizations,
    required this.drivers,
    required this.vehicles,
  });

  final List<Organization> organizations;
  final List<Driver> drivers;
  final List<Vehicle> vehicles;

  OrganizationsData copyWith({
    List<Organization>? organizations,
    List<Driver>? drivers,
    List<Vehicle>? vehicles,
  }) {
    return OrganizationsData(
      organizations: organizations ?? this.organizations,
      drivers: drivers ?? this.drivers,
      vehicles: vehicles ?? this.vehicles,
    );
  }

  @override
  List<Object?> get props => [organizations, drivers, vehicles];
}

