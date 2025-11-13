import 'package:akimat_project/core/locale/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:akimat_project/generated/l10n.dart';
import 'package:go_router/go_router.dart';

class DrawerItem {
  final String title;
  final IconData icon;
  final String route;

  DrawerItem({
    required this.title,
    required this.icon,
    required this.route,
  });
}

final mobileDrawerProvider = Provider.family<List<DrawerItem>, S>((ref, s) {
  return [
    DrawerItem(
      title: s.dashboard,
      icon: Icons.dashboard,
      route: '/dashboard',
    ),
    DrawerItem(
      title: s.organizations,
      icon: Icons.business,
      route: '/organization',
    ),
    DrawerItem(
      title: s.areas,
      icon: Icons.area_chart,
      route: '/areas',
    ),
  ];
});

class DrawerMobile extends ConsumerWidget {
  const DrawerMobile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch locale to ensure rebuild when language changes
    ref.watch(localeProvider);
    final s = S.of(context);
    final items = ref.watch(mobileDrawerProvider(s));

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.blue),
            child: Center(
              child: Text(
                s.menu,
                style: const TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
          ),
          ...items.map((item) => ListTile(
                leading: Icon(item.icon),
                title: Text(item.title),
                onTap: () {
                  Navigator.of(context).pop();
                  context.go(item.route);
                },
              )),
        ],
      ),
    );
  }
}

