import 'package:akimat_project/core/locale/language_switcher.dart';
import 'package:akimat_project/generated/l10n.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NavbarWidgetsProvider {
  /// Get default web navbar widgets with language switcher
  static List<Widget> getDefaultWebWidgets(BuildContext context) {
    return [
      TextButton(
        onPressed: () => context.go('/dashboard'),
        child: Text(S.of(context).dashboard),
      ),
      TextButton(
        onPressed: () => context.go('/organization'),
        child: Text(S.of(context).organizations),
      ),
      TextButton(
        onPressed: () {},
        child: Text(S.of(context).areas),
      ),
      TextButton(
        onPressed: () {},
        child: Text(S.of(context).polygons),
      ),
      TextButton(
        onPressed: () {},
        child: Text(S.of(context).tickets),
      ),
      TextButton(
        onPressed: () {},
        child: Text(S.of(context).trips),
      ),
      TextButton(
        onPressed: () {},
        child: Text(S.of(context).reports),
      ),
      const LanguageSwitcher(),
    ];
  }

  /// Get default mobile navbar widgets with language switcher
  static List<Widget> getDefaultMobileWidgets(BuildContext context) {
    return [
      // IconButton(
      //   icon: const Icon(Icons.dashboard),
      //   tooltip: S.of(context).dashboard,
      //   onPressed: () => context.go('/dashboard'),
      // ),
      // IconButton(
      //   icon: const Icon(Icons.do_not_touch),
      //   tooltip: S.of(context).organizations,
      //   onPressed: () => context.go('/organization'),
      // ),
      // IconButton(
      //   icon: const Icon(Icons.area_chart),
      //   tooltip: S.of(context).areas,
      //   onPressed: () {},
      // ),
      const LanguageSwitcher(),
    ];
  }

  /// Combine custom widgets with language switcher for web
  static List<Widget> combineWebWidgets(
    BuildContext context,
    List<Widget>? customWidgets,
  ) {
    if (customWidgets == null) {
      return getDefaultWebWidgets(context);
    }
    // Ensure language switcher is always included
    final hasLanguageSwitcher = customWidgets.any(
      (w) => w.runtimeType.toString() == 'LanguageSwitcher' || w is LanguageSwitcher,
    );
    if (!hasLanguageSwitcher) {
      return [...customWidgets, const LanguageSwitcher()];
    }
    return customWidgets;
  }

  /// Combine custom widgets with language switcher for mobile
  static List<Widget> combineMobileWidgets(
    BuildContext context,
    List<Widget>? customWidgets,
  ) {
    if (customWidgets == null) {
      return getDefaultMobileWidgets(context);
    }
    // Ensure language switcher is always included
    final hasLanguageSwitcher = customWidgets.any(
      (w) => w.runtimeType.toString() == 'LanguageSwitcher' || w is LanguageSwitcher,
    );
    if (!hasLanguageSwitcher) {
      return [...customWidgets, const LanguageSwitcher()];
    }
    return customWidgets;
  }
}

