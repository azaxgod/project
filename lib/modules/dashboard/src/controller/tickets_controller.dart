import 'package:akimat_project/modules/auth/src/controller/auth_notifier.dart';
import 'package:akimat_project/modules/dashboard/src/controller/tickets_state.dart';
import 'package:akimat_project/modules/dashboard/src/model/areas/cleaning_area.dart';
import 'package:akimat_project/modules/dashboard/src/model/contracts/contract.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/organization_type.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/user_role.dart';
import 'package:akimat_project/modules/dashboard/src/model/tickets/ticket.dart';
import 'package:akimat_project/modules/dashboard/src/model/tickets/ticket_assignment.dart';
import 'package:akimat_project/modules/dashboard/src/repository/contracts_repository.dart';
import 'package:akimat_project/modules/dashboard/src/repository/contracts_repository_impl.dart';
import 'package:akimat_project/modules/dashboard/src/repository/operations_repository.dart';
import 'package:akimat_project/modules/dashboard/src/repository/operations_repository_impl.dart';
import 'package:akimat_project/modules/dashboard/src/repository/organizations_repository.dart';
import 'package:akimat_project/modules/dashboard/src/repository/organizations_repository_impl.dart';
import 'package:akimat_project/services/contracts/module.dart';
import 'package:akimat_project/services/operations/module.dart';
import 'package:akimat_project/services/organizations/module.dart';
import 'package:akimat_project/services/tickets/module.dart';
import 'package:flutter/foundation.dart';
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
      ticketsServices: ref.watch(ticketsServicesProvider),
      userRole: role,
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
        // Обрабатываем ошибки загрузки участков отдельно, чтобы не ломать всю страницу
        List<CleaningArea> areas = [];
        try {
          areas = await _operationsRepository.loadCleaningAreas(onlyActive: true);
        } catch (e) {
          // Если не удалось загрузить участки, продолжаем с пустым списком
          // Пользователь все равно сможет работать с тикетами
          debugPrint('TicketsController: Failed to load cleaning areas: $e');
          // Можно показать предупреждение пользователю, но не блокировать работу
        }

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
          debugPrint('TicketsController: Failed to load contracts: $e');
        }

        // Load tickets from operations repository
        List<Ticket> tickets = [];
        try {
          // Фильтруем по роли
          // ВАЖНО: Для подрядчика НЕ передаем contractorId в loadTickets(),
          // так как endpoint /contractor/tickets автоматически фильтрует по contractor_id из JWT токена
          String? contractorFilter;
          String? driverFilter;
          
          // Для подрядчика НЕ устанавливаем contractorFilter, так как сервер сам фильтрует по JWT
          // Для других ролей (Akimat, KGU ZKH) можно передать contractorFilter для фильтрации
          if (state.role != UserRole.contractorAdmin && state.role != UserRole.driver) {
            contractorFilter = state.contractorFilter;
          } else if (state.role == UserRole.driver && state.organizationId != null) {
            // TODO: Получить driverId из organizationId или из authState
            // Пока используем organizationId как driverId (временное решение)
            driverFilter = state.organizationId;
          }

          debugPrint('TicketsController._loadData: Loading tickets with filters:');
          debugPrint('  - role: ${state.role}');
          debugPrint('  - organizationId: ${state.organizationId}');
          debugPrint('  - statusFilter: ${state.statusFilter}');
          debugPrint('  - contractorFilter: ${contractorFilter ?? state.contractorFilter} (will be ignored for contractor)');
          debugPrint('  - areaFilter: ${state.areaFilter}');
          debugPrint('  - contractFilter: ${state.contractFilter}');
          debugPrint('  - periodStart: ${state.periodStart}');
          debugPrint('  - periodEnd: ${state.periodEnd}');

          tickets = await _operationsRepository.loadTickets(
            status: state.statusFilter,
            contractorId: contractorFilter ?? state.contractorFilter,
            cleaningAreaId: state.areaFilter,
            contractId: state.contractFilter,
            plannedStartFrom: state.periodStart,
            plannedStartTo: state.periodEnd,
            factStartFrom: state.factPeriodStart,
            factStartTo: state.factPeriodEnd,
            driverId: driverFilter,
          );
          
          debugPrint('TicketsController._loadData: Loaded ${tickets.length} tickets');
          if (tickets.isNotEmpty) {
            debugPrint('TicketsController._loadData: First ticket status: ${tickets.first.status}');
            debugPrint('TicketsController._loadData: First ticket ID: ${tickets.first.id}');
            debugPrint('TicketsController._loadData: First ticket contractorId: ${tickets.first.contractorId}');
            debugPrint('TicketsController._loadData: Expected organizationId: ${state.organizationId}');
          } else {
            debugPrint('TicketsController._loadData: No tickets loaded!');
          }
        } catch (e, stackTrace) {
          // Если не удалось загрузить тикеты, продолжаем с пустым списком
          debugPrint('TicketsController: Failed to load tickets: $e');
          debugPrint('TicketsController: Stack trace: $stackTrace');
        }

        // Загружаем назначения для всех тикетов (только для Подрядчика, Акимата и KGU ZKH)
        Map<String, List<TicketAssignment>> assignments = {};
        if (state.role == UserRole.contractorAdmin || state.role == UserRole.akimatAdmin || state.role == UserRole.kguZkhAdmin) {
          for (final ticket in tickets) {
            try {
              final ticketAssignments = await _operationsRepository.getTicketAssignments(ticket.id);
              assignments[ticket.id] = ticketAssignments;
            } catch (e) {
              debugPrint('TicketsController: Failed to load assignments for ticket ${ticket.id}: $e');
              assignments[ticket.id] = [];
            }
          }
        }

        final ticketsData = TicketsData(
          tickets: tickets,
          contractors: contractors,
          areas: areas,
          contracts: contracts,
          assignments: assignments,
        );
        
        debugPrint('TicketsController._loadData: Created TicketsData with ${ticketsData.tickets.length} tickets');
        debugPrint('TicketsController._loadData: TicketsData contractors: ${ticketsData.contractors.length}');
        debugPrint('TicketsController._loadData: TicketsData areas: ${ticketsData.areas.length}');
        debugPrint('TicketsController._loadData: TicketsData contracts: ${ticketsData.contracts.length}');
        
        return ticketsData;
      }),
    );
  }

  Future<void> refresh() => _loadData();

  void selectTicket(Ticket? ticket) {
    state = state.copyWith(selectedTicket: ticket);
  }

  void setStatusFilter(TicketStatus? status) {
    debugPrint('TicketsController.setStatusFilter: called with status=$status');
    debugPrint('TicketsController.setStatusFilter: current statusFilter=${state.statusFilter}');
    // Всегда обновляем состояние и перезагружаем данные,
    // даже если значение не изменилось (например, повторный выбор "Все")
    state = state.copyWith(statusFilter: status);
    debugPrint('TicketsController.setStatusFilter: new statusFilter=${state.statusFilter}');
    _loadData();
  }

  void setContractorFilter(String? contractorId) {
    debugPrint('TicketsController.setContractorFilter: called with contractorId=$contractorId');
    debugPrint('TicketsController.setContractorFilter: current contractorFilter=${state.contractorFilter}');
    // Всегда обновляем состояние и перезагружаем данные,
    // даже если значение не изменилось (например, повторный выбор "Все")
    state = state.copyWith(contractorFilter: contractorId);
    debugPrint('TicketsController.setContractorFilter: new contractorFilter=${state.contractorFilter}');
    _loadData();
  }

  void setAreaFilter(String? areaId) {
    debugPrint('TicketsController.setAreaFilter: called with areaId=$areaId');
    debugPrint('TicketsController.setAreaFilter: current areaFilter=${state.areaFilter}');
    // Всегда обновляем состояние и перезагружаем данные,
    // даже если значение не изменилось (например, повторный выбор "Все")
    state = state.copyWith(areaFilter: areaId);
    debugPrint('TicketsController.setAreaFilter: new areaFilter=${state.areaFilter}');
    _loadData();
  }

  void setContractFilter(String? contractId) {
    debugPrint('TicketsController.setContractFilter: called with contractId=$contractId');
    debugPrint('TicketsController.setContractFilter: current contractFilter=${state.contractFilter}');
    // Всегда обновляем состояние и перезагружаем данные,
    // даже если значение не изменилось (например, повторный выбор "Все")
    state = state.copyWith(contractFilter: contractId);
    debugPrint('TicketsController.setContractFilter: new contractFilter=${state.contractFilter}');
    _loadData();
  }

  void setPeriodFilter(DateTime? start, DateTime? end) {
    state = state.copyWith(
      periodStart: start,
      periodEnd: end,
    );
    _loadData();
  }

  void setFactPeriodFilter(DateTime? start, DateTime? end) {
    state = state.copyWith(
      factPeriodStart: start,
      factPeriodEnd: end,
    );
    _loadData();
  }

  Future<void> cancelTicket(Ticket ticket) async {
    // Отмена тикета возможна только если нет фактов:
    // - нет trip с этим ticket_id
    // - fact_start_at IS NULL
    if (ticket.factStartAt != null || (ticket.tripsCount ?? 0) > 0) {
      state = state.copyWith(
        message: 'Невозможно отменить тикет с фактами работ. Убедитесь, что нет рейсов и фактического начала работ.',
      );
      return;
    }

    final result = await AsyncValue.guard(() async {
      return await _operationsRepository.updateTicketStatus(
        ticket.id,
        status: TicketStatus.cancelled,
      );
    });

    state = state.copyWith(
      lastAction: result.whenData((_) => const AsyncValue.data(null)),
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
      // TODO: Добавить проверки перед закрытием (все рейсы закрыты, объем на выезде ≈ 0)
      return await _operationsRepository.updateTicketStatus(
        ticket.id,
        status: TicketStatus.closed,
      );
    });

    state = state.copyWith(
      lastAction: result.whenData((_) => const AsyncValue.data(null)),
      message: result.hasError ? 'Ошибка при закрытии тикета' : 'Тикет закрыт',
    );

    if (!result.hasError) {
      await _loadData();
    }
  }

  Future<void> createTicket(Ticket ticket) async {
    final result = await AsyncValue.guard(() async {
      return await _operationsRepository.createTicket(
        cleaningAreaId: ticket.cleaningAreaId,
        contractorId: ticket.contractorId,
        contractId: ticket.contractId,
        plannedStartAt: ticket.plannedStartAt,
        plannedEndAt: ticket.plannedEndAt,
        description: ticket.description,
        createdByOrgId: ticket.createdByOrgId,
      );
    });

    if (!result.hasError) {
      // ВАЖНО: Сбрасываем фильтры ПЕРЕД загрузкой данных, чтобы новый тикет был виден
      state = state.copyWith(
        statusFilter: null,
        contractorFilter: null,
        areaFilter: null,
        contractFilter: null,
        periodStart: null,
        periodEnd: null,
        factPeriodStart: null,
        factPeriodEnd: null,
        lastAction: result.whenData((_) => const AsyncValue.data(null)),
        message: 'Тикет создан',
      );
      // Обновляем данные после сброса фильтров
      await _loadData();
    } else {
      state = state.copyWith(
        lastAction: result.whenData((_) => const AsyncValue.data(null)),
        message: 'Ошибка при создании тикета',
      );
    }
  }

  Future<void> updateTicket(Ticket ticket) async {
    final result = await AsyncValue.guard(() async {
      // KGU ZKH может редактировать только до начала фактов
      if (ticket.factStartAt != null || (ticket.tripsCount ?? 0) > 0) {
        throw Exception('Невозможно редактировать тикет с фактами работ');
      }
      
      return await _operationsRepository.updateTicket(
        ticket.id,
        cleaningAreaId: ticket.cleaningAreaId,
        contractorId: ticket.contractorId,
        contractId: ticket.contractId,
        plannedStartAt: ticket.plannedStartAt,
        plannedEndAt: ticket.plannedEndAt,
        description: ticket.description,
      );
    });

    state = state.copyWith(
      lastAction: result.whenData((_) => const AsyncValue.data(null)),
      message: result.hasError ? 'Ошибка при обновлении тикета' : 'Тикет обновлен',
    );

    if (!result.hasError) {
      await _loadData();
    }
  }

  /// Назначить водителя/технику на тикет
  Future<void> assignDriverVehicle({
    required String ticketId,
    String? driverId,
    String? vehicleId,
  }) async {
    final result = await AsyncValue.guard(() async {
      return await _operationsRepository.createTicketAssignment(
        ticketId,
        driverId: driverId,
        vehicleId: vehicleId,
      );
    });

    state = state.copyWith(
      lastAction: result.whenData((_) => const AsyncValue.data(null)),
      message: result.hasError ? 'Ошибка при назначении' : 'Назначение создано',
    );

    if (!result.hasError) {
      await _loadData();
    }
  }

  /// Удалить назначение
  Future<void> removeAssignment(String ticketId, String assignmentId) async {
    final result = await AsyncValue.guard(() async {
      await _operationsRepository.deleteTicketAssignment(ticketId, assignmentId);
    });

    state = state.copyWith(
      lastAction: result.whenData((_) => const AsyncValue.data(null)),
      message: result.hasError ? 'Ошибка при удалении назначения' : 'Назначение удалено',
    );

    if (!result.hasError) {
      await _loadData();
    }
  }

  /// Перевести тикет в IN_PROGRESS
  Future<void> startTicket(Ticket ticket) async {
    final result = await AsyncValue.guard(() async {
      return await _operationsRepository.updateTicketStatus(
        ticket.id,
        status: TicketStatus.inProgress,
      );
    });

    state = state.copyWith(
      lastAction: result.whenData((_) => const AsyncValue.data(null)),
      message: result.hasError ? 'Ошибка при начале работ' : 'Работы начаты',
    );

    if (!result.hasError) {
      await _loadData();
    }
  }

  /// Перевести тикет в COMPLETED (с проверками)
  Future<void> completeTicket(Ticket ticket) async {
    // TODO: Реализовать проверки:
    // - Все рейсы закрыты (polygon_exit_time заполнено)
    // - Объём на выезде ≈ 0 для рейсов с exit_volume_event
    // Пока просто переводим в COMPLETED
    final result = await AsyncValue.guard(() async {
      return await _operationsRepository.updateTicketStatus(
        ticket.id,
        status: TicketStatus.completed,
      );
    });

    state = state.copyWith(
      lastAction: result.whenData((_) => const AsyncValue.data(null)),
      message: result.hasError ? 'Ошибка при завершении работ' : 'Работы завершены',
    );

    if (!result.hasError) {
      await _loadData();
    }
  }
}

