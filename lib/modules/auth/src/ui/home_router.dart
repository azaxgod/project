  import 'package:akimat_project/modules/areas/src/ui/contract_home.dart';
  import 'package:akimat_project/modules/auth/src/controller/auth_notifier.dart';
  import 'package:akimat_project/modules/dashboard/src/ui/screen/akimat_dashboard/akimat_home.dart';
  import 'package:akimat_project/modules/trips/src/ui/driver_home.dart';
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:go_router/go_router.dart';
import 'package:akimat_project/generated/l10n.dart';
  class HomeRouter extends ConsumerWidget {
    const HomeRouter({super.key});

    @override
    Widget build(BuildContext context, WidgetRef ref) {
      final authState = ref.watch(authNotifierProvider);

      // 1. Если ещё идёт проверка токена при старте приложения
      if (authState.isCheckingToken) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      // 2. Пользователь не авторизован → редирект на логин
      if (authState.user == null) {
        Future.microtask(() => context.go('/login'));
        return const SizedBox.shrink();
      }

      // 3. Пользователь авторизован → проверка роли
      final role = authState.user!.role;
      switch (role) {
        case 'AKIMAT_ADMIN':
        final scaffoldKey = GlobalKey<ScaffoldState>();
          return AkimatHome(
            scaffoldKey: scaffoldKey,
          );
        case 'TOO_ADMIN':
        case 'CONTRACTOR_ADMIN':
          return const ContractorHome();
        case 'DRIVER':
          return const DriverHome();
        default:
          return const Scaffold(
            body: Center(child: Text('Нет доступа')),
          );
      }
    }
  }
