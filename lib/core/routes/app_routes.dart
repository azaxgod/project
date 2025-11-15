import 'package:akimat_project/modules/auth/src/controller/auth_notifier.dart';
import 'package:akimat_project/modules/auth/src/ui/login_page.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/akimat_dashboard/akimat_home.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/areas/areas_page.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/organizations_page.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/polygons/polygons_page.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/tickets/tickets_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
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
    ],
   redirect: (context, state) {
  final loggedIn = authState.user != null;
  final loggingIn = state.matchedLocation == '/login';

  if (!loggedIn && !loggingIn) return '/login';
  if (loggedIn && loggingIn) return '/dashboard';


  final validRoutes = ['/login', '/home', '/dashboard', '/organization', '/areas', '/polygons', '/tickets'];
  if (!validRoutes.contains(state.matchedLocation)) return '/dashboard';

  return null;
},
  );
});
