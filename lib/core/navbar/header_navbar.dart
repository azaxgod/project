import 'package:akimat_project/generated/l10n.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:akimat_project/core/navbar/app_navbar.dart';

class HeaderNavbar extends StatelessWidget implements PreferredSizeWidget{
  final List<Widget>? webWidgets;
  final List<Widget>? mobileWidgets;
  final GlobalKey<ScaffoldState>? scaffoldKey; 

  const HeaderNavbar({
  super.key, 
  this.webWidgets, 
  this.mobileWidgets,
  this.scaffoldKey
  });
  
  @override 
  Size get preferredSize => const Size.fromHeight(60);
  
  @override
  Widget build(BuildContext context) {
    return kIsWeb
        ? AppNavbar(
          // scaffoldKey: scaffoldKey,
            webWidgets: webWidgets ??
                [
            TextButton(onPressed: () {}, child: Text(S.of(context).dashboard)),
                TextButton(onPressed: () {}, child: Text(S.of(context).organizations)),
                TextButton(onPressed: () {}, child: Text(S.of(context).areas)),
                TextButton(onPressed: () {}, child: Text(S.of(context).polygons)),
                TextButton(onPressed: () {}, child: Text(S.of(context).tickets)),
                TextButton(onPressed: () {}, child: Text(S.of(context).trips)),
                TextButton(onPressed: () {}, child: Text(S.of(context).reports)),
                ],
          )
        : AppNavbar(
          scaffoldKey: scaffoldKey,
            mobileWidgets: mobileWidgets ??
                [
 IconButton(
                icon: const Icon(Icons.dashboard),
                tooltip: S.of(context).dashboard,
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.business),
                tooltip: S.of(context).organizations,
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.area_chart),
                tooltip: S.of(context).areas,
                onPressed: () {},
              ),
            ],
          );
  }
}
