  import 'package:akimat_project/modules/areas/src/ui/contract_home.dart';
  import 'package:akimat_project/modules/auth/src/controller/auth_notifier.dart';
  import 'package:akimat_project/modules/dashboard/src/ui/screen/akimat_cabinet/akimat_cabinet_page.dart';
  import 'package:akimat_project/modules/dashboard/src/ui/screen/kgu_cabinet/kgu_cabinet_page.dart';
  import 'package:akimat_project/modules/dashboard/src/ui/screen/contractor_cabinet/contractor_cabinet_page.dart';
  import 'package:akimat_project/modules/dashboard/src/ui/screen/landfill_cabinet/landfill_cabinet_page.dart';
  import 'package:akimat_project/modules/trips/src/ui/driver_home.dart';
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:go_router/go_router.dart';
import 'package:akimat_project/l10n/l10n.dart';
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
        case 'AKIMAT_USER':
          final scaffoldKey = GlobalKey<ScaffoldState>();
          return AkimatCabinetPage(
            scaffoldKey: scaffoldKey,
          );
        case 'KGU_ZKH_ADMIN':
        case 'KGU_ZKH_USER':
          final scaffoldKey = GlobalKey<ScaffoldState>();
          return KguCabinetPage(
            scaffoldKey: scaffoldKey,
          );
        case 'CONTRACTOR_ADMIN':
        case 'CONTRACTOR_USER':
          final scaffoldKey = GlobalKey<ScaffoldState>();
          return ContractorCabinetPage(
            scaffoldKey: scaffoldKey,
          );
        case 'LANDFILL_ADMIN':
        case 'LANDFILL_USER':
        case 'TOO_ADMIN': // Поддержка старого значения
          final scaffoldKey = GlobalKey<ScaffoldState>();
          return LandfillCabinetPage(
            scaffoldKey: scaffoldKey,
          );
        case 'DRIVER':
          return const DriverHome();
        default:
          return const Scaffold(
            body: Center(child: Text('Нет доступа')),
          );
      }
    }
  }
