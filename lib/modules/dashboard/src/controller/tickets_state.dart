import 'package:akimat_project/modules/dashboard/src/model/areas/cleaning_area.dart';
import 'package:akimat_project/modules/dashboard/src/model/contracts/contract.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/organization.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/user_role.dart';
import 'package:akimat_project/modules/dashboard/src/model/tickets/ticket.dart';
import 'package:akimat_project/modules/dashboard/src/model/tickets/ticket_assignment.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TicketsState extends Equatable {
  const TicketsState({
    required this.data,
    required this.lastAction,
    required this.role,
    this.organizationId,
    this.message,
    this.selectedTicket,
    this.statusFilter,
    this.contractorFilter,
    this.areaFilter,
    this.contractFilter,
    this.periodStart,
    this.periodEnd,
    this.factPeriodStart,
    this.factPeriodEnd,
  });

  final AsyncValue<TicketsData> data;
  final AsyncValue<void> lastAction;
  final String? message;
  final UserRole role;
  final String? organizationId;
  final Ticket? selectedTicket;
  final TicketStatus? statusFilter;
  final String? contractorFilter;
  final String? areaFilter;
  final String? contractFilter;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final DateTime? factPeriodStart;
  final DateTime? factPeriodEnd;

  factory TicketsState.initial({
    required UserRole role,
    required String? organizationId,
  }) {
    return TicketsState(
      data: const AsyncLoading(),
      lastAction: const AsyncData(null),
      role: role,
      organizationId: organizationId,
    );
  }

  TicketsState copyWith({
    AsyncValue<TicketsData>? data,
    AsyncValue<void>? lastAction,
    String? message,
    UserRole? role,
    String? organizationId,
    Ticket? selectedTicket,
    TicketStatus? statusFilter,
    String? contractorFilter,
    String? areaFilter,
    String? contractFilter,
    DateTime? periodStart,
    DateTime? periodEnd,
    DateTime? factPeriodStart,
    DateTime? factPeriodEnd,
  }) {
    return TicketsState(
      data: data ?? this.data,
      lastAction: lastAction ?? this.lastAction,
      message: message ?? this.message,
      role: role ?? this.role,
      organizationId: organizationId ?? this.organizationId,
      selectedTicket: selectedTicket,
      statusFilter: statusFilter,
      contractorFilter: contractorFilter,
      areaFilter: areaFilter,
      contractFilter: contractFilter,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      factPeriodStart: factPeriodStart ?? this.factPeriodStart,
      factPeriodEnd: factPeriodEnd ?? this.factPeriodEnd,
    );
  }

  @override
  List<Object?> get props => [
        data,
        lastAction,
        message,
        role,
        organizationId,
        selectedTicket,
        statusFilter,
        contractorFilter,
        areaFilter,
        contractFilter,
        periodStart,
        periodEnd,
        factPeriodStart,
        factPeriodEnd,
      ];
}

class TicketsData extends Equatable {
  const TicketsData({
    required this.tickets,
    required this.contractors,
    required this.areas,
    required this.contracts,
    this.assignments = const {},
  });

  final List<Ticket> tickets;
  final List<Organization> contractors;
  final List<CleaningArea> areas;
  final List<Contract> contracts;
  final Map<String, List<TicketAssignment>> assignments; // ticketId -> assignments

  TicketsData copyWith({
    List<Ticket>? tickets,
    List<Organization>? contractors,
    List<CleaningArea>? areas,
    List<Contract>? contracts,
    Map<String, List<TicketAssignment>>? assignments,
  }) {
    return TicketsData(
      tickets: tickets ?? this.tickets,
      contractors: contractors ?? this.contractors,
      areas: areas ?? this.areas,
      contracts: contracts ?? this.contracts,
      assignments: assignments ?? this.assignments,
    );
  }

  @override
  List<Object?> get props => [tickets, contractors, areas, contracts, assignments];
}

