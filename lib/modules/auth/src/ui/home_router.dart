import 'package:akimat_project/modules/areas/src/ui/contract_home.dart';
import 'package:akimat_project/modules/dashboard/src/ui/akimat_home.dart';
import 'package:akimat_project/modules/trips/src/ui/driver_home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controller/auth_notifier.dart';
// import '../../dashboard/src/ui/akimat_home.dart';
// import '../../areas/src/ui/contractor_home.dart';
// import '../../trips/src/ui/driver_home.dart';

class HomeRouter extends ConsumerWidget {
  const HomeRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(authNotifierProvider)?.role;

    if (role == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    switch (role) {
      case 'AKIMAT_ADMIN':
        return const AkimatHome();
      case 'TOO_ADMIN':
      case 'CONTRACTOR_ADMIN':
        return const ContractorHome();
      case 'DRIVER':
        return const DriverHome();
      default:
        return const Scaffold(body: Center(child: Text('Нет доступа')));
    }
  }
}
