import 'package:akimat_project/modules/auth/src/controller/auth_notifier.dart';
import 'package:akimat_project/modules/auth/src/ui/home_router.dart';
import 'package:akimat_project/modules/auth/src/ui/login_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// import 'modules/auth/src/ui/login_page.dart';
// import 'modules/home/home_router.dart';
// import 'modules/auth/src/controller/auth_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>();
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeRouter(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeRouter(),
      ),
    ],
    redirect: (context, state) {
      final loggedIn = authState.user != null;
      final loggingIn = state.matchedLocation == '/login';

      if (!loggedIn && !loggingIn) return '/login';
      if (loggedIn && loggingIn) return '/home';
      return null;
    },
  );
});
