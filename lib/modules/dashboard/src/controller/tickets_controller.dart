import 'package:akimat_project/modules/auth/src/controller/auth_notifier.dart';
import 'package:akimat_project/modules/dashboard/src/controller/tickets_state.dart';
import 'package:akimat_project/modules/dashboard/src/model/areas/cleaning_area.dart';
import 'package:akimat_project/modules/dashboard/src/model/contracts/contract.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/organization.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/organization_type.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/user_role.dart';
import 'package:akimat_project/modules/dashboard/src/model/tickets/ticket.dart';
import 'package:akimat_project/modules/dashboard/src/repository/organizations_repository.dart';
import 'package:akimat_project/modules/dashboard/src/repository/organizations_repository_impl.dart';
import 'package:akimat_project/services/organizations/module.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final ticketsControllerProvider = StateNotifierProvider<TicketsController, TicketsState>((ref) {
  final authState = ref.watch(authNotifierProvider);
  final role = userRoleFromString(authState.user?.role);
  final organizationId = authState.user?.organizationId;

  return TicketsController(
    repository: OrganizationsRepositoryImpl(
      services: ref.watch(organizationsServicesProvider),
    ),
    initialState: TicketsState.initial(
      role: role,
      organizationId: organizationId,
    ),
  );
});

class TicketsController extends StateNotifier<TicketsState> {
  TicketsController({
    required OrganizationsRepository repository,
    required TicketsState initialState,
  })  : _repository = repository,
        super(initialState) {
    _loadData();
  }

  final OrganizationsRepository _repository;

  Future<void> _loadData() async {
    state = state.copyWith(data: const AsyncLoading());
    state = state.copyWith(
      data: await AsyncValue.guard(() async {
        // Load contractors and areas for filters
        final organizations = await _repository.loadOrganizations();
        final contractors = organizations
            .where((org) => org.type == OrganizationType.contractor)
            .toList();

        // TODO: Load areas from repository when implemented
        final areas = <CleaningArea>[];

        // TODO: Load contracts from repository when implemented
        final contracts = <Contract>[];

        // TODO: Load tickets from repository when implemented
        final tickets = <Ticket>[];

        return TicketsData(
          tickets: tickets,
          contractors: contractors,
          areas: areas,
          contracts: contracts,
        );
      }),
    );
  }

  Future<void> refresh() => _loadData();

  void selectTicket(Ticket? ticket) {
    state = state.copyWith(selectedTicket: ticket);
  }

  void setStatusFilter(TicketStatus? status) {
    state = state.copyWith(statusFilter: status);
  }

  void setContractorFilter(String? contractorId) {
    state = state.copyWith(contractorFilter: contractorId);
  }

  void setAreaFilter(String? areaId) {
    state = state.copyWith(areaFilter: areaId);
  }

  void setContractFilter(String? contractId) {
    state = state.copyWith(contractFilter: contractId);
  }

  void setPeriodFilter(DateTime? start, DateTime? end) {
    state = state.copyWith(
      periodStart: start,
      periodEnd: end,
    );
  }

  void setFactPeriodFilter(DateTime? start, DateTime? end) {
    state = state.copyWith(
      factPeriodStart: start,
      factPeriodEnd: end,
    );
  }

  Future<void> cancelTicket(Ticket ticket) async {
    // Отмена тикета возможна только если нет фактов
    if (ticket.factStartAt != null || (ticket.tripsCount ?? 0) > 0) {
      state = state.copyWith(
        message: 'Невозможно отменить тикет с фактами работ',
      );
      return;
    }

    final result = await AsyncValue.guard(() async {
      // TODO: Implement repository method
      return ticket.copyWith(
        status: TicketStatus.cancelled,
        updatedAt: DateTime.now(),
      );
    });

    state = state.copyWith(
      lastAction: result.whenData((_) => null),
      message: result.hasError ? 'Ошибка при отмене тикета' : 'Тикет отменен',
    );

    if (!result.hasError) {
      await _loadData();
    }
  }

  Future<void> closeTicket(Ticket ticket) async {
    // Закрытие возможно только если тикет COMPLETED
    if (ticket.status != TicketStatus.completed) {
      state = state.copyWith(
        message: 'Можно закрыть только завершенный тикет',
      );
      return;
    }

    final result = await AsyncValue.guard(() async {
      // TODO: Implement repository method
      return ticket.copyWith(
        status: TicketStatus.closed,
        updatedAt: DateTime.now(),
      );
    });

    state = state.copyWith(
      lastAction: result.whenData((_) => null),
      message: result.hasError ? 'Ошибка при закрытии тикета' : 'Тикет закрыт',
    );

    if (!result.hasError) {
      await _loadData();
    }
  }

  Future<void> createTicket(Ticket ticket) async {
    final result = await AsyncValue.guard(() async {
      // TODO: Implement repository method
      return ticket;
    });

    state = state.copyWith(
      lastAction: result.whenData((_) => null),
      message: result.hasError ? 'Ошибка при создании тикета' : 'Тикет создан',
    );

    if (!result.hasError) {
      await _loadData();
    }
  }

  Future<void> updateTicket(Ticket ticket) async {
    final result = await AsyncValue.guard(() async {
      // TODO: Implement repository method
      return ticket;
    });

    state = state.copyWith(
      lastAction: result.whenData((_) => null),
      message: result.hasError ? 'Ошибка при обновлении тикета' : 'Тикет обновлен',
    );

    if (!result.hasError) {
      await _loadData();
    }
  }
}

