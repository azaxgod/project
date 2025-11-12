import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:akimat_project/generated/l10n.dart';
import 'package:go_router/go_router.dart';

class DrawerItem {
  final String title;
  final IconData icon;
  // final VoidCallback onTap;
  final String route;

  DrawerItem({required this.title, required this.icon, //required this.onTap
  required this.route});
}

final mobileDrawerProvider = Provider<List<DrawerItem>>((ref) {
  return [
    DrawerItem(
      title: S.current.dashboard,
      icon: Icons.dashboard,
        route: '/dashboard',
    ),
    DrawerItem(
      title: S.current.organizations,
      icon: Icons.business,
      route: '/organization',
    
      
    ),
    DrawerItem(
      title: S.current.areas,
      icon: Icons.area_chart,
      route:  
      'a'
      
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
              Navigator.of(context).pop();
              Future.microtask(()=> context.go(item.route));

       SchedulerBinding.instance.addPostFrameCallback((_) {
                  context.go(item.route); 
                });



              // Future.delayed(const Duration(milliseconds: 250),(){
              //   context.go(item.route);
              // });
            
            },
          )),
        ],
      ),
    );
  }
}

