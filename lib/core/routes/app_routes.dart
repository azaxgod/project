import 'package:akimat_project/core/storage/route_storage.dart';
import 'package:akimat_project/modules/analytics/src/ui/screen/analytics_areas_page.dart';
import 'package:akimat_project/modules/analytics/src/ui/screen/analytics_contracts_page.dart';
import 'package:akimat_project/modules/analytics/src/ui/screen/analytics_dashboard_page.dart';
import 'package:akimat_project/modules/analytics/src/ui/screen/analytics_drivers_page.dart';
import 'package:akimat_project/modules/analytics/src/ui/screen/analytics_performance_page.dart';
import 'package:akimat_project/modules/analytics/src/ui/screen/analytics_technical_page.dart';
import 'package:akimat_project/modules/analytics/src/ui/screen/analytics_trips_page.dart';
import 'package:akimat_project/modules/analytics/src/ui/screen/analytics_trip_detail_page.dart';
import 'package:akimat_project/modules/analytics/src/ui/screen/analytics_violations_page.dart';
import 'package:akimat_project/modules/analytics/src/ui/screen/analytics_vehicles_page.dart';
import 'package:akimat_project/modules/auth/src/controller/auth_notifier.dart';
import 'package:akimat_project/modules/auth/src/ui/login_page.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/akimat_cabinet/akimat_cabinet_page.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/akimat_dashboard/akimat_home.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/areas/areas_page.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/monitoring/monitoring_page.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/organizations_page.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/polygons/polygons_page.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/tickets/tickets_page.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/contracts/contracts_page.dart';
import 'package:akimat_project/modules/violations/src/ui/screen/violation_detail_page.dart';
import 'package:akimat_project/modules/violations/src/ui/screen/violations_page.dart';
import 'package:akimat_project/modules/trips/src/ui/driver_home.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/user_role.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = FutureProvider<GoRouter>((ref) async {
  // Ждем, пока Firebase Auth восстановит состояние (особенно важно на вебе)
  // Проверяем состояние асинхронно и ждем его восстановления
  int attempts = 0;
  const maxAttempts = 50; // Увеличено до 5 секунд для надежности
  while (attempts < maxAttempts) {
    final authState = ref.read(authNotifierProvider);
    
    // Если проверка завершена И пользователь восстановлен, выходим из цикла
    if (!authState.isCheckingToken && authState.user != null) {
      break;
    }
    
    // Если проверка завершена, но пользователь не найден - тоже выходим
    if (!authState.isCheckingToken && authState.user == null) {
      // Даем еще немного времени на восстановление (для веба)
      await Future.delayed(const Duration(milliseconds: 200));
      final retryState = ref.read(authNotifierProvider);
      if (!retryState.isCheckingToken) {
        break;
      }
    }
    
    // Ждем между попытками
    await Future.delayed(const Duration(milliseconds: 100));
    attempts++;
  }
  
  // Получаем финальное состояние после ожидания
  final finalAuthState = ref.read(authNotifierProvider);
  
  // Загружаем сохраненный роут асинхронно
  // ВАЖНО: initialLocation не поддерживает query параметры, поэтому используем только путь
  // Query параметры будут восстановлены через redirect
  // НИКОГДА не используем сохраненный роут для initialLocation если пользователь не авторизован
  String initialLocation = '/login';
  if (finalAuthState.user != null) {
    final savedRoute = await RouteStorage.getLastRoute();
    if (savedRoute != null && savedRoute != '/login' && !savedRoute.startsWith('/login')) {
      // Извлекаем путь без query параметров для initialLocation
      final routePath = savedRoute.contains('?') 
          ? savedRoute.split('?')[0] 
          : savedRoute;
      
      final validRoutes = [
        '/home', '/dashboard', '/organization', '/monitoring', '/areas', 
        '/polygons', '/tickets', '/kgu/contracts', '/analytics',
        '/analytics/trips', '/analytics/violations', '/analytics/performance',
        '/analytics/contracts', '/analytics/areas', '/analytics/drivers',
        '/analytics/vehicles', '/analytics/technical', '/violations', '/driver'
      ];
      // Проверяем динамические роуты (с параметрами)
      final isDynamicRoute = routePath.startsWith('/violations/') || 
                             routePath.startsWith('/analytics/trips/');
      if (validRoutes.contains(routePath) || isDynamicRoute) {
        // Используем только путь без query параметров для initialLocation
        initialLocation = routePath;
        debugPrint('GoRouter: Restoring saved route path: $routePath (full route: $savedRoute)');
      } else {
        debugPrint('GoRouter: Saved route not valid, using /dashboard: $savedRoute');
        initialLocation = '/dashboard';
      }
    } else {
      initialLocation = '/dashboard';
    }
  } else {
    // Пользователь не авторизован - всегда начинаем с /login
    debugPrint('GoRouter: User not authenticated, initial location: /login');
    initialLocation = '/login';
  }

  // Создаем ValueNotifier для обновления роутера при изменении auth state
  final authStateNotifier = ValueNotifier<AuthState>(finalAuthState);
  
  // Подписываемся на изменения auth state для обновления роутера
  ref.listen<AuthState>(authNotifierProvider, (previous, next) {
    if (authStateNotifier.value.user != next.user) {
      authStateNotifier.value = next;
      debugPrint('GoRouter: Auth state changed, user=${next.user != null}');
    }
  });

  // Убеждаемся, что initialLocation всегда валидный
  // Если пользователь не авторизован, всегда используем /login
  final validInitialLocation = finalAuthState.user == null 
      ? '/login'
      : (initialLocation == '/login' || 
         initialLocation.startsWith('/dashboard') || 
         initialLocation.startsWith('/home') ||
         initialLocation.startsWith('/organization') ||
         initialLocation.startsWith('/monitoring') ||
         initialLocation.startsWith('/analytics') ||
         initialLocation.startsWith('/driver')
         ? initialLocation 
         : '/dashboard');
  
  debugPrint('GoRouter: Creating router with initialLocation: $validInitialLocation (user=${finalAuthState.user != null})');
  
  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: validInitialLocation,
    refreshListenable: authStateNotifier,
    onException: (context, state, exception) {
      // Обработка ошибок навигации
      debugPrint('Navigation error: $exception');
      debugPrint('Navigation error state: ${state.uri}');
      debugPrint('Navigation error exception: $exception');
      // Не возвращаем значение из onException - это не поддерживается
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) {
          // Очищаем сохраненный роут при переходе на логин
          RouteStorage.clearLastRoute();
          return const LoginPage();
        },
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => AkimatCabinetPage(
          scaffoldKey: GlobalKey<ScaffoldState>(),
        ),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => AkimatCabinetPage(
          scaffoldKey: GlobalKey<ScaffoldState>(),
        ),
      ),
      GoRoute(
        path: '/organization',
        builder: (context, state) => OrganizationsPage(
          scaffoldKey: GlobalKey<ScaffoldState>(),
        ),
      ),
      GoRoute(
        path: '/monitoring',
        builder: (context, state) {
          debugPrint('=== GoRoute /monitoring builder called ===');
          try {
            debugPrint('GoRoute /monitoring: Creating MonitoringPage');
            final page = MonitoringPage(
              scaffoldKey: GlobalKey<ScaffoldState>(),
            );
            debugPrint('GoRoute /monitoring: MonitoringPage created successfully, returning page');
            return page;
          } catch (e, stackTrace) {
            debugPrint('=== GoRoute /monitoring builder ERROR: $e ===');
            debugPrint('GoRoute /monitoring builder stack: $stackTrace');
            // Возвращаем простую страницу с ошибкой вместо rethrow
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Ошибка создания страницы: $e'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => GoRouter.of(context).go('/dashboard'),
                      child: const Text('Вернуться на главную'),
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
      // Старые роуты оставляем для обратной совместимости
      GoRoute(
        path: '/areas',
        builder: (context, state) => AreasPage(
          scaffoldKey: GlobalKey<ScaffoldState>(),
        ),
      ),
      GoRoute(
        path: '/polygons',
        builder: (context, state) => PolygonsPage(
          scaffoldKey: GlobalKey<ScaffoldState>(),
        ),
      ),
      GoRoute(
        path: '/tickets',
        builder: (context, state) => TicketsPage(
          scaffoldKey: GlobalKey<ScaffoldState>(),
        ),
      ),
      GoRoute(
        path: '/kgu/contracts',
        builder: (context, state) => ContractsPage(
          scaffoldKey: GlobalKey<ScaffoldState>(),
        ),
      ),
      GoRoute(
        path: '/analytics',
        name: 'analytics',
        builder: (context, state) => AnalyticsDashboardPage(
          scaffoldKey: GlobalKey<ScaffoldState>(),
        ),
      ),
      GoRoute(
        path: '/analytics/trips',
        builder: (context, state) => AnalyticsTripsPage(
          scaffoldKey: GlobalKey<ScaffoldState>(),
        ),
      ),
      GoRoute(
        path: '/analytics/violations',
        builder: (context, state) => AnalyticsViolationsPage(
          scaffoldKey: GlobalKey<ScaffoldState>(),
        ),
      ),
      GoRoute(
        path: '/analytics/performance',
        builder: (context, state) => AnalyticsPerformancePage(
          scaffoldKey: GlobalKey<ScaffoldState>(),
        ),
      ),
      GoRoute(
        path: '/analytics/contracts',
        builder: (context, state) => AnalyticsContractsPage(
          scaffoldKey: GlobalKey<ScaffoldState>(),
        ),
      ),
      GoRoute(
        path: '/analytics/areas',
        builder: (context, state) => AnalyticsAreasPage(
          scaffoldKey: GlobalKey<ScaffoldState>(),
        ),
      ),
      GoRoute(
        path: '/analytics/drivers',
        builder: (context, state) => AnalyticsDriversPage(
          scaffoldKey: GlobalKey<ScaffoldState>(),
        ),
      ),
      GoRoute(
        path: '/analytics/vehicles',
        builder: (context, state) => AnalyticsVehiclesPage(
          scaffoldKey: GlobalKey<ScaffoldState>(),
        ),
      ),
      GoRoute(
        path: '/analytics/technical',
        builder: (context, state) => AnalyticsTechnicalPage(
          scaffoldKey: GlobalKey<ScaffoldState>(),
        ),
      ),
      GoRoute(
        path: '/analytics/trips/:id',
        builder: (context, state) {
          final tripId = state.pathParameters['id']!;
          return AnalyticsTripDetailPage(
            tripId: tripId,
            scaffoldKey: GlobalKey<ScaffoldState>(),
          );
        },
      ),
      GoRoute(
        path: '/violations',
        builder: (context, state) => ViolationsPage(
          scaffoldKey: GlobalKey<ScaffoldState>(),
        ),
      ),
      GoRoute(
        path: '/violations/:id',
        builder: (context, state) {
          final violationId = state.pathParameters['id']!;
          return ViolationDetailPage(
            violationId: violationId,
            scaffoldKey: GlobalKey<ScaffoldState>(),
          );
        },
      ),
      GoRoute(
        path: '/driver',
        builder: (context, state) => const DriverHome(),
      ),
    ],
   redirect: (context, state) async {
  debugPrint('=== GoRouter redirect called: ${state.matchedLocation} ===');
  
  // Получаем authState через Container из контекста
  final container = ProviderScope.containerOf(context);
  var authState = container.read(authNotifierProvider);
  
  // Если идет проверка токена, ждем ее завершения (особенно важно при обновлении страницы)
  if (authState.isCheckingToken || (authState.user == null && !authState.isCheckingToken)) {
    debugPrint('GoRouter redirect: Waiting for token check to complete or user to be restored...');
    int attempts = 0;
    const maxAttempts = 30; // До 3 секунд
    while ((authState.isCheckingToken || authState.user == null) && attempts < maxAttempts) {
      await Future.delayed(const Duration(milliseconds: 100));
      authState = container.read(authNotifierProvider);
      // Если пользователь восстановлен, выходим
      if (authState.user != null && !authState.isCheckingToken) {
        break;
      }
      attempts++;
    }
    debugPrint('GoRouter redirect: Token check completed, user=${authState.user != null}, attempts=$attempts');
  }
  
  debugPrint('GoRouter redirect: loggedIn=${authState.user != null}, location=${state.matchedLocation}');
  
  final loggedIn = authState.user != null;
  final currentLocation = state.matchedLocation;
  final isLoggingIn = currentLocation == '/login';

  // Загружаем сохраненный роут один раз для всей функции (если пользователь авторизован)
  String? savedRoute;
  if (loggedIn) {
    savedRoute = await RouteStorage.getLastRoute();
  }

  // Сохраняем роут при каждой навигации (если пользователь авторизован и не на логине)
  // Включаем query параметры для сохранения состояния вкладок
  if (loggedIn && !isLoggingIn && currentLocation != '/login' && !currentLocation.startsWith('/login')) {
    // Используем state.uri вместо GoRouterState.of(context).uri
    final uri = state.uri;
    final fullLocation = uri.hasQuery 
        ? '${uri.path}?${uri.query}' 
        : uri.path;
    RouteStorage.saveLastRoute(fullLocation).catchError((e) {
      debugPrint('Error saving route in redirect: $e');
    });
  }

  // Если не авторизован и не на странице логина - перенаправить на логин
  if (!loggedIn && !isLoggingIn) {
    debugPrint('GoRouter redirect: Not logged in, redirecting to /login');
    await RouteStorage.clearLastRoute();
    return '/login';
  }

  // Если авторизован и на странице логина - перенаправить на сохраненный роут или dashboard
  // Это важно при восстановлении после обновления страницы
  if (loggedIn && isLoggingIn) {
    debugPrint('GoRouter redirect: User logged in on /login, checking saved route: $savedRoute');
    if (savedRoute != null && savedRoute != '/login' && !savedRoute.startsWith('/login')) {
      // Извлекаем путь без query параметров для проверки
      final routePath = savedRoute.contains('?') 
          ? savedRoute.split('?')[0] 
          : savedRoute;
      
      final validRoutes = [
        '/home', '/dashboard', '/organization', '/monitoring', '/areas', 
        '/polygons', '/tickets', '/kgu/contracts', '/analytics',
        '/analytics/trips', '/analytics/violations', '/analytics/performance',
        '/analytics/contracts', '/analytics/areas', '/analytics/drivers',
        '/analytics/vehicles', '/analytics/technical', '/violations', '/driver'
      ];
      
      // Проверяем динамические роуты
      final isDynamicRoute = routePath.startsWith('/violations/') || 
                             routePath.startsWith('/analytics/trips/');
      
      if (validRoutes.contains(routePath) || isDynamicRoute) {
        debugPrint('GoRouter redirect: Redirecting from /login to saved route: $savedRoute');
        return savedRoute; // Возвращаем полный путь с query параметрами
      } else {
        debugPrint('GoRouter redirect: Saved route is not valid: $savedRoute');
      }
    } else {
      debugPrint('GoRouter redirect: No saved route or invalid route: $savedRoute');
    }
    debugPrint('GoRouter redirect: Redirecting to /dashboard');
    return '/dashboard';
  }

  // Если авторизован - проверить валидность роута (с поддержкой query параметров)
  if (loggedIn) {
    // Извлекаем путь без query параметров для проверки
    final routePath = currentLocation.contains('?') 
        ? currentLocation.split('?')[0] 
        : currentLocation;
    
    // ВАЖНО: Для водителя редиректим /tickets на /driver?tab=tickets
    // чтобы тикеты открывались как вкладка, а не отдельный экран
    final user = authState.user;
    if (user != null) {
      final role = userRoleFromString(user.role);
      if (role == UserRole.driver && routePath == '/tickets') {
        debugPrint('GoRouter redirect: Driver trying to access /tickets, redirecting to /driver?tab=tickets');
        return '/driver?tab=tickets';
      }
    }
    
    final validRoutes = [
      '/login', '/home', '/dashboard', '/organization', '/monitoring', '/areas', 
      '/polygons', '/tickets', '/kgu/contracts', '/analytics',
      '/analytics/trips', '/analytics/violations', '/analytics/performance',
      '/analytics/contracts', '/analytics/areas', '/analytics/drivers',
      '/analytics/vehicles', '/analytics/technical', '/violations', '/driver'
    ];
    
    // Проверяем динамические роуты (с параметрами)
    if (routePath.startsWith('/violations/')) {
      debugPrint('GoRouter redirect: Allowing violations detail route');
      return null; // Разрешаем доступ к детальным страницам нарушений
    }
    
    // ВАЖНО: Проверяем сохраненный роут при восстановлении (после обновления страницы)
    // Это происходит когда роутер инициализируется с путем без query параметров
    // но сохраненный роут содержит query параметры (например, вкладки)
    // savedRoute уже объявлен выше для всей функции redirect
    if (savedRoute != null && savedRoute != '/login' && !savedRoute.startsWith('/login')) {
      final savedRoutePath = savedRoute.contains('?') 
          ? savedRoute.split('?')[0] 
          : savedRoute;
      
      // Если текущий путь совпадает с сохраненным, но сохраненный имеет query параметры
      // и текущий их не имеет - перенаправляем на сохраненный роут с параметрами
      if (routePath == savedRoutePath && savedRoute.contains('?') && !currentLocation.contains('?')) {
        debugPrint('GoRouter redirect: Restoring saved route with query params: $savedRoute (current: $currentLocation)');
        return savedRoute; // Возвращаем полный путь с query параметрами
      }
      
      // Если пользователь на /login или /dashboard после восстановления - проверяем сохраненный роут
      if ((routePath == '/login' || routePath == '/dashboard') && routePath != savedRoutePath) {
        final isDynamicRoute = savedRoutePath.startsWith('/violations/') || 
                               savedRoutePath.startsWith('/analytics/trips/');
        
        if (validRoutes.contains(savedRoutePath) || isDynamicRoute) {
          debugPrint('GoRouter redirect: Restoring saved route from /login or /dashboard: $savedRoute');
          return savedRoute; // Возвращаем полный путь с query параметрами
        }
      }
    }
    

    if (validRoutes.contains(routePath)) {
      debugPrint('GoRouter redirect: Route is valid, allowing: $currentLocation');
      return null;
    }
    
    debugPrint('GoRouter redirect: Route is not valid: $currentLocation');
    // Если роут не валидный - перенаправить на сохраненный роут или dashboard
    // savedRoute уже объявлен выше
    if (savedRoute != null && savedRoute != '/login' && !savedRoute.startsWith('/login')) {
      final savedRoutePath = savedRoute.contains('?') 
          ? savedRoute.split('?')[0] 
          : savedRoute;
      if (validRoutes.contains(savedRoutePath)) {
        debugPrint('GoRouter redirect: Redirecting to saved route: $savedRoute');
        return savedRoute; // Возвращаем полный путь с query параметрами
      }
    }
    debugPrint('GoRouter redirect: Redirecting to /dashboard');
    return '/dashboard';
  }

  debugPrint('GoRouter redirect: No redirect needed');
  return null;
},
  );
  
  // Сохраняем роут при навигации через listener (включая query параметры)
  router.routerDelegate.addListener(() {
    final uri = router.routerDelegate.currentConfiguration.uri;
    // Сохраняем полный путь с query параметрами
    final currentLocation = uri.hasQuery 
        ? '${uri.path}?${uri.query}' 
        : uri.path;
    // Используем finalAuthState, который уже был получен выше
    if (finalAuthState.user != null && currentLocation != '/login' && !currentLocation.startsWith('/login')) {
      // Сохраняем асинхронно, не блокируя навигацию
      RouteStorage.saveLastRoute(currentLocation).catchError((e) {
        debugPrint('Error saving route: $e');
      });
    }
  });
  
  return router;
});
