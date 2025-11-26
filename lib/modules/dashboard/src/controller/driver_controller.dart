import 'package:akimat_project/core/di.dart';
import 'package:akimat_project/modules/auth/src/controller/auth_notifier.dart';
import 'package:akimat_project/modules/dashboard/src/controller/areas_controller.dart';
import 'package:akimat_project/modules/dashboard/src/model/areas/cleaning_area.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/driver.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/organization.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/user_role.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/vehicle.dart';
import 'package:akimat_project/modules/dashboard/src/model/polygons/polygon.dart' as model;
import 'package:akimat_project/modules/dashboard/src/model/tickets/ticket.dart';
import 'package:akimat_project/modules/dashboard/src/model/tickets/ticket_assignment.dart';
import 'package:akimat_project/modules/dashboard/src/repository/operations_repository.dart';
import 'package:akimat_project/modules/dashboard/src/repository/organizations_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DriverState {
  final AsyncValue<DriverData> data;
  final Ticket? currentTicket;
  final TicketAssignment? currentAssignment;

  const DriverState({
    required this.data,
    this.currentTicket,
    this.currentAssignment,
  });

  factory DriverState.initial() {
    return const DriverState(
      data: AsyncLoading(),
    );
  }

  DriverState copyWith({
    AsyncValue<DriverData>? data,
    Ticket? currentTicket,
    TicketAssignment? currentAssignment,
  }) {
    return DriverState(
      data: data ?? this.data,
      currentTicket: currentTicket ?? this.currentTicket,
      currentAssignment: currentAssignment ?? this.currentAssignment,
    );
  }
}

class DriverData {
  final Organization? contractor; // Организация подрядчика
  final Driver? driver; // Информация о водителе
  final Vehicle? vehicle; // Привязанная техника
  final List<Ticket> tickets; // Все тикеты водителя
  final Map<String, List<TicketAssignment>> assignments; // Назначения по тикетам
  final Map<String, CleaningArea> cleaningAreas; // Участки уборки по ID
  final Map<String, model.Polygon> polygons; // Полигоны по ID

  const DriverData({
    this.contractor,
    this.driver,
    this.vehicle,
    required this.tickets,
    required this.assignments,
    this.cleaningAreas = const {},
    this.polygons = const {},
  });
}

final driverControllerProvider =
    StateNotifierProvider<DriverController, DriverState>((ref) {
  final authState = ref.watch(authNotifierProvider);
  final driverId = authState.user?.id; // driverId из JWT токена
  final organizationId = authState.user?.organizationId;

  return DriverController(
    operationsRepository: ref.watch(operationsRepositoryProvider),
    organizationsRepository: ref.watch(organizationsRepositoryProvider),
    driverId: driverId,
    organizationId: organizationId,
  );
});

class DriverController extends StateNotifier<DriverState> {
  DriverController({
    required OperationsRepository operationsRepository,
    required OrganizationsRepository organizationsRepository,
    String? driverId,
    String? organizationId,
  })  : _operationsRepository = operationsRepository,
        _organizationsRepository = organizationsRepository,
        _driverId = driverId,
        _organizationId = organizationId,
        super(DriverState.initial()) {
    _loadData();
  }

  final OperationsRepository _operationsRepository;
  final OrganizationsRepository _organizationsRepository;
  final String? _driverId;
  final String? _organizationId;

  Future<void> _loadData() async {
    state = state.copyWith(data: const AsyncLoading());
    state = state.copyWith(
      data: await AsyncValue.guard(() async {
        // Загружаем тикеты водителя
        List<Ticket> tickets = [];
        if (_driverId != null) {
          tickets = await _operationsRepository.loadTickets(
            driverId: _driverId,
          );
        }

        // Загружаем назначения для всех тикетов
        Map<String, List<TicketAssignment>> assignments = {};
        for (final ticket in tickets) {
          try {
            final ticketAssignments = await _operationsRepository.getTicketAssignments(ticket.id);
            // Фильтруем только назначения текущего водителя
            final driverAssignments = ticketAssignments
                .where((a) => a.driverId == _driverId && a.isActive)
                .toList();
            if (driverAssignments.isNotEmpty) {
              assignments[ticket.id] = driverAssignments;
            }
          } catch (e) {
            // Игнорируем ошибки
          }
        }

        // Находим текущий активный рейс (assignment со статусом NOT_STARTED или IN_WORK)
        Ticket? currentTicket;
        TicketAssignment? currentAssignment;
        for (final ticket in tickets) {
          final ticketAssignments = assignments[ticket.id] ?? [];
          for (final assignment in ticketAssignments) {
            if (assignment.assignmentStatus == AssignmentStatus.notStarted ||
                assignment.assignmentStatus == AssignmentStatus.inWork) {
              currentTicket = ticket;
              currentAssignment = assignment;
              break;
            }
          }
          if (currentTicket != null) break;
        }

        // Загружаем информацию о водителе и технике
        // Для DRIVER роли используем методы получения по ID вместо списков
        Driver? driver;
        Vehicle? vehicle;
        Organization? contractor;

        if (_driverId != null) {
          try {
            // Для DRIVER роли используем getDriver(id) вместо loadDrivers()
            // GET /roles/drivers/:id доступен для водителя (согласно документации)
            driver = await _organizationsRepository.getDriver(_driverId!);
          } catch (e) {
            // Игнорируем ошибки (возможно, водитель еще не создан в системе)
            debugPrint('DriverController: Failed to load driver: $e');
          }
        }

        // Загружаем технику из назначения или из водителя
        if (currentAssignment?.vehicleId != null) {
          try {
            // Для DRIVER роли используем getVehicle(id) вместо loadVehicles()
            // GET /roles/vehicles/:id должен быть доступен для водителя
            vehicle = await _organizationsRepository.getVehicle(currentAssignment!.vehicleId!);
          } catch (e) {
            // Игнорируем ошибки
            debugPrint('DriverController: Failed to load vehicle from assignment: $e');
          }
        }

        // Если техника не загружена из назначения, пытаемся загрузить из водителя
        // (если у водителя есть привязанная техника)
        if (vehicle == null && driver != null) {
          // TODO: Добавить vehicleId в модель Driver, если это поле есть в API
          // Пока оставляем как есть
        }

        // Загружаем организацию подрядчика по ID (если есть organizationId в JWT токене)
        if (_organizationId != null) {
          try {
            // Для DRIVER роли используем getOrganization(id) вместо loadOrganizations()
            // GET /roles/organizations/:id должен быть доступен для водителя
            contractor = await _organizationsRepository.getOrganization(_organizationId!);
          } catch (e) {
            // Игнорируем ошибки (возможно, организация не найдена)
            debugPrint('DriverController: Failed to load organization: $e');
          }
        }

        // Если организация не загружена, пытаемся получить из водителя
        if (contractor == null && driver?.contractorId != null) {
          try {
            contractor = await _organizationsRepository.getOrganization(driver!.contractorId);
          } catch (e) {
            debugPrint('DriverController: Failed to load organization from driver: $e');
          }
        }

        // Загружаем участки уборки для текущего тикета
        Map<String, CleaningArea> cleaningAreas = {};
        if (currentTicket != null) {
          try {
            final area = await _operationsRepository.getCleaningArea(currentTicket.cleaningAreaId);
            cleaningAreas[currentTicket.cleaningAreaId] = area;
          } catch (e) {
            debugPrint('DriverController: Failed to load cleaning area: $e');
          }
        }

        // Загружаем полигоны из рейсов тикета (если есть)
        // Полигон определяется по рейсам, связанным с тикетом
        // Для упрощения, можно получить полигон из контракта или из первого рейса
        Map<String, model.Polygon> polygons = {};
        // TODO: Загрузить полигон из рейсов тикета или из контракта
        // Пока оставляем пустым, так как полигон определяется динамически по рейсам

        // Обновляем состояние с текущим рейсом
        state = state.copyWith(
          currentTicket: currentTicket,
          currentAssignment: currentAssignment,
        );

        return DriverData(
          contractor: contractor,
          driver: driver,
          vehicle: vehicle,
          tickets: tickets,
          assignments: assignments,
          cleaningAreas: cleaningAreas,
          polygons: polygons,
        );
      }),
    );
  }

  Future<void> refresh() => _loadData();

  /// Начать рейс (перевести assignment в IN_WORK)
  Future<void> startTrip(String assignmentId) async {
    try {
      await _operationsRepository.markAssignmentInWork(assignmentId);
      await _loadData();
    } catch (e) {
      rethrow;
    }
  }

  /// Завершить рейс (перевести assignment в COMPLETED)
  Future<void> completeTrip(String assignmentId) async {
    try {
      await _operationsRepository.markAssignmentCompleted(assignmentId);
      await _loadData();
    } catch (e) {
      rethrow;
    }
  }
}

