  import 'package:akimat_project/core/navbar/drawer_mobile.dart';
import 'package:akimat_project/core/navbar/header_navbar.dart';
import 'package:akimat_project/core/navbar/navbar_widgets_provider.dart';
import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/core/ui/app_textstyle.dart';
import 'package:akimat_project/modules/auth/src/controller/auth_notifier.dart';
import 'package:akimat_project/modules/dashboard/src/controller/driver_controller.dart';
import 'package:akimat_project/modules/dashboard/src/model/areas/cleaning_area.dart';
import 'package:akimat_project/modules/dashboard/src/model/polygons/polygon.dart' as model;
import 'package:akimat_project/modules/dashboard/src/model/tickets/ticket_assignment.dart';
import 'package:akimat_project/modules/dashboard/src/repository/operations_repository.dart';
import 'package:akimat_project/modules/dashboard/src/repository/operations_repository_impl.dart';
import 'package:akimat_project/modules/dashboard/src/services/driver_location_service.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/tickets/tickets_page.dart';
import 'package:akimat_project/modules/trips/src/ui/widgets/driver_current_trip_card.dart';
import 'package:akimat_project/modules/trips/src/ui/widgets/driver_map_widget.dart';
import 'package:akimat_project/modules/trips/src/ui/widgets/driver_ticket_details_dialog.dart';
import 'package:akimat_project/modules/trips/src/ui/widgets/driver_tickets_list.dart';
import 'package:akimat_project/services/operations/module.dart';
import 'package:akimat_project/services/tickets/module.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

final driverLocationServiceProvider = Provider<DriverLocationService>((ref) {
  final operationsRepo = OperationsRepositoryImpl(
    services: ref.watch(operationsServicesProvider),
    ticketsServices: ref.watch(ticketsServicesProvider),
    userRole: null, // Не используется для отправки локации
  );
  return DriverLocationService(repository: operationsRepo);
});

class DriverHome extends ConsumerStatefulWidget {
  const DriverHome({super.key});

  @override
  ConsumerState<DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends ConsumerState<DriverHome> with SingleTickerProviderStateMixin {
  bool _isLocationTracking = false;
  String? _locationStatus;
  Position? _currentPosition;
  late TabController _tabController;
  String? _lastTabParam; // Отслеживаем последний tab параметр для предотвращения циклов
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>(); // Для мобильного drawer
  VoidCallback? _routeListener; // Слушатель изменений роута
  bool _isSyncing = false; // Флаг для предотвращения одновременной синхронизации
  Timer? _refreshTimer; // Таймер для периодического обновления данных

  void _onTabControllerChanged() {
    // Этот слушатель больше не обновляет URL, так как URL обновляется кнопками навбара
    // Это предотвращает циклы и двойные переключения
    // URL -> TabController синхронизация происходит через routeListener и didChangeDependencies
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Инициализируем _lastTabParam пустой строкой, чтобы избежать проблем с null
    _lastTabParam = '';
    
    // НЕ добавляем слушатель TabController, который обновляет URL
    // URL обновляется кнопками навбара, а TabController синхронизируется из URL
    // Это предотвращает циклы и двойные переключения
    
    // Начинаем отслеживание GPS-локации при входе
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startLocationTracking();
      _getCurrentPosition();
      // Инициализируем _lastTabParam из текущего роута
      try {
        final router = GoRouter.of(context);
        final uri = router.routerDelegate.currentConfiguration.uri;
        _lastTabParam = uri.queryParameters['tab'] ?? '';
      } catch (e) {
        _lastTabParam = '';
      }
      _syncTabFromRoute();
      // Добавляем слушатель изменений роута после первой отрисовки
      _setupRouteListener();
      // Автообновление отключено по запросу пользователя
      // _startPeriodicRefresh();
    });
  }
  
  /// Настраивает слушатель изменений роута для синхронизации вкладок
  void _setupRouteListener() {
    if (!mounted || _routeListener != null) return; // Не создаем слушатель дважды
    
    try {
      final router = GoRouter.of(context);
      // Создаем слушатель, который будет вызываться при изменении роута
      _routeListener = () {
        if (mounted && !_tabController.indexIsChanging) {
          final uri = router.routerDelegate.currentConfiguration.uri;
          final newTabParam = uri.queryParameters['tab'] ?? '';
          
          // Нормализуем для сравнения
          final normalizedNew = newTabParam.isEmpty ? 'current' : newTabParam;
          final normalizedLast = (_lastTabParam?.isEmpty ?? true) ? 'current' : _lastTabParam!;
          
          if (normalizedNew != normalizedLast) {
            debugPrint('DriverHome: Route listener detected tab change: "$_lastTabParam" -> "$newTabParam"');
            // Обновляем _lastTabParam ПЕРЕД синхронизацией, чтобы избежать повторных вызовов
            _lastTabParam = newTabParam;
            // Синхронизируем сразу, без задержек, для мгновенного переключения
            if (mounted && !_tabController.indexIsChanging) {
              _syncTabFromRoute();
            }
          }
        }
      };
      // Добавляем слушатель к routerDelegate
      router.routerDelegate.addListener(_routeListener!);
      debugPrint('DriverHome: Route listener set up successfully');
    } catch (e) {
      debugPrint('DriverHome: Error setting up route listener: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Синхронизируем вкладку при изменении зависимостей (включая роут)
    // Это обеспечивает синхронизацию при клике на кнопки навбара
    // Проверяем, изменился ли tab параметр
    try {
      final router = GoRouter.of(context);
      final uri = router.routerDelegate.currentConfiguration.uri;
      final currentTabParam = uri.queryParameters['tab'] ?? '';
      
      // Нормализуем: пустая строка означает 'current'
      final normalizedCurrent = currentTabParam.isEmpty ? 'current' : currentTabParam;
      final normalizedLast = (_lastTabParam?.isEmpty ?? true) ? 'current' : _lastTabParam!;
      
      if (normalizedCurrent != normalizedLast) {
        debugPrint('DriverHome: didChangeDependencies detected tab change: "$_lastTabParam" -> "$currentTabParam"');
        // Обновляем _lastTabParam ПЕРЕД синхронизацией
        _lastTabParam = currentTabParam;
        // Синхронизируем сразу, без задержек, для мгновенного переключения
        // routeListener тоже может быть вызван, но проверка _lastTabParam предотвратит двойную синхронизацию
        if (mounted && !_tabController.indexIsChanging) {
          _syncTabFromRoute();
        }
      }
    } catch (e) {
      // Игнорируем ошибки
    }
  }

  /// Обновляет URL при переключении вкладки
  /// ВАЖНО: Этот метод больше не используется, так как URL обновляется кнопками навбара
  /// Оставлен для совместимости, но не вызывается
  void _updateRouteFromTab(int index) {
    // Метод больше не используется
    // URL обновляется кнопками навбара напрямую через context.go()
  }

  /// Синхронизирует вкладку с query параметром из роута
  void _syncTabFromRoute() {
    if (!mounted || _isSyncing) return;
    
    // Устанавливаем флаг, чтобы предотвратить одновременную синхронизацию
    _isSyncing = true;
    
    // Не блокируем синхронизацию, даже если идет анимация
    // Это важно для корректного переключения при быстрых кликах
    
    try {
      final router = GoRouter.of(context);
      final uri = router.routerDelegate.currentConfiguration.uri;
      final tab = uri.queryParameters['tab'] ?? '';
      
      // Нормализуем: пустая строка означает 'current'
      final normalizedTab = tab.isEmpty ? 'current' : tab;
      
      int tabIndex = 0; // По умолчанию первая вкладка (Текущий рейс)
      switch (normalizedTab) {
        case 'current':
          tabIndex = 0;
          break;
        case 'tickets':
          tabIndex = 1;
          break;
        case 'map':
          tabIndex = 2;
          break;
        default:
          tabIndex = 0; // Fallback на первую вкладку
          break;
      }
      
      // Обновляем вкладку только если она отличается от текущей
      if (_tabController.index != tabIndex) {
        debugPrint('DriverHome: Syncing tab to index $tabIndex (from route tab=$tab, normalized=$normalizedTab, current index=${_tabController.index}, lastTabParam=$_lastTabParam, indexIsChanging=${_tabController.indexIsChanging})');
        // Используем прямое присваивание index для мгновенного переключения
        // Это предотвращает циклы и проблемы с синхронизацией
        final oldIndex = _tabController.index;
        
        // Если идет анимация, останавливаем её и переключаемся сразу
        if (_tabController.indexIsChanging) {
          debugPrint('DriverHome: Tab is changing, forcing immediate switch to index $tabIndex');
        }
        
        _tabController.index = tabIndex;
        
        // Проверяем, что переключение произошло
        if (_tabController.index == tabIndex) {
          debugPrint('DriverHome: Tab synced successfully from index $oldIndex to $tabIndex');
        } else {
          debugPrint('DriverHome: WARNING - Tab sync failed! Expected index $tabIndex but got ${_tabController.index}');
          // Повторяем попытку через небольшую задержку
          Future.delayed(const Duration(milliseconds: 50), () {
            if (mounted && _tabController.index != tabIndex) {
              debugPrint('DriverHome: Retrying tab sync to index $tabIndex');
              _tabController.index = tabIndex;
            }
          });
        }
      } else {
        debugPrint('DriverHome: Tab already at correct index $tabIndex, skipping sync');
      }
    } catch (e) {
      debugPrint('Error syncing tab from route: $e');
    } finally {
      // Сбрасываем флаг после завершения синхронизации
      _isSyncing = false;
    }
  }

  @override
  void dispose() {
    // НЕ удаляем слушатель TabController, так как мы его не добавляли
    _tabController.dispose();
    // Удаляем слушатель роутера
    if (_routeListener != null) {
      try {
        final router = GoRouter.of(context);
        router.routerDelegate.removeListener(_routeListener!);
      } catch (e) {
        // Игнорируем ошибки
      }
      _routeListener = null;
    }
    // Останавливаем периодическое обновление
    _refreshTimer?.cancel();
    _refreshTimer = null;
    // Останавливаем отслеживание при выходе
    final service = ref.read(driverLocationServiceProvider);
    service.stopTracking();
    super.dispose();
  }

  Future<void> _getCurrentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      // Игнорируем ошибки
    }
  }

  Future<void> _startLocationTracking() async {
    try {
      final service = ref.read(driverLocationServiceProvider);
      await service.startTracking();
      setState(() {
        _isLocationTracking = true;
        _locationStatus = 'Отслеживание активно';
      });
      // Получаем текущую позицию
      _getCurrentPosition();
    } catch (e) {
      setState(() {
        _isLocationTracking = false;
        _locationStatus = 'Ошибка: $e';
      });
    }
  }

  Future<void> _sendCurrentLocation() async {
    try {
      final service = ref.read(driverLocationServiceProvider);
      await service.sendCurrentLocation();
      setState(() {
        _locationStatus = 'Локация отправлена';
      });
    } catch (e) {
      setState(() {
        _locationStatus = 'Ошибка отправки: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final driverState = ref.watch(driverControllerProvider);
    final driverController = ref.read(driverControllerProvider.notifier);
    
    // Используем GoRouter для отслеживания изменений роута
    // Это заставит виджет перестраиваться при изменении роута
    final router = GoRouter.of(context);
    final uri = router.routerDelegate.currentConfiguration.uri;
    // Используем uri как зависимость для принудительного обновления навбара
    final routeKey = uri.toString();
    
    // Синхронизация вкладок происходит через didChangeDependencies и routeListener
    // Не нужно дублировать логику здесь, чтобы избежать конфликтов

    return Scaffold(
      key: _scaffoldKey, // Для мобильного drawer
      // Убираем AppBar - навигация теперь только в HeaderNavbar
      appBar: null,
      // Drawer для мобильной версии (навигация через боковое меню)
      drawer: !kIsWeb ? const DrawerMobile() : null,
      body: Column(
        children: [
          // Единая навигация в HeaderNavbar (для веб и мобильной версии)
          // Используем getDefaultWebWidgets/getDefaultMobileWidgets напрямую,
          // они уже содержат правильную навигацию для водителя
          // Key с routeKey заставляет перестраиваться при изменении роута
          HeaderNavbar(
            key: ValueKey('driver-navbar-$routeKey'),
            webWidgets: kIsWeb ? NavbarWidgetsProvider.getDefaultWebWidgets(context) : null,
            mobileWidgets: !kIsWeb ? NavbarWidgetsProvider.getDefaultMobileWidgets(context) : null,
            scaffoldKey: !kIsWeb ? _scaffoldKey : null,
          ),
          // Контент вкладок (работает через TabBarView для синхронизации с навигацией)
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Вкладка: Текущее задание
                _buildCurrentTripTab(driverState, driverController, user),
                // Вкладка: Мои задания (тикеты с активными назначениями)
                _buildMyTicketsTab(driverState),
                // Вкладка: Карта
                _buildMapTab(driverState),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentTripTab(
    DriverState driverState,
    DriverController driverController,
    user,
  ) {
    return driverState.data.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Ошибка загрузки данных: $error',
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => driverController.refresh(),
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
      data: (data) {
        final currentTicket = driverState.currentTicket;
        final currentAssignment = driverState.currentAssignment;

        // Отладочная информация
        debugPrint('DriverHome._buildCurrentTripTab: currentTicket=${currentTicket?.id}, currentAssignment=${currentAssignment?.id}');
        debugPrint('DriverHome._buildCurrentTripTab: tickets count=${data.tickets.length}, assignments count=${data.assignments.length}');

        if (currentTicket == null || currentAssignment == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 64,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Нет активных заданий',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Подождите, пока подрядчик назначит вам задание',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                // Отладочная информация
                if (data.tickets.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Отладка: Загружено тикетов: ${data.tickets.length}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    'Отладка: Назначений: ${data.assignments.length}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              // Информация о водителе, организации и технике (всегда видна)
              _buildDriverInfoCard(data, user),
              // Карточка текущего задания
              DriverCurrentTripCard(
                ticket: currentTicket,
                assignment: currentAssignment,
                areaName: data.cleaningAreas[currentTicket.cleaningAreaId]?.name ?? 'Участок ${currentTicket.cleaningAreaId.substring(0, 8)}',
                polygonName: data.polygons.isNotEmpty ? data.polygons.values.first.name : null,
                vehicle: data.vehicle,
                onShowDetails: () async {
                  try {
                    // Загружаем детали тикета
                    final ticketDetails = await driverController.getTicketDetails(currentTicket.id);
                    if (mounted) {
                      await DriverTicketDetailsDialog.show(
                        context: context,
                        ticket: currentTicket,
                        assignment: currentAssignment,
                        areaName: data.cleaningAreas[currentTicket.cleaningAreaId]?.name,
                        polygonName: data.polygons.isNotEmpty ? data.polygons.values.first.name : null,
                        metrics: ticketDetails['metrics'] as Map<String, dynamic>?,
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Ошибка загрузки деталей тикета: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                onStartTrip: () async {
                  try {
                    // Переводим assignment в IN_WORK (статус IN_PROGRESS)
                    await driverController.startTrip(currentAssignment.id);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Рейс начат. Статус: IN_PROGRESS. Машина на карте стала зелёной.'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 3),
                        ),
                      );
                      // Обновляем данные для обновления карты
                      await driverController.refresh();
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Ошибка при начале рейса: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                onCompleteTrip: () async {
                  try {
                    // Переводим assignment в COMPLETED
                    // Примечание: Рейс также может быть завершён автоматически после выезда с полигона
                    // (фиксируется камерами LANDFILL на бэкенде)
                    await driverController.completeTrip(currentAssignment.id);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Рейс завершён. Статус: COMPLETED.'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 3),
                        ),
                      );
                      // Обновляем данные
                      await driverController.refresh();
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Ошибка при завершении рейса: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMyTicketsTab(DriverState driverState) {
    return driverState.data.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Ошибка загрузки данных: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(driverControllerProvider.notifier).refresh(),
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
      data: (data) {
        final authState = ref.read(authNotifierProvider);
        final user = authState.user;
        final driverController = ref.read(driverControllerProvider.notifier);
        
        return Column(
          children: [
            // Информация о водителе, организации и технике (всегда видна)
            _buildDriverInfoCard(data, user),
            // Список тикетов водителя с кнопками "Начать работу"
            Expanded(
              child: DriverTicketsList(
                tickets: data.tickets,
                assignments: data.assignments,
                cleaningAreas: data.cleaningAreas,
                driverController: driverController,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMapTab(DriverState driverState) {
    return driverState.data.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Ошибка: $error'),
      ),
      data: (data) {
        final currentTicket = driverState.currentTicket;
        final currentLocation = _currentPosition != null
            ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
            : const LatLng(54.8667, 69.1500); // Петропавловск по умолчанию

        // Загружаем участок уборки из данных
        // ВАЖНО: Участок должен отображаться на карте для текущего тикета или первого доступного тикета
        CleaningArea? cleaningArea;
        
        // Сначала пытаемся взять участок из текущего тикета
        if (currentTicket != null) {
          cleaningArea = data.cleaningAreas[currentTicket.cleaningAreaId];
          if (cleaningArea != null) {
            debugPrint('DriverHome._buildMapTab: Found cleaning area "${cleaningArea.name}" (${cleaningArea.id}) for current ticket ${currentTicket.id}, geometry points: ${cleaningArea.geometry.length}');
            if (cleaningArea.geometry.isEmpty) {
              debugPrint('DriverHome._buildMapTab: ⚠ WARNING - Cleaning area has empty geometry, will not be displayed on map');
            }
          } else {
            debugPrint('DriverHome._buildMapTab: ⚠ WARNING - No cleaning area found for current ticket ${currentTicket.id}, cleaningAreaId: ${currentTicket.cleaningAreaId}');
            debugPrint('DriverHome._buildMapTab: Available cleaning areas: ${data.cleaningAreas.keys.toList()}');
          }
        }
        
        // Если нет участка из текущего тикета, берем участок из первого доступного тикета
        if (cleaningArea == null && data.tickets.isNotEmpty) {
          for (final ticket in data.tickets) {
            final area = data.cleaningAreas[ticket.cleaningAreaId];
            if (area != null && area.geometry.isNotEmpty) {
              cleaningArea = area;
              debugPrint('DriverHome._buildMapTab: Using cleaning area "${cleaningArea.name}" (${cleaningArea.id}) from ticket ${ticket.id} (no current ticket)');
              break;
            }
          }
        }
        
        // Если все еще нет участка, но есть загруженные участки, берем первый
        if (cleaningArea == null && data.cleaningAreas.isNotEmpty) {
          final firstArea = data.cleaningAreas.values.firstWhere(
            (area) => area.geometry.isNotEmpty,
            orElse: () => data.cleaningAreas.values.first,
          );
          cleaningArea = firstArea;
          debugPrint('DriverHome._buildMapTab: Using first available cleaning area "${cleaningArea.name}" (${cleaningArea.id})');
        }
        
        if (cleaningArea == null) {
          debugPrint('DriverHome._buildMapTab: ⚠ WARNING - No cleaning area available to display on map');
          debugPrint('DriverHome._buildMapTab: Tickets count: ${data.tickets.length}');
          debugPrint('DriverHome._buildMapTab: Cleaning areas count: ${data.cleaningAreas.length}');
        }

        // Полигоны для отображения на карте (привязанные к подрядчику)
        // ВАЖНО: Полигоны загружаются всегда, не только после начала работы
        // API /polygons?only_active=true возвращает только полигоны подрядчика водителя
        final polygonsList = data.polygons.values.toList();
        debugPrint('DriverHome._buildMapTab: Loaded ${polygonsList.length} polygons for driver');
        
        // Для обратной совместимости оставляем первый полигон
        model.Polygon? polygon;
        if (polygonsList.isNotEmpty) {
          polygon = polygonsList.first;
          debugPrint('DriverHome._buildMapTab: Using polygon "${polygon.name}" (${polygon.id}) for map display');
          if (polygonsList.length > 1) {
            debugPrint('DriverHome._buildMapTab: Note: ${polygonsList.length} polygons available, all will be displayed on map');
          }
        } else {
          debugPrint('DriverHome._buildMapTab: ⚠ WARNING - No polygons available for driver');
        }

        // Проверяем, находится ли водитель в зоне участка
        bool isInArea = false;
        if (cleaningArea != null && cleaningArea.geometry.isNotEmpty && _currentPosition != null) {
          isInArea = _isPointInPolygon(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            cleaningArea.geometry,
          );
        }

        // Проверяем, находится ли водитель в зоне любого полигона
        bool isInPolygon = false;
        if (_currentPosition != null && polygonsList.isNotEmpty) {
          // Проверяем все полигоны подрядчика
          for (final p in polygonsList) {
            if (p.geometry.isNotEmpty) {
              final inThisPolygon = _isPointInPolygon(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
                p.geometry,
              );
              if (inThisPolygon) {
                isInPolygon = true;
                debugPrint('DriverHome._buildMapTab: Driver is inside polygon "${p.name}" (${p.id})');
                break;
              }
            }
          }
        } else if (polygon != null && polygon.geometry.isNotEmpty && _currentPosition != null) {
          // Fallback для обратной совместимости
          isInPolygon = _isPointInPolygon(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            polygon.geometry,
          );
        }

        // Определяем, находится ли машина в работе
        final isVehicleInWork = driverState.currentAssignment?.assignmentStatus == AssignmentStatus.inWork;
        
        final authState = ref.read(authNotifierProvider);
        final user = authState.user;

        return Column(
          children: [
            // Информация о водителе, организации и технике (всегда видна)
            _buildDriverInfoCard(data, user),
            // Карта
            Expanded(
              child: DriverMapWidget(
                currentLocation: currentLocation,
                cleaningArea: cleaningArea,
                polygon: polygon, // Для обратной совместимости
                polygons: polygonsList, // Передаем все полигоны подрядчика
                isInArea: isInArea,
                isInPolygon: isInPolygon,
                isVehicleInWork: isVehicleInWork,
              ),
            ),
          ],
        );
      },
    );
  }

  /// Виджет с информацией о водителе, организации и технике
  Widget _buildDriverInfoCard(DriverData data, user) {
    return Container(
      margin: const EdgeInsets.all(AppPadding.normal),
      padding: const EdgeInsets.all(AppPadding.large),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSize.cardRadius),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppPadding.small),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSize.smallRadius),
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppPadding.normal),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Водитель',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.driver?.fullName ?? user?.phone ?? 'Неизвестно',
                      style: AppTextStyles.title2,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (data.contractor != null) ...[
            const SizedBox(height: AppPadding.large),
            const Divider(),
            const SizedBox(height: AppPadding.normal),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppPadding.small),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSize.smallRadius),
                  ),
                  child: const Icon(
                    Icons.business,
                    color: Colors.green,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppPadding.normal),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Организация (подрядчик)',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data.contractor!.name,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          if (data.vehicle != null) ...[
            const SizedBox(height: AppPadding.large),
            const Divider(),
            const SizedBox(height: AppPadding.normal),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppPadding.small),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSize.smallRadius),
                  ),
                  child: const Icon(
                    Icons.local_shipping,
                    color: Colors.orange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppPadding.normal),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Привязанная техника',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${data.vehicle!.brand} ${data.vehicle!.model}',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Гос. номер: ${data.vehicle!.plateNumber}',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Запускает периодическое обновление данных для автоматического обнаружения завершения рейса
  /// после выезда с полигона (фиксируется камерами LANDFILL на бэкенде)
  /// Также обновляет данные для обнаружения новых назначений от подрядчика
  void _startPeriodicRefresh() {
    // Обновляем данные каждые 15 секунд
    // - Если есть активный рейс (IN_WORK) - для обнаружения завершения
    // - Если нет активного рейса - для обнаружения новых назначений от подрядчика
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      final driverState = ref.read(driverControllerProvider);
      final currentAssignment = driverState.currentAssignment;
      
      // Обновляем данные:
      // 1. Если есть активный рейс (IN_WORK) - для обнаружения завершения
      // 2. Если нет текущего рейса - для обнаружения новых назначений от подрядчика
      final shouldRefresh = currentAssignment?.assignmentStatus == AssignmentStatus.inWork ||
                            currentAssignment == null;
      
      if (shouldRefresh) {
        debugPrint('DriverHome: Periodic refresh - checking for updates');
        ref.read(driverControllerProvider.notifier).refresh();
      }
    });
  }

  /// Проверяет, находится ли точка внутри полигона (алгоритм Ray Casting)
  bool _isPointInPolygon(double lat, double lon, List<List<double>> polygon) {
    if (polygon.isEmpty) return false;

    bool inside = false;
    int j = polygon.length - 1;

    for (int i = 0; i < polygon.length; i++) {
      final xi = polygon[i][0]; // longitude
      final yi = polygon[i][1]; // latitude
      final xj = polygon[j][0]; // longitude
      final yj = polygon[j][1]; // latitude

      final intersect = ((yi > lat) != (yj > lat)) &&
          (lon < (xj - xi) * (lat - yi) / (yj - yi) + xi);
      if (intersect) inside = !inside;
      j = i;
    }

    return inside;
  }
}
