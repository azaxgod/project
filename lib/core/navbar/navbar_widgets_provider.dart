import 'package:akimat_project/core/locale/language_switcher.dart';
import 'package:akimat_project/core/navbar/logout_button.dart';
import 'package:akimat_project/core/navbar/user_role_badge.dart';
import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/core/ui/widgets/theme_toggle_button.dart';
import 'package:akimat_project/modules/auth/src/controller/auth_notifier.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/user_role.dart';
import 'package:akimat_project/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class NavbarWidgetsProvider {
  /// Get default web navbar widgets with language switcher
  /// Проверяет роль пользователя и возвращает соответствующий навбар
  static List<Widget> getDefaultWebWidgets(BuildContext context) {
    // Получаем роль пользователя из контекста
    final authNotifier = ProviderScope.containerOf(context).read(authNotifierProvider);
    final user = authNotifier.user;
    final role = user != null ? userRoleFromString(user.role) : UserRole.unknown;
    
    // Для водителя возвращаем упрощенный навбар
    if (role == UserRole.driver) {
      return getDriverWebWidgets(context);
    }
    
    // Для остальных ролей - стандартный навбар
    return getStandardWebWidgets(context);
  }

  /// Навбар для водителя (упрощенный, мобильный-ориентированный)
  static List<Widget> getDriverWebWidgets(BuildContext context) {
    String currentRoute = '/';
    String currentQuery = '';
    try {
      final router = GoRouter.of(context);
      final uri = router.routerDelegate.currentConfiguration.uri;
      currentRoute = uri.path;
      currentQuery = uri.queryParameters['tab'] ?? '';
    } catch (e) {
      // Fallback if route cannot be determined
    }
    
    // Нормализуем currentQuery: '' или 'current' означают первую вкладку
    final normalizedQuery = (currentQuery.isEmpty || currentQuery == 'current') ? 'current' : currentQuery;
    
    return [
      _NavbarButton(
        label: 'Текущий рейс',
        icon: Icons.assignment,
        isActive: currentRoute == '/driver' && normalizedQuery == 'current',
        route: '/driver?tab=current',
      ),
      _NavbarButton(
        label: 'Мои задания',
        icon: Icons.list,
        isActive: currentRoute == '/driver' && normalizedQuery == 'tickets',
        route: '/driver?tab=tickets',
      ),
      _NavbarButton(
        label: 'Карта',
        icon: Icons.map,
        isActive: currentRoute == '/driver' && normalizedQuery == 'map',
        route: '/driver?tab=map',
      ),
      const SizedBox(width: AppPadding.small),
      const UserRoleBadge(), // Отображение роли пользователя
      const SizedBox(width: AppPadding.small),
      const LanguageSwitcher(),
      const SizedBox(width: AppPadding.small),
      const LogoutButtonWeb(), // Кнопка выхода
    ];
  }

  /// Стандартный навбар для остальных ролей
  static List<Widget> getStandardWebWidgets(BuildContext context) {
    String currentRoute = '/';
    try {
      final router = GoRouter.of(context);
      currentRoute = router.routerDelegate.currentConfiguration.uri.path;
    } catch (e) {
      // Fallback if route cannot be determined
    }
    
    // Получаем роль пользователя
    final authNotifier = ProviderScope.containerOf(context).read(authNotifierProvider);
    final user = authNotifier.user;
    final role = user != null ? userRoleFromString(user.role) : UserRole.unknown;
    
    // Для LANDFILL_ADMIN показываем только Мониторинг и Аналитику
    if (role == UserRole.landfillAdmin) {
      return [
        _NavbarButton(
          label: 'Мониторинг',
          icon: Icons.map,
          isActive: currentRoute == '/monitoring' || currentRoute == '/areas' || currentRoute == '/polygons',
          route: '/monitoring',
        ),
        _NavbarButton(
          label: S.of(context)!.analytics,
          icon: Icons.analytics,
          isActive: currentRoute == '/analytics' || currentRoute.startsWith('/analytics/'),
          route: '/analytics',
        ),
        const SizedBox(width: AppPadding.small),
        const ThemeToggleButton(compact: true),
        const SizedBox(width: AppPadding.small),
        const UserRoleBadge(),
        const SizedBox(width: AppPadding.small),
        const LanguageSwitcher(),
        const SizedBox(width: AppPadding.small),
        const LogoutButtonWeb(),
      ];
    }
    
    return [
      _NavbarButton(
        label: S.of(context)!.dashboard,
        icon: Icons.dashboard,
        isActive: currentRoute == '/dashboard',
        route: '/dashboard',
      ),
      _NavbarButton(
        label: S.of(context)!.organizations,
        icon: Icons.business,
        isActive: currentRoute == '/organization',
        route: '/organization',
      ),
      _NavbarButton(
        label: 'Мониторинг',
        icon: Icons.map,
        isActive: currentRoute == '/monitoring' || currentRoute == '/areas' || currentRoute == '/polygons',
        route: '/monitoring',
      ),
      // _NavbarButton(
      //   label: S.of(context)!.tickets,
      //   icon: Icons.assignment,
      //   isActive: currentRoute == '/tickets',
      //   route: '/tickets',
      // ),
      // _NavbarButton(
      //   label: S.of(context)!.contracts,
      //   icon: Icons.receipt_long,
      //   isActive: currentRoute == '/kgu/contracts',
      //   route: '/kgu/contracts',
      // ),
      _NavbarButton(
        label: S.of(context)!.analytics,
        icon: Icons.analytics,
        isActive: currentRoute == '/analytics' || currentRoute.startsWith('/analytics/'),
        route: '/analytics',
      ),
      // Скрыты временно: Отчет и Рейсы о нарушениях
      _NavbarButton(
        label: S.of(context)!.violations,
        icon: Icons.gavel,
        isActive: currentRoute == '/violations' || currentRoute.startsWith('/violations/'),
        route: '/violations',
      ),
      // _NavbarButton(
      //   label: S.of(context)!.trips,
      //   icon: Icons.directions_car,
      //   isActive: false,
      //   onPressed: () {},
      // ),
      // _NavbarButton(
      //   label: S.of(context)!.reports,
      //   icon: Icons.assessment,
      //   isActive: false,
      //   onPressed: () {},
      // ),
      const SizedBox(width: AppPadding.small),
      const ThemeToggleButton(compact: true),
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
      const ThemeToggleButton(compact: true),
      const SizedBox(width: AppPadding.small),
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
  final String? route;

  const _NavbarButton({
    required this.label,
    required this.icon,
    required this.isActive,
    this.route,
  });

  @override
  Widget build(BuildContext context) {
    void handleTap() {
      if (route == null) return;
      try {
        context.go(route!);
      } catch (e) {
        try {
          context.push(route!);
        } catch (_) {}
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Определяем компактный режим по ширине родителя
        final screenWidth = MediaQuery.of(context).size.width;
        final isCompact = screenWidth < 1100;
        final isVeryCompact = screenWidth < 900;
        
        return Tooltip(
          message: label,
          waitDuration: isVeryCompact ? const Duration(milliseconds: 300) : const Duration(seconds: 1),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: handleTap,
              borderRadius: BorderRadius.circular(AppSize.buttonRadius),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isVeryCompact ? 8 : (isCompact ? 10 : AppPadding.normal),
                  vertical: AppPadding.small,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSize.buttonRadius),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: isVeryCompact ? 18 : AppSize.iconSizeSmall,
                      color: isActive
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                    // Показываем текст только на больших экранах
                    if (!isVeryCompact) ...[
                      const SizedBox(width: AppPadding.small),
                      Text(
                        isCompact ? _getShortLabel(label) : label,
                        style: TextStyle(
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                          fontSize: isCompact ? 13 : 15,
                          letterSpacing: -0.24,
                          color: isActive
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  /// Сокращает длинные названия для компактного режима
  String _getShortLabel(String label) {
    // Словарь сокращений
    const shortcuts = {
      'Организации': 'Орг.',
      'Мониторинг': 'Монит.',
      'Задания (Tickets)': 'Задания',
      'Нарушения': 'Наруш.',
      'Аналитика': 'Аналит.',
      'Контракты': 'Контр.',
      'Текущий рейс': 'Рейс',
      'Мои задания': 'Задания',
    };
    return shortcuts[label] ?? label;
  }
}

