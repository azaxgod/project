import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:akimat_project/generated/l10n.dart';

class DrawerItem {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  DrawerItem({required this.title, required this.icon, required this.onTap});
}

final mobileDrawerProvider = Provider<List<DrawerItem>>((ref) {
  return [
    DrawerItem(
      title: S.current.dashboard,
      icon: Icons.dashboard,
      onTap: () {
        print('Dashboard tapped');
      },
    ),
    DrawerItem(
      title: S.current.organizations,
      icon: Icons.business,
      onTap: () {
        print('Organizations tapped');
      },
    ),
    DrawerItem(
      title: S.current.areas,
      icon: Icons.area_chart,
      onTap: () {
        print('Areas tapped');
      },
    ),
  ];
});
class DrawerMobile extends ConsumerWidget {
  const DrawerMobile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(mobileDrawerProvider);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Center(
              child: Text('Меню', style: TextStyle(color: Colors.white, fontSize: 20)),
            ),
          ),
          ...items.map((item) => ListTile(
            leading: Icon(item.icon),
            title: Text(item.title),
            onTap: () {
              Navigator.of(context).pop(); // закрываем Drawer
              item.onTap(); // вызываем действие (например навигацию)
            },
          )),
        ],
      ),
    );
  }
}

