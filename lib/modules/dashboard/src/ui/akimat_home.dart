import 'package:akimat_project/core/navbar/app_navbar.dart';
import 'package:akimat_project/core/navbar/header_navbar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:akimat_project/core/platform/platform_utils.dart';
import 'package:akimat_project/core/ui/widgets/card_item.dart';
// import 'package:akimat_project/core/app_navbar/app_navbar.dart';

class AkimatHome extends StatelessWidget {
  const AkimatHome({super.key});

  final _scaffoldKey = GlobalKey<ScaffoldState>;

  @override
  Widget build(BuildContext context) {
    final config = PlatformConfig.instance;

    final kpiCards = [
      AppCard(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('Активные участки', style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text('12', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      AppCard(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('Активные тикеты', style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text('8', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    ];

    final extraWidgets = <Widget>[];
    if (config.showExtraWidget) {
      extraWidgets.add(
        Container(
          height: 100,
          color: Colors.blue[100],
          child: const Center(child: Text('Дополнительный веб-виджет')),
        ),
      );
    } else {
      extraWidgets.add(
        Container(
          height: 80,
          color: Colors.green[100],
          child: const Center(child: Text('Дополнительный мобильный виджет')),
        ),
      );
    }

   final _scaffoldKey = GlobalKey<ScaffoldState>();

return Scaffold(
  key: _scaffoldKey,
  drawer: Drawer(
    child: ListView(
      padding: EdgeInsets.zero,
      children: const [
        DrawerHeader(
          decoration: BoxDecoration(color: Colors.blue),
          child: Text('Меню', style: TextStyle(color: Colors.white, fontSize: 20)),
        ),
        ListTile(
          leading: Icon(Icons.dashboard),
          title: Text('Главная'),
        ),
        ListTile(
          leading: Icon(Icons.business),
          title: Text('Организации'),
        ),
      ],
    ),
  ),

  // 1️⃣ добавляем AppNavbar
  appBar: kIsWeb
      ? null
      : PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: HeaderNavbar(
            scaffoldKey: _scaffoldKey, // ⚡ ключ обязательно передаём
            mobileWidgets: [
              IconButton(icon: const Icon(Icons.notifications), onPressed: () {}),
              IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
            ],
          ),
        ),

   body: Column(
        children: [
          if (kIsWeb)
            HeaderNavbar(
              webWidgets: [
                TextButton(onPressed: () {}, child: const Text('Главная')),
                TextButton(onPressed: () {}, child: const Text('Организации')),
                TextButton(onPressed: () {}, child: const Text('Статистика')),
              ],
            ),
          Expanded(
            child: Row(
              children: [
                if (kIsWeb)
                  NavigationRail(
                    selectedIndex: 0,
                    destinations: const [
                      NavigationRailDestination(icon: Icon(Icons.dashboard), label: Text('Дашборд')),
                      NavigationRailDestination(icon: Icon(Icons.business), label: Text('Организации')),
                    ],
                  ),
                if (kIsWeb) const VerticalDivider(thickness: 1, width: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(config.padding),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (config.topOffset > 0) SizedBox(height: config.topOffset),
                          const Text(
                            'Главная панель',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 120,
                            child: config.horizontalScroll
                                ? ListView(scrollDirection: Axis.horizontal, children: kpiCards)
                                : Row(mainAxisAlignment: MainAxisAlignment.start, children: kpiCards),
                          ),
                          const SizedBox(height: 16),
                          ...extraWidgets,
                          const SizedBox(height: 16),
                          const Text('Последние рейсы',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
