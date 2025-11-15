import 'package:akimat_project/core/navbar/app_navbar.dart';
import 'package:akimat_project/core/navbar/navbar_widgets_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class HeaderNavbar extends StatelessWidget implements PreferredSizeWidget {
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
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    return kIsWeb
        ? AppNavbar(
            // scaffoldKey: scaffoldKey,
            webWidgets: NavbarWidgetsProvider.combineWebWidgets(
              context,
              webWidgets,
            ),
          )
        : AppNavbar(
            scaffoldKey: scaffoldKey,
            mobileWidgets: NavbarWidgetsProvider.combineMobileWidgets(
              context,
              mobileWidgets,
            ),
          );
  }
}
