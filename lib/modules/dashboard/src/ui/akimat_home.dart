import 'package:akimat_project/core/navbar/drawer_mobile.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:akimat_project/core/navbar/header_navbar.dart';
import 'package:akimat_project/core/platform/platform_utils.dart';
import 'package:akimat_project/core/ui/widgets/card_item.dart';
// import 'drawer_mobile.dart'; // твой кастомный DrawerMobile

class AkimatHome extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final List<Widget>? webNavbarWidgets;
  final List<Widget>? mobileNavbarWidgets;

  const AkimatHome({
    super.key,
    required this.scaffoldKey,
    this.webNavbarWidgets,
    this.mobileNavbarWidgets,
  });

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

    return Scaffold(
      key: scaffoldKey,
      drawer: !kIsWeb ? const DrawerMobile() : null, // кастомный Drawer
      appBar: kIsWeb
          ? null
          : AppBar(
              title: const Text('Главная'),
              leading: Builder(
                builder: (context) {
                  return IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  );
                },
              ),
              actions: mobileNavbarWidgets, // твои иконки справа
            ),
      body: Column(
        children: [
          if (kIsWeb)
            HeaderNavbar(
              webWidgets: webNavbarWidgets,
            ),
          Expanded(
            child: Row(
              children: [
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
                                ? ListView(
                                    scrollDirection: Axis.horizontal,
                                    children: kpiCards,
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: kpiCards,
                                  ),
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
