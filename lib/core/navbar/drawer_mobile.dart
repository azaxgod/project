import 'package:akimat_project/core/locale/locale_provider.dart';
import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:akimat_project/generated/l10n.dart';
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
  ];
});

class DrawerMobile extends ConsumerWidget {
  const DrawerMobile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch locale to ensure rebuild when language changes
    ref.watch(localeProvider);
    final s = S.of(context);
    final items = ref.watch(mobileDrawerProvider(s));

    return Drawer(
      backgroundColor: AppColors.surface,
      child: Column(
        children: [
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                bottom: BorderSide(
                  color: AppColors.separator,
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppPadding.large),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
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
                  ],
                ),
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
        ],
      ),
    );
  }
}

