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
import 'package:akimat_project/modules/dashboard/src/repository/contracts_repository.dart';
import 'package:akimat_project/modules/dashboard/src/repository/contracts_repository_impl.dart';
import 'package:akimat_project/modules/dashboard/src/repository/operations_repository.dart';
import 'package:akimat_project/modules/dashboard/src/repository/organizations_repository.dart';
import 'package:akimat_project/services/contracts/module.dart';
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
    contractsRepository: ContractsRepositoryImpl(
      services: ref.watch(contractsServicesProvider),
    ),
    driverId: driverId,
    organizationId: organizationId,
  );
});

class DriverController extends StateNotifier<DriverState> {
  DriverController({
    required OperationsRepository operationsRepository,
    required OrganizationsRepository organizationsRepository,
    required ContractsRepository contractsRepository,
    String? driverId,
    String? organizationId,
  })  : _operationsRepository = operationsRepository,
        _organizationsRepository = organizationsRepository,
        _contractsRepository = contractsRepository,
        _driverId = driverId,
        _organizationId = organizationId,
        super(DriverState.initial()) {
    _loadData();
  }

  final OperationsRepository _operationsRepository;
  final OrganizationsRepository _organizationsRepository;
  final ContractsRepository _contractsRepository;
  final String? _driverId;
  final String? _organizationId;

  Future<void> _loadData() async {
    state = state.copyWith(data: const AsyncLoading());
    state = state.copyWith(
      data: await AsyncValue.guard(() async {
        // Загружаем тикеты водителя
        // ВАЖНО: Для роли водителя endpoint /driver/tickets автоматически определяет водителя из JWT токена
        // НЕ передаем driverId, так как сервер сам фильтрует по driver_id из токена
        debugPrint('DriverController._loadData: Loading tickets for driverId=$_driverId');
        List<Ticket> tickets = [];
        tickets = await _operationsRepository.loadTickets();
        debugPrint('DriverController._loadData: Loaded ${tickets.length} tickets');

        // Загружаем назначения для всех тикетов
        // ВАЖНО: Для водителя endpoint /driver/tickets/:id уже возвращает назначения, отфильтрованные по driver_id из JWT токена
        // Поэтому мы принимаем все активные назначения, которые вернул бэкенд
        Map<String, List<TicketAssignment>> assignments = {};
        for (final ticket in tickets) {
          try {
            final ticketAssignments = await _operationsRepository.getTicketAssignments(ticket.id);
            debugPrint('DriverController._loadData: Ticket ${ticket.id} has ${ticketAssignments.length} assignments from backend');
            
            // Фильтруем только активные назначения
            // Назначения уже отфильтрованы по водителю на бэкенде через /driver/tickets/:id
            final activeAssignments = ticketAssignments
                .where((a) {
                  if (!a.isActive) {
                    debugPrint('DriverController._loadData: Assignment ${a.id} filtered out: isActive=false');
                    return false;
                  }
                  // Логируем для отладки, но принимаем все активные назначения
                  debugPrint('DriverController._loadData: Assignment ${a.id}: driverId=${a.driverId}, isActive=${a.isActive}, status=${a.assignmentStatus}');
                  return true;
                })
                .toList();
            
            debugPrint('DriverController._loadData: Ticket ${ticket.id} has ${activeAssignments.length} active assignments');
            
            // Если назначения есть, добавляем их
            if (activeAssignments.isNotEmpty) {
              assignments[ticket.id] = activeAssignments;
            } else {
              debugPrint('DriverController._loadData: WARNING - Ticket ${ticket.id} has no active assignments');
              // Выводим все назначения для отладки
              for (final a in ticketAssignments) {
                debugPrint('DriverController._loadData:   - Assignment ${a.id}: driverId=${a.driverId}, isActive=${a.isActive}, status=${a.assignmentStatus}');
              }
            }
          } catch (e, stackTrace) {
            debugPrint('DriverController._loadData: Failed to load assignments for ticket ${ticket.id}: $e');
            debugPrint('DriverController._loadData: Stack trace: $stackTrace');
            // Не игнорируем ошибки полностью, но продолжаем загрузку других тикетов
          }
        }
        
        debugPrint('DriverController._loadData: Total assignments found: ${assignments.length} tickets with assignments');

        // Находим текущий активный рейс (assignment со статусом null, NOT_STARTED или IN_WORK)
        // ВАЖНО: Проверяем статус назначения, а не статус тикета
        // Даже если тикет отменен (CANCELLED), водитель может начать рейс, если назначение активно
        // Приоритет: IN_WORK > NOT_STARTED/null (берем первый активный рейс в работе, если есть)
        Ticket? currentTicket;
        TicketAssignment? currentAssignment;
        
        // Сначала ищем рейс в работе (IN_WORK)
        for (final ticket in tickets) {
          final ticketAssignments = assignments[ticket.id] ?? [];
          debugPrint('DriverController._loadData: Checking ticket ${ticket.id} (status=${ticket.status}) with ${ticketAssignments.length} assignments');
          
          for (final assignment in ticketAssignments) {
            final status = assignment.assignmentStatus;
            debugPrint('DriverController._loadData: Assignment ${assignment.id} has status: $status, isActive=${assignment.isActive}');
            
            // Приоритет: сначала ищем рейс в работе
            if (status == AssignmentStatus.inWork && assignment.isActive) {
              currentTicket = ticket;
              currentAssignment = assignment;
              debugPrint('DriverController._loadData: Found current trip IN_WORK: ticket=${ticket.id} (status=${ticket.status}), assignment=${assignment.id}');
              break;
            }
          }
          if (currentTicket != null) break;
        }
        
        // Если рейс в работе не найден, ищем рейс со статусом NOT_STARTED или null
        if (currentTicket == null) {
          for (final ticket in tickets) {
            final ticketAssignments = assignments[ticket.id] ?? [];
            
            for (final assignment in ticketAssignments) {
              final status = assignment.assignmentStatus;
              
              // Проверяем только статус назначения, не статус тикета
              // Водитель может начать рейс даже для отмененного тикета, если назначение активно
              if (assignment.isActive && 
                  (status == null || status == AssignmentStatus.notStarted)) {
                currentTicket = ticket;
                currentAssignment = assignment;
                debugPrint('DriverController._loadData: Found current trip NOT_STARTED: ticket=${ticket.id} (status=${ticket.status}), assignment=${assignment.id}, assignmentStatus=$status');
                break;
              }
            }
            if (currentTicket != null) break;
          }
        }
        
        if (currentTicket == null) {
          debugPrint('DriverController._loadData: No current trip found. Tickets: ${tickets.length}, Assignments: ${assignments.length}');
          // Детальная информация для отладки
          if (tickets.isEmpty) {
            debugPrint('DriverController._loadData: No tickets loaded - check if driver has assignments');
          } else {
            debugPrint('DriverController._loadData: Tickets loaded but no current assignment found');
            for (final ticket in tickets) {
              final ticketAssignments = assignments[ticket.id] ?? [];
              debugPrint('DriverController._loadData: Ticket ${ticket.id}: ${ticketAssignments.length} assignments');
              for (final assignment in ticketAssignments) {
                debugPrint('DriverController._loadData:   - Assignment ${assignment.id}: status=${assignment.assignmentStatus}, isActive=${assignment.isActive}');
              }
            }
          }
        } else {
          debugPrint('DriverController._loadData: Current trip found: ticket=${currentTicket.id}, assignment=${currentAssignment?.id}, status=${currentAssignment?.assignmentStatus}');
        }

        // Загружаем информацию о водителе и технике
        // ВАЖНО: Для начала рейса информация о водителе не нужна - она используется только для отображения
        // Убираем загрузку водителя, чтобы не делать лишний запрос к /roles/drivers/:id
        Driver? driver;
        Vehicle? vehicle;
        Organization? contractor;

        // Информация о водителе не загружается - не нужна для начала рейса
        // Если понадобится для отображения, можно загрузить позже по требованию
        debugPrint('DriverController._loadData: Skipping driver info loading - not needed for trip start');

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

        // Загружаем участки уборки для всех тикетов водителя
        Map<String, CleaningArea> cleaningAreas = {};
        for (final ticket in tickets) {
          if (!cleaningAreas.containsKey(ticket.cleaningAreaId)) {
            try {
              final area = await _operationsRepository.getCleaningArea(ticket.cleaningAreaId);
              cleaningAreas[ticket.cleaningAreaId] = area;
              debugPrint('DriverController._loadData: Loaded cleaning area ${area.name} (${area.id})');
            } catch (e) {
              debugPrint('DriverController._loadData: Failed to load cleaning area ${ticket.cleaningAreaId}: $e');
            }
          }
        }

        // Загружаем полигоны LANDFILL для отображения на карте
        // ВАЖНО: Водителю не нужны контракты, но нужны полигоны для карты
        // Загружаем все активные полигоны через loadPolygons
        Map<String, model.Polygon> polygons = {};
        try {
          // Загружаем все активные полигоны (включая LANDFILL)
          final allPolygons = await _operationsRepository.loadPolygons(onlyActive: true);
          debugPrint('DriverController._loadData: Loaded ${allPolygons.length} active polygons');
          
          // Добавляем все полигоны для отображения на карте
          for (final polygon in allPolygons) {
            polygons[polygon.id] = polygon;
            debugPrint('DriverController._loadData: Added polygon ${polygon.name} (${polygon.id}) for map');
          }
          
          debugPrint('DriverController._loadData: Total polygons loaded for map: ${polygons.length}');
        } catch (e) {
          debugPrint('DriverController._loadData: Failed to load polygons for map: $e');
          // Не критично - карта будет работать без полигонов, но с участками уборки
        }

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

  // ==================== Driver Appeals ====================

  /// Создать апелляцию водителя
  Future<Map<String, dynamic>> createAppeal({
    required String tripId,
    required String appealReasonType, // ERROR_CAMERA, TRANSIT_PATH, WRONG_ASSIGNMENT, OTHER
    required String comment,
  }) async {
    try {
      return await _operationsRepository.createDriverAppeal(
        tripId: tripId,
        appealReasonType: appealReasonType,
        comment: comment,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Получить список апелляций водителя
  Future<List<Map<String, dynamic>>> getAppeals({
    String? ticketId,
  }) async {
    try {
      return await _operationsRepository.getDriverAppeals(
        ticketId: ticketId,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Получить детали апелляции водителя
  Future<Map<String, dynamic>> getAppeal(String appealId) async {
    try {
      return await _operationsRepository.getDriverAppeal(appealId);
    } catch (e) {
      rethrow;
    }
  }

  /// Добавить комментарий к апелляции водителя
  Future<Map<String, dynamic>> addAppealComment({
    required String appealId,
    required String comment,
  }) async {
    try {
      return await _operationsRepository.addDriverAppealComment(
        appealId: appealId,
        comment: comment,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Получить комментарии к апелляции водителя
  Future<List<Map<String, dynamic>>> getAppealComments(String appealId) async {
    try {
      return await _operationsRepository.getDriverAppealComments(appealId);
    } catch (e) {
      rethrow;
    }
  }

  /// Получить детали тикета для водителя
  /// Возвращает TicketDetails с полями: ticket, metrics, assignments, trips, appeals
  Future<Map<String, dynamic>> getTicketDetails(String ticketId) async {
    try {
      // Используем getTicketAssignments, который уже загружает TicketDetails
      // и извлекаем полные данные через прямой вызов API
      final ticket = await _operationsRepository.getTicket(ticketId);
      final assignments = await _operationsRepository.getTicketAssignments(ticketId);
      
      // Загружаем метрики через отдельный запрос (если нужно)
      // Пока используем данные из тикета
      final metrics = {
        'total_trips': ticket.tripsCount ?? 0,
        'total_volume_m3': ticket.volumeShipped ?? 0.0,
        'has_violations': ticket.hasViolations,
      };
      
      return {
        'ticket': ticket,
        'metrics': metrics,
        'assignments': assignments,
      };
    } catch (e) {
      rethrow;
    }
  }
}

