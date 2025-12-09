import 'package:akimat_project/core/navbar/app_navbar.dart';
import 'package:akimat_project/core/navbar/navbar_widgets_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HeaderNavbar extends StatelessWidget {
  final List<Widget>? webWidgets;
  final List<Widget>? mobileWidgets;
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const HeaderNavbar({
    super.key,
    this.webWidgets,
    this.mobileWidgets,
    this.scaffoldKey,
  });

  @override
  Widget build(BuildContext context) {
    // Используем GoRouter.of(context) для отслеживания изменений роута
    // Это заставит виджет перестраиваться при изменении роута
    final router = GoRouter.of(context);
    final uri = router.routerDelegate.currentConfiguration.uri;
    // Используем uri для принудительного обновления при изменении роута
    
    // Если webWidgets или mobileWidgets уже переданы, используем их напрямую
    // БЕЗ дополнительного комбинирования через combineWebWidgets,
    // чтобы избежать дублирования навбара
    final widgetsToUse = kIsWeb 
        ? (webWidgets ?? NavbarWidgetsProvider.getDefaultWebWidgets(context))
        : (mobileWidgets ?? NavbarWidgetsProvider.getDefaultMobileWidgets(context));
    
    return kIsWeb
        ? AppNavbar(
            webWidgets: widgetsToUse,
          )
        : AppNavbar(
            scaffoldKey: scaffoldKey,
            mobileWidgets: widgetsToUse,
          );
  }
}
