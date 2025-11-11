import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../platform/platform_utils.dart'; 

class AppNavbar extends StatelessWidget {
  final List<Widget> webWidgets;
  final List<Widget> mobileWidgets;
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const AppNavbar({
    super.key,
  this.scaffoldKey,
    this.webWidgets = const [],
    this.mobileWidgets = const [],
  });

  @override
  Widget build(BuildContext context) {
    final config = PlatformConfig.instance;

    if (kIsWeb) {

      return Container(
        height: 60,
        color: config.backgroundColor,
        padding: EdgeInsets.symmetric(horizontal: config.padding),
        child: Row(
          children: [
            const Text(
              'Логотип / Название',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(width: 32),
            ...webWidgets, 
          ],
        ),
      );
    } else {

      return AppBar(
        backgroundColor: config.backgroundColor,
        title: const Text('Логотип / Название'),
        actions: mobileWidgets, 
        leading: IconButton(onPressed: (){
          if (scaffoldKey != null && scaffoldKey!.currentState != null){
            scaffoldKey!.currentState!.openDrawer();
          }
        }, icon: Icon(Icons.menu)),
      );
    }
  }
}
