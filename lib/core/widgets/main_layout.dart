import 'package:akimat_project/core/navbar/header_navbar.dart';
import 'package:akimat_project/core/widgets/app_footer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class MainLayout extends StatelessWidget {
  const MainLayout({
    super.key,
    required this.child,
    this.webNavbarWidgets,
    this.mobileNavbarWidgets,
    this.showFooter = true,
  });

  final Widget child;
  final List<Widget>? webNavbarWidgets;
  final List<Widget>? mobileNavbarWidgets;
  final bool showFooter;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      // На мобилке footer не нужен (мало места)
      return child;
    }

    return Column(
      children: [
        // Navbar
        HeaderNavbar(
          webWidgets: webNavbarWidgets,
          mobileWidgets: mobileNavbarWidgets,
        ),
        // Основной контент
        Expanded(child: child),
        // Footer
        if (showFooter) const AppFooter(),
      ],
    );
  }
}



