import 'package:akimat_project/core/locale/locale_provider.dart';
import 'package:akimat_project/core/navbar/logout_button.dart';
import 'package:akimat_project/core/navbar/user_role_badge.dart';
import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/modules/auth/src/controller/auth_notifier.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/user_role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:akimat_project/l10n/l10n.dart';
import 'package:go_router/go_router.dart';

class DrawerItem {
  final String title;
  final IconData icon;
  final String route;

  DrawerItem({
    required this.title,
    required this.icon,
    required this.route,
  });
}

final mobileDrawerProvider = Provider.family<List<DrawerItem>, S>((ref, s) {
  return [
    DrawerItem(
      title: s.dashboard,
      icon: Icons.dashboard,
      route: '/dashboard',
    ),
    DrawerItem(
      title: s.organizations,
      icon: Icons.business,
      route: '/organization',
    ),
    DrawerItem(
      title: s.areas,
      icon: Icons.area_chart,
      route: '/areas',
    ),
    DrawerItem(
      title: s.polygons,
      icon: Icons.map,
      route: '/polygons',
    ),
    DrawerItem(
      title: s.tickets,
      icon: Icons.assignment,
      route: '/tickets',
    ),
    DrawerItem(
      title: s.contracts,
      icon: Icons.receipt_long,
      route: '/kgu/contracts',
    ),
  ];
});

class DrawerMobile extends ConsumerWidget {
  const DrawerMobile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch locale to ensure rebuild when language changes
    ref.watch(localeProvider);
    final s = S.of(context)!;
    final items = ref.watch(mobileDrawerProvider(s));

    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final role = user != null ? userRoleFromString(user.role) : UserRole.unknown;

    String _getRoleLabel(UserRole role) {
      switch (role) {
        case UserRole.akimatAdmin:
          return 'Акимат';
        case UserRole.kguZkhAdmin:
          return 'KGU ZKH';
        case UserRole.tooAdmin:
          return 'TOO';
        case UserRole.contractorAdmin:
          return 'Подрядчик';
        case UserRole.driver:
          return 'Водитель';
        case UserRole.unknown:
          return 'Неизвестно';
      }
    }

    Color _getRoleColor(UserRole role) {
      switch (role) {
        case UserRole.akimatAdmin:
          return Colors.blue;
        case UserRole.kguZkhAdmin:
          return Colors.green;
        case UserRole.tooAdmin:
          return Colors.orange;
        case UserRole.contractorAdmin:
          return Colors.purple;
        case UserRole.driver:
          return Colors.teal;
        case UserRole.unknown:
          return Colors.grey;
      }
    }

    IconData _getRoleIcon(UserRole role) {
      switch (role) {
        case UserRole.akimatAdmin:
          return Icons.admin_panel_settings;
        case UserRole.kguZkhAdmin:
          return Icons.business;
        case UserRole.tooAdmin:
          return Icons.engineering;
        case UserRole.contractorAdmin:
          return Icons.business_center;
        case UserRole.driver:
          return Icons.drive_eta;
        case UserRole.unknown:
          return Icons.person;
      }
    }

    return Drawer(
      backgroundColor: AppColors.surface,
      child: Column(
        children: [
          // Заголовок с логотипом и ролью
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(AppPadding.large),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.separator,
                    width: 0.5,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppPadding.small),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppSize.smallRadius),
                        ),
                        child: Icon(
                          Icons.snowing,
                          color: AppColors.primary,
                          size: AppSize.iconSizeLarge,
                        ),
                      ),
                      const SizedBox(width: AppPadding.normal),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SnowOps',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.36,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              s.menu,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 15,
                                letterSpacing: -0.24,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppPadding.normal),
                  // Отображение роли пользователя
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppPadding.normal,
                      vertical: AppPadding.small,
                    ),
                    decoration: BoxDecoration(
                      color: _getRoleColor(role).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSize.buttonRadius),
                      border: Border.all(
                        color: _getRoleColor(role).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getRoleIcon(role),
                          size: 18,
                          color: _getRoleColor(role),
                        ),
                        const SizedBox(width: AppPadding.small),
                        Text(
                          _getRoleLabel(role),
                          style: TextStyle(
                            color: _getRoleColor(role),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Разделитель после роли
                  const SizedBox(height: AppPadding.normal),
                  Divider(
                    color: AppColors.separator,
                    height: 1,
                    thickness: 0.5,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppPadding.small),
              children: [
                ...items.map((item) => Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: AppPadding.small,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppSize.cardRadius),
                        color: Colors.transparent,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppPadding.normal,
                          vertical: AppPadding.small,
                        ),
                        leading: Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppSize.smallRadius),
                          ),
                          child: Icon(
                            item.icon,
                            color: AppColors.primary,
                            size: AppSize.iconSizeSmall,
                          ),
                        ),
                        title: Text(
                          item.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.normal,
                            fontSize: 17,
                            letterSpacing: -0.41,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSize.buttonRadius),
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                          context.go(item.route);
                        },
                      ),
                    )),
              ],
            ),
          ),
          // Кнопка выхода внизу drawer
          const LogoutButtonMobile(),
        ],
      ),
    );
  }
}

