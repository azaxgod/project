import 'package:akimat_project/core/storage/route_storage.dart';
import 'package:akimat_project/modules/analytics/src/ui/screen/analytics_areas_page.dart';
import 'package:akimat_project/modules/analytics/src/ui/screen/analytics_contracts_page.dart';
import 'package:akimat_project/modules/analytics/src/ui/screen/analytics_dashboard_page.dart';
import 'package:akimat_project/modules/analytics/src/ui/screen/analytics_drivers_page.dart';
import 'package:akimat_project/modules/analytics/src/ui/screen/analytics_performance_page.dart';
import 'package:akimat_project/modules/analytics/src/ui/screen/analytics_technical_page.dart';
import 'package:akimat_project/modules/analytics/src/ui/screen/analytics_trips_page.dart';
import 'package:akimat_project/modules/analytics/src/ui/screen/analytics_violations_page.dart';
import 'package:akimat_project/modules/analytics/src/ui/screen/analytics_vehicles_page.dart';
import 'package:akimat_project/modules/auth/src/controller/auth_notifier.dart';
import 'package:akimat_project/modules/auth/src/ui/login_page.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/akimat_dashboard/akimat_home.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/areas/areas_page.dart';
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
        '/home', '/dashboard', '/organization', '/areas', 
        '/polygons', '/tickets', '/kgu/contracts', '/analytics',
        '/analytics/trips', '/analytics/violations', '/analytics/performance',
        '/analytics/contracts', '/analytics/areas', '/analytics/drivers',
        '/analytics/vehicles', '/analytics/technical', '/violations'
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
        builder: (context, state) => AkimatHome(
          scaffoldKey: GlobalKey<ScaffoldState>(),
        ),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => AkimatHome(
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
        builder: (context, state) => const AnalyticsTripsPage(),
      ),
      GoRoute(
        path: '/analytics/violations',
        builder: (context, state) => const AnalyticsViolationsPage(),
      ),
      GoRoute(
        path: '/analytics/performance',
        builder: (context, state) => const AnalyticsPerformancePage(),
      ),
      GoRoute(
        path: '/analytics/contracts',
        builder: (context, state) => const AnalyticsContractsPage(),
      ),
      GoRoute(
        path: '/analytics/areas',
        builder: (context, state) => const AnalyticsAreasPage(),
      ),
      GoRoute(
        path: '/analytics/drivers',
        builder: (context, state) => const AnalyticsDriversPage(),
      ),
      GoRoute(
        path: '/analytics/vehicles',
        builder: (context, state) => const AnalyticsVehiclesPage(),
      ),
      GoRoute(
        path: '/analytics/technical',
        builder: (context, state) => const AnalyticsTechnicalPage(),
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
  final loggedIn = authState.user != null;
  final currentLocation = state.matchedLocation;
  final isLoggingIn = currentLocation == '/login';

  // Если не авторизован и не на странице логина - перенаправить на логин
  if (!loggedIn && !isLoggingIn) {
    await RouteStorage.clearLastRoute();
    return '/login';
  }

  // Если авторизован и на странице логина - перенаправить на сохраненный роут или dashboard
  if (loggedIn && isLoggingIn) {
    final savedRoute = await RouteStorage.getLastRoute();
    final validRoutes = [
      '/home', '/dashboard', '/organization', '/areas', 
      '/polygons', '/tickets', '/kgu/contracts', '/analytics',
      '/analytics/trips', '/analytics/violations', '/analytics/performance',
      '/analytics/contracts', '/analytics/areas', '/analytics/drivers',
      '/analytics/vehicles', '/analytics/technical', '/violations'
    ];
    
    // Проверяем динамические роуты
    if (savedRoute != null && savedRoute.startsWith('/violations/')) {
      return savedRoute;
    }
    
    if (savedRoute != null && validRoutes.contains(savedRoute)) {
      return savedRoute;
    }
    return '/dashboard';
  }

  // Если авторизован - проверить валидность роута
  if (loggedIn) {
    final validRoutes = [
      '/login', '/home', '/dashboard', '/organization', '/areas', 
      '/polygons', '/tickets', '/kgu/contracts', '/analytics',
      '/analytics/trips', '/analytics/violations', '/analytics/performance',
      '/analytics/contracts', '/analytics/areas', '/analytics/drivers',
      '/analytics/vehicles', '/analytics/technical', '/violations'
    ];
    
    // Проверяем динамические роуты (с параметрами)
    if (currentLocation.startsWith('/violations/')) {
      return null; // Разрешаем доступ к детальным страницам нарушений
    }
    
    // Если роут валидный - оставить как есть (сохранение происходит через listener)
    if (validRoutes.contains(currentLocation)) {
      return null;
    }
    
    // Если роут не валидный - перенаправить на сохраненный роут или dashboard
    final savedRoute = await RouteStorage.getLastRoute();
    if (savedRoute != null && validRoutes.contains(savedRoute)) {
      return savedRoute;
    }
    return '/dashboard';
  }

  return null;
},
  );
  
  // Сохраняем роут при навигации через listener
  router.routerDelegate.addListener(() {
    final currentLocation = router.routerDelegate.currentConfiguration.uri.path;
    if (authState.user != null && currentLocation != '/login') {
      // Сохраняем асинхронно, не блокируя навигацию
      RouteStorage.saveLastRoute(currentLocation).catchError((e) {
        debugPrint('Error saving route: $e');
      });
    }
  });
  
  return router;
});
