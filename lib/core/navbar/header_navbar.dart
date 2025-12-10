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
    // Используем currentConfiguration как зависимость для принудительного обновления
    final config = router.routerDelegate.currentConfiguration;
    final uri = config.uri;
    // Используем uri.toString() для создания уникального ключа, который заставит виджет перестраиваться
    final routeKey = uri.toString();
    
    // Если webWidgets или mobileWidgets уже переданы, используем их напрямую
    // БЕЗ дополнительного комбинирования через combineWebWidgets,
    // чтобы избежать дублирования навбара
    // Важно: getDefaultWebWidgets/getDefaultMobileWidgets вызываются каждый раз при перестройке,
    // что обеспечивает актуальное состояние активной вкладки
    final widgetsToUse = kIsWeb 
        ? (webWidgets ?? NavbarWidgetsProvider.getDefaultWebWidgets(context))
        : (mobileWidgets ?? NavbarWidgetsProvider.getDefaultMobileWidgets(context));
    
    return kIsWeb
        ? AppNavbar(
            key: ValueKey(routeKey), // Ключ заставляет перестраиваться при изменении роута
            webWidgets: widgetsToUse,
          )
        : AppNavbar(
            key: ValueKey(routeKey), // Ключ заставляет перестраиваться при изменении роута
            scaffoldKey: scaffoldKey,
            mobileWidgets: widgetsToUse,
          );
  }
}
