import 'package:akimat_project/core/locale/language_switcher.dart';
import 'package:akimat_project/core/navbar/logout_button.dart';
import 'package:akimat_project/core/navbar/user_role_badge.dart';
import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/l10n/l10n.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NavbarWidgetsProvider {
  /// Get default web navbar widgets with language switcher
  static List<Widget> getDefaultWebWidgets(BuildContext context) {
    final theme = Theme.of(context);
    String currentRoute = '/';
    try {
      final router = GoRouter.of(context);
      currentRoute = router.routerDelegate.currentConfiguration.uri.path;
    } catch (e) {
      // Fallback if route cannot be determined
    }
    
    return [
      _NavbarButton(
        label: S.of(context)!.dashboard,
        icon: Icons.dashboard,
        isActive: currentRoute == '/dashboard',
        onPressed: () => context.go('/dashboard'),
      ),
      _NavbarButton(
        label: S.of(context)!.organizations,
        icon: Icons.business,
        isActive: currentRoute == '/organization',
        onPressed: () => context.go('/organization'),
      ),
      _NavbarButton(
        label: S.of(context)!.areas,
        icon: Icons.area_chart,
        isActive: currentRoute == '/areas',
        onPressed: () => context.go('/areas'),
      ),
      _NavbarButton(
        label: S.of(context)!.polygons,
        icon: Icons.map,
        isActive: currentRoute == '/polygons',
        onPressed: () => context.go('/polygons'),
      ),
      _NavbarButton(
        label: S.of(context)!.tickets,
        icon: Icons.assignment,
        isActive: currentRoute == '/tickets',
        onPressed: () => context.go('/tickets'),
      ),
      _NavbarButton(
        label: S.of(context)!.contracts,
        icon: Icons.receipt_long,
        isActive: currentRoute == '/kgu/contracts',
        onPressed: () => context.go('/kgu/contracts'),
      ),
      _NavbarButton(
        label: S.of(context)!.analytics,
        icon: Icons.analytics,
        isActive: currentRoute == '/analytics' || currentRoute.startsWith('/analytics/'),
        onPressed: () => context.go('/analytics'),
      ),
      _NavbarButton(
        label: S.of(context)!.violations,
        icon: Icons.gavel,
        isActive: currentRoute == '/violations' || currentRoute.startsWith('/violations/'),
        onPressed: () => context.go('/violations'),
      ),
      _NavbarButton(
        label: S.of(context)!.trips,
        icon: Icons.directions_car,
        isActive: false,
        onPressed: () {},
      ),
      _NavbarButton(
        label: S.of(context)!.reports,
        icon: Icons.assessment,
        isActive: false,
        onPressed: () {},
      ),
      const SizedBox(width: AppPadding.small),
      const UserRoleBadge(), // Отображение роли пользователя
      const SizedBox(width: AppPadding.small),
      const LanguageSwitcher(),
      const SizedBox(width: AppPadding.small),
      const LogoutButtonWeb(), // Кнопка выхода
    ];
  }

  /// Get default mobile navbar widgets with language switcher
  static List<Widget> getDefaultMobileWidgets(BuildContext context) {
    return [
      // IconButton(
      //   icon: const Icon(Icons.dashboard),
      //   tooltip: S.of(context)!.dashboard,
      //   onPressed: () => context.go('/dashboard'),
      // ),
      // IconButton(
      //   icon: const Icon(Icons.do_not_touch),
      //   tooltip: S.of(context)!.organizations,
      //   onPressed: () => context.go('/organization'),
      // ),
      // IconButton(
      //   icon: const Icon(Icons.area_chart),
      //   tooltip: S.of(context)!.areas,
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

class _NavbarButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onPressed;

  const _NavbarButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: isActive ? AppColors.primary : AppColors.textSecondary,
        backgroundColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(
          horizontal: AppPadding.normal,
          vertical: AppPadding.small,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSize.buttonRadius),
        ),
        // overlayColor: MaterialStateProperty.all(
        //   AppColors.primary.withOpacity(0.1),
        // ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSize.iconSizeSmall),
          const SizedBox(width: AppPadding.small),
          Text(
            label,
            style: TextStyle(
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              fontSize: 15,
              letterSpacing: -0.24,
            ),
          ),
        ],
      ),
    );
  }
}

