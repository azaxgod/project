import 'package:akimat_project/modules/auth/src/controller/auth_notifier.dart';
import 'package:akimat_project/modules/dashboard/src/controller/tickets_state.dart';
import 'package:akimat_project/modules/dashboard/src/model/areas/cleaning_area.dart';
import 'package:akimat_project/modules/dashboard/src/model/contracts/contract.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/organization_type.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/user_role.dart';
import 'package:akimat_project/modules/dashboard/src/model/tickets/ticket.dart';
import 'package:akimat_project/modules/dashboard/src/repository/contracts_repository.dart';
import 'package:akimat_project/modules/dashboard/src/repository/contracts_repository_impl.dart';
import 'package:akimat_project/modules/dashboard/src/repository/operations_repository.dart';
import 'package:akimat_project/modules/dashboard/src/repository/operations_repository_impl.dart';
import 'package:akimat_project/modules/dashboard/src/repository/organizations_repository.dart';
import 'package:akimat_project/modules/dashboard/src/repository/organizations_repository_impl.dart';
import 'package:akimat_project/services/contracts/module.dart';
import 'package:akimat_project/services/operations/module.dart';
import 'package:akimat_project/services/organizations/module.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final contractsRepositoryProvider = Provider<ContractsRepository>((ref) {
  return ContractsRepositoryImpl(
    services: ref.watch(contractsServicesProvider),
  );
});

final ticketsControllerProvider = StateNotifierProvider<TicketsController, TicketsState>((ref) {
  final authState = ref.watch(authNotifierProvider);
  final role = userRoleFromString(authState.user?.role);
  final organizationId = authState.user?.organizationId;

  return TicketsController(
    organizationsRepository: OrganizationsRepositoryImpl(
      services: ref.watch(organizationsServicesProvider),
    ),
    contractsRepository: ref.watch(contractsRepositoryProvider),
    operationsRepository: OperationsRepositoryImpl(
      services: ref.watch(operationsServicesProvider),
    ),
    initialState: TicketsState.initial(
      role: role,
      organizationId: organizationId,
    ),
  );
});

class TicketsController extends StateNotifier<TicketsState> {
  TicketsController({
    required OrganizationsRepository organizationsRepository,
    required ContractsRepository contractsRepository,
    required OperationsRepository operationsRepository,
    required TicketsState initialState,
  })  : _organizationsRepository = organizationsRepository,
        _contractsRepository = contractsRepository,
        _operationsRepository = operationsRepository,
        super(initialState) {
    _loadData();
  }

  final OrganizationsRepository _organizationsRepository;
  final ContractsRepository _contractsRepository;
  final OperationsRepository _operationsRepository;

  Future<void> _loadData() async {
    state = state.copyWith(data: const AsyncLoading());
    state = state.copyWith(
      data: await AsyncValue.guard(() async {
        // Load contractors and areas for filters
        final organizations = await _organizationsRepository.loadOrganizations();
        final contractors = organizations
            .where((org) => org.type == OrganizationType.contractor)
            .toList();

        // Load areas from operations repository
        final areas = await _operationsRepository.loadCleaningAreas(onlyActive: true);

        // Load contracts from contract-service
        List<Contract> contracts = [];
        try {
          // Для подрядчика загружаем только свои контракты
          if (state.role == UserRole.contractorAdmin && state.organizationId != null) {
            contracts = await _contractsRepository.loadContracts(
              contractorId: state.organizationId,
            );
          } else if (state.role == UserRole.akimatAdmin || state.role == UserRole.kguZkhAdmin) {
            // Для Акимата и KGU ZKH загружаем все контракты
            contracts = await _contractsRepository.loadContracts();
          }
        } catch (e) {
          // Игнорируем ошибки загрузки контрактов, продолжаем работу
          // Ошибка будет видна в UI через AsyncValue
        }

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

