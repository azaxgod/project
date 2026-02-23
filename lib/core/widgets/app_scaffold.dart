import 'package:akimat_project/core/widgets/app_footer.dart';
import 'package:flutter/material.dart';

/// Scaffold с глобальным футером версии
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.drawer,
    this.floatingActionButton,
    this.backgroundColor,
    this.scaffoldKey,
    this.showFooter = true,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? drawer;
  final Widget? floatingActionButton;
  final Color? backgroundColor;
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final bool showFooter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: appBar,
      drawer: drawer,
      floatingActionButton: floatingActionButton,
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          Expanded(child: body),
          if (showFooter) const AppFooter(),
        ],
      ),
    );
  }
}



