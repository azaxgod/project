import 'package:akimat_project/generated/l10n.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:akimat_project/core/navbar/app_navbar.dart';

class HeaderNavbar extends StatelessWidget {
  final List<Widget>? webWidgets;
  final List<Widget>? mobileWidgets;
  final GlobalKey<ScaffoldState>? scaffoldKey; 

  const HeaderNavbar({super.key, this.webWidgets, this.mobileWidgets,this.scaffoldKey});

  @override
  Widget build(BuildContext context) {
    return kIsWeb
        ? AppNavbar(
          // scaffoldKey: scaffoldKey,
            webWidgets: webWidgets ??
                [
                  TextButton(onPressed: () {}, child: Text(S.of(context).loading)),
                  TextButton(onPressed: () {}, child: const Text('Организации')),
                ],
          )
        : AppNavbar(
          scaffoldKey:scaffoldKey!,
            mobileWidgets: mobileWidgets ??
                [
                  IconButton(icon: const Icon(Icons.notifications), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
                ],
          );
  }
}
