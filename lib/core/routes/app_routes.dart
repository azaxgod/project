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
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = FutureProvider<GoRouter>((ref) async {
  final authState = ref.watch(authNotifierProvider);
  
  // Ждем, пока Firebase Auth восстановит состояние (особенно важно на вебе)
  // Если идет проверка токена, ждем ее завершения
  if (authState.isCheckingToken) {
    // Ждем до 2 секунд, пока состояние восстановится
    int attempts = 0;
    while (authState.isCheckingToken && attempts < 20) {
      await Future.delayed(const Duration(milliseconds: 100));
      final currentState = ref.read(authNotifierProvider);
      if (!currentState.isCheckingToken) break;
      attempts++;
    }
  }
  
  // Получаем актуальное состояние после ожидания
  final finalAuthState = ref.read(authNotifierProvider);
  
  // Загружаем сохраненный роут асинхронно
  String initialLocation = '/login';
  if (finalAuthState.user != null) {
    final savedRoute = await RouteStorage.getLastRoute();
    if (savedRoute != null && savedRoute != '/login') {
      final validRoutes = [
        '/home', '/dashboard', '/organization', '/monitoring', '/areas', 
        '/polygons', '/tickets', '/kgu/contracts', '/analytics',
        '/analytics/trips', '/analytics/violations', '/analytics/performance',
        '/analytics/contracts', '/analytics/areas', '/analytics/drivers',
        '/analytics/vehicles', '/analytics/technical', '/analytics/trips/:id', '/violations'
      ];
      if (validRoutes.contains(savedRoute)) {
        initialLocation = savedRoute;
      } else {
        initialLocation = '/dashboard';
      }
    } else {
      initialLocation = '/dashboard';
    }
  }

  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: initialLocation,
    onException: (context, state, exception) {
      // Обработка ошибок навигации
      debugPrint('Navigation error: $exception');
    },
    routes: [
      GoRoute(
        path: '/login',
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
    ],
   redirect: (context, state) async {
  debugPrint('=== GoRouter redirect called: ${state.matchedLocation} ===');
  
  // Получаем authState через Container из контекста
  final container = ProviderScope.containerOf(context);
  final authState = container.read(authNotifierProvider);
  
  debugPrint('GoRouter redirect: loggedIn=${authState.user != null}, location=${state.matchedLocation}');
  
  final loggedIn = authState.user != null;
  final currentLocation = state.matchedLocation;
  final isLoggingIn = currentLocation == '/login';

  // Сохраняем роут при каждой навигации (если пользователь авторизован и не на логине)
  if (loggedIn && !isLoggingIn && currentLocation != '/login') {
    RouteStorage.saveLastRoute(currentLocation).catchError((e) {
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
  if (loggedIn && isLoggingIn) {
    final savedRoute = await RouteStorage.getLastRoute();
    final validRoutes = [
      '/home', '/dashboard', '/organization', '/monitoring', '/areas', 
      '/polygons', '/tickets', '/kgu/contracts', '/analytics',
      '/analytics/trips', '/analytics/violations', '/analytics/performance',
      '/analytics/contracts', '/analytics/areas', '/analytics/drivers',
      '/analytics/vehicles', '/analytics/technical', '/violations'
    ];
    
    // Проверяем динамические роуты
    if (savedRoute != null && savedRoute.startsWith('/violations/')) {
      debugPrint('GoRouter redirect: Redirecting to saved route: $savedRoute');
      return savedRoute;
    }
    
    if (savedRoute != null && validRoutes.contains(savedRoute)) {
      debugPrint('GoRouter redirect: Redirecting to saved route: $savedRoute');
      return savedRoute;
    }
    debugPrint('GoRouter redirect: No valid saved route, redirecting to /dashboard');
    return '/dashboard';
  }

  // Если авторизован - проверить валидность роута
  if (loggedIn) {
    final validRoutes = [
      '/login', '/home', '/dashboard', '/organization', '/monitoring', '/areas', 
      '/polygons', '/tickets', '/kgu/contracts', '/analytics',
      '/analytics/trips', '/analytics/violations', '/analytics/performance',
      '/analytics/contracts', '/analytics/areas', '/analytics/drivers',
      '/analytics/vehicles', '/analytics/technical', '/violations'
    ];
    
    // Проверяем динамические роуты (с параметрами)
    if (currentLocation.startsWith('/violations/')) {
      debugPrint('GoRouter redirect: Allowing violations detail route');
      return null; // Разрешаем доступ к детальным страницам нарушений
    }
    
    // Если роут валидный - оставить как есть
    if (validRoutes.contains(currentLocation)) {
      debugPrint('GoRouter redirect: Route is valid, allowing: $currentLocation');
      return null;
    }
    
    debugPrint('GoRouter redirect: Route is not valid: $currentLocation');
    // Если роут не валидный - перенаправить на сохраненный роут или dashboard
    final savedRoute = await RouteStorage.getLastRoute();
    if (savedRoute != null && validRoutes.contains(savedRoute)) {
      debugPrint('GoRouter redirect: Redirecting to saved route: $savedRoute');
      return savedRoute;
    }
    debugPrint('GoRouter redirect: Redirecting to /dashboard');
    return '/dashboard';
  }

  debugPrint('GoRouter redirect: No redirect needed');
  return null;
},
  );
  
  // Сохраняем роут при навигации через listener
  router.routerDelegate.addListener(() {
    final currentLocation = router.routerDelegate.currentConfiguration.uri.path;
    if (finalAuthState.user != null && currentLocation != '/login') {
      // Сохраняем асинхронно, не блокируя навигацию
      RouteStorage.saveLastRoute(currentLocation).catchError((e) {
        debugPrint('Error saving route: $e');
      });
    }
  });
  
  return router;
});
