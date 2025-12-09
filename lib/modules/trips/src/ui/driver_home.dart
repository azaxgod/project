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
import 'package:akimat_project/services/operations/module.dart';
import 'package:akimat_project/services/tickets/module.dart';
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

  void _onTabControllerChanged() {
    // Обновляем URL только когда анимация завершена
    if (!_tabController.indexIsChanging && mounted) {
      final index = _tabController.index;
      debugPrint('DriverHome: TabController changed to index: $index');
      // Обновляем URL при изменении TabController (асинхронно, чтобы не блокировать)
      Future.microtask(() {
        if (mounted && _tabController.index == index) {
          _updateRouteFromTab(index);
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Слушаем изменения TabController для синхронизации с URL
    _tabController.addListener(_onTabControllerChanged);
    
    // Начинаем отслеживание GPS-локации при входе
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startLocationTracking();
      _getCurrentPosition();
      _syncTabFromRoute();
      // Добавляем слушатель изменений роута после первой отрисовки
      _setupRouteListener();
    });
  }
  
  /// Настраивает слушатель изменений роута для синхронизации вкладок
  void _setupRouteListener() {
    if (!mounted || _routeListener != null) return; // Не создаем слушатель дважды
    
    try {
      final router = GoRouter.of(context);
      // Создаем слушатель, который будет вызываться при изменении роута
      _routeListener = () {
        if (mounted) {
          final uri = router.routerDelegate.currentConfiguration.uri;
          final newTabParam = uri.queryParameters['tab'] ?? '';
          if (newTabParam != _lastTabParam) {
            debugPrint('DriverHome: Route listener detected tab change: "$_lastTabParam" -> "$newTabParam"');
            _lastTabParam = newTabParam;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _syncTabFromRoute();
              }
            });
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
      
      if (currentTabParam != _lastTabParam) {
        _lastTabParam = currentTabParam;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            debugPrint('DriverHome: Syncing tab from didChangeDependencies (tab=$currentTabParam)');
            _syncTabFromRoute();
          }
        });
      }
    } catch (e) {
      // Игнорируем ошибки
    }
  }

  /// Обновляет URL при переключении вкладки
  void _updateRouteFromTab(int index) {
    if (!mounted) return;
    
    String tabParam = 'current';
    switch (index) {
      case 0:
        tabParam = 'current';
        break;
      case 1:
        tabParam = 'tickets';
        break;
      case 2:
        tabParam = 'map';
        break;
    }
    
    // Если URL уже правильный, не обновляем
    try {
      final currentUri = GoRouter.of(context).routerDelegate.currentConfiguration.uri;
      final currentTab = currentUri.queryParameters['tab'] ?? '';
      if (currentTab == tabParam) {
        debugPrint('DriverHome: URL already correct, skipping update');
        return;
      }
    } catch (e) {
      // Игнорируем ошибки проверки
    }
    
    try {
      // Обновляем _lastTabParam чтобы избежать лишней синхронизации
      _lastTabParam = tabParam;
      
      // Обновляем URL
      final newRoute = '/driver?tab=$tabParam';
      debugPrint('DriverHome: Updating route to $newRoute (from tab index $index)');
      
      // Используем go для обновления URL
      final router = GoRouter.of(context);
      router.go(newRoute);
    } catch (e) {
      debugPrint('Error updating route from tab: $e');
    }
  }

  /// Синхронизирует вкладку с query параметром из роута
  void _syncTabFromRoute() {
    if (!mounted) return;
    
    try {
      final uri = GoRouter.of(context).routerDelegate.currentConfiguration.uri;
      final tab = uri.queryParameters['tab'];
      
      int tabIndex = 0; // По умолчанию первая вкладка (Текущий рейс)
      switch (tab) {
        case 'current':
        case null:
        case '':
          tabIndex = 0;
          break;
        case 'tickets':
          tabIndex = 1;
          break;
        case 'map':
          tabIndex = 2;
          break;
      }
      
      // Обновляем вкладку только если она отличается от текущей
      if (_tabController.index != tabIndex) {
        debugPrint('DriverHome: Syncing tab to index $tabIndex (from route tab=$tab, current index=${_tabController.index}, isChanging=${_tabController.indexIsChanging})');
        // Используем animateTo только если не идет анимация
        if (!_tabController.indexIsChanging) {
          // Временно отключаем слушатель, чтобы избежать цикла
          _tabController.removeListener(_onTabControllerChanged);
          _tabController.animateTo(tabIndex);
          // Включаем слушатель обратно после небольшой задержки
          Future.delayed(const Duration(milliseconds: 150), () {
            if (mounted) {
              _tabController.addListener(_onTabControllerChanged);
            }
          });
        } else {
          // Если идет анимация, ждем её завершения и синхронизируем снова
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              _syncTabFromRoute();
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error syncing tab from route: $e');
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabControllerChanged);
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
    
    // Слушаем изменения роута через GoRouter и синхронизируем вкладку
    final router = GoRouter.of(context);
    final uri = router.routerDelegate.currentConfiguration.uri;
    final currentTabParam = uri.queryParameters['tab'] ?? '';
    
    // Всегда синхронизируем вкладку с URL при изменении tab параметра
    // Это обеспечивает синхронизацию при клике на кнопки навбара
    if (currentTabParam != _lastTabParam) {
      final previousTabParam = _lastTabParam;
      _lastTabParam = currentTabParam;
      debugPrint('DriverHome: Tab param changed from "$previousTabParam" to "$currentTabParam"');
      // Синхронизируем сразу после build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && currentTabParam == _lastTabParam) {
          debugPrint('DriverHome: Syncing tab from route in build (tab=$currentTabParam)');
          _syncTabFromRoute();
        }
      });
    } else if (_lastTabParam == null) {
      // Первая загрузка - синхронизируем
      _lastTabParam = currentTabParam;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          debugPrint('DriverHome: Initial sync tab from route (tab=$currentTabParam)');
          _syncTabFromRoute();
        }
      });
    }

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
          HeaderNavbar(
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
        
        return Column(
          children: [
            // Информация о водителе, организации и технике (всегда видна)
            _buildDriverInfoCard(data, user),
            // Список тикетов водителя (использует GET /driver/tickets через TicketsController)
            Expanded(
              child: TicketsPage(
                scaffoldKey: GlobalKey<ScaffoldState>(),
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
        CleaningArea? cleaningArea;
        if (currentTicket != null) {
          cleaningArea = data.cleaningAreas[currentTicket.cleaningAreaId];
        }

        // Полигон загружается из контракта тикета (через DriverController)
        model.Polygon? polygon;
        if (data.polygons.isNotEmpty) {
          // Используем первый доступный полигон из контракта
          polygon = data.polygons.values.first;
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
                polygon: polygon,
                isInArea: isInArea,
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
