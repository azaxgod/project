import 'package:akimat_project/core/locale/locale_provider.dart';
import 'package:akimat_project/core/navbar/header_navbar.dart';
import 'package:akimat_project/core/navbar/navbar_widgets_provider.dart';
import 'package:akimat_project/core/platform/platform_utils.dart';
import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/core/ui/app_textstyle.dart';
import 'package:akimat_project/core/widgets/app_footer.dart';
import 'package:akimat_project/l10n/l10n.dart';
import 'package:akimat_project/modules/auth/src/controller/auth_notifier.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/akimat_cabinet/widgets/akimat_menu_item.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/akimat_dashboard/akimat_home.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/akimat_cabinet/organizational_structure_page.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/akimat_cabinet/kgu_zkh_page.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/users/akimat_users_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AkimatCabinetPage extends ConsumerStatefulWidget {
  const AkimatCabinetPage({
    super.key,
    required this.scaffoldKey,
    this.webNavbarWidgets,
    this.mobileNavbarWidgets,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;
  final List<Widget>? webNavbarWidgets;
  final List<Widget>? mobileNavbarWidgets;

  @override
  ConsumerState<AkimatCabinetPage> createState() => _AkimatCabinetPageState();
}

class _AkimatCabinetPageState extends ConsumerState<AkimatCabinetPage> {
  int _selectedMenuIndex = 0;

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final s = S.of(context)!;
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final isSuperAdmin = user?.role == 'AKIMAT_ADMIN';
    final config = PlatformConfig.instance;

    final menuItems = _buildMenuItems(isSuperAdmin);

    return Scaffold(
      key: widget.scaffoldKey,
      drawer: !kIsWeb ? _buildMobileDrawer(context, menuItems, user?.role ?? 'AKIMAT_USER', isSuperAdmin) : null,
      appBar: !kIsWeb
          ? AppBar(
              title: Text(_getMenuLabel(_selectedMenuIndex)),
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              actions: NavbarWidgetsProvider.combineMobileWidgets(
                context,
                widget.mobileNavbarWidgets,
              ),
            )
          : null,
      body: Column(
        children: [
          if (kIsWeb)
            HeaderNavbar(
              webWidgets: widget.webNavbarWidgets,
            ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Боковое меню
                if (kIsWeb)
                  Container(
                    width: 280,
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      border: Border(
                        right: BorderSide(
                          color: AppColors.divider,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Заголовок
                        Container(
                          padding: const EdgeInsets.all(AppPadding.large),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: AppColors.divider,
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Личный кабинет',
                                style: AppTextStyles.title2,
                              ),
                              const SizedBox(height: AppPadding.xs),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppPadding.small,
                                  vertical: AppPadding.xs,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(
                                    AppSize.smallRadius,
                                  ),
                                ),
                                child: Text(
                                  user?.role ?? 'AKIMAT_USER',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Меню
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppPadding.normal,
                            ),
                            children: menuItems.asMap().entries.map((entry) {
                              final index = entry.key;
                              final item = entry.value;
                              return AkimatMenuItem(
                                icon: item.icon,
                                label: item.label,
                                isSelected: _selectedMenuIndex == index,
                                onTap: () {
                                  setState(() {
                                    _selectedMenuIndex = index;
                                  });
                                  item.onTap();
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
          if (kIsWeb)
            const VerticalDivider(thickness: 1, width: 1),
                // Контент
                Expanded(
                  child: _buildContent(_selectedMenuIndex),
                ),
              ],
            ),
          ),
          // Футер с версией (только для web)
          if (kIsWeb) const AppFooter(),
        ],
      ),
    );
  }

  List<_MenuItems> _buildMenuItems(bool isSuperAdmin) {
    return [
      _MenuItems(
        icon: Icons.dashboard,
        label: 'Главная',
        onTap: () {},
      ),
      _MenuItems(
        icon: Icons.account_tree,
        label: 'Организационная структура',
        onTap: () {},
      ),
      if (isSuperAdmin)
        _MenuItems(
          icon: Icons.people,
          label: 'Пользователи Акимата',
          onTap: () {},
        ),
      _MenuItems(
        icon: Icons.business,
        label: 'KGU ЖКХ',
        onTap: () {},
      ),
      _MenuItems(
        icon: Icons.map,
        label: 'Мониторинг (город)',
        onTap: () => context.go('/monitoring'),
      ),
      _MenuItems(
        icon: Icons.analytics,
        label: 'Аналитика (город)',
        onTap: () => context.go('/analytics'),
      ),
    ];
  }

  Widget _buildContent(int index) {
    switch (index) {
      case 0: // Главная
        return AkimatHome(
          scaffoldKey: GlobalKey<ScaffoldState>(),
        );
      case 1: // Организационная структура
        return OrganizationalStructurePage(
          scaffoldKey: GlobalKey<ScaffoldState>(),
        );
      case 2: // Пользователи Акимата (только для SUPER_ADMIN)
        final authState = ref.read(authNotifierProvider);
        final user = authState.user;
        if (user?.role == 'AKIMAT_ADMIN') {
          return AkimatUsersPage(
            scaffoldKey: GlobalKey<ScaffoldState>(),
          );
        }
        return const SizedBox.shrink();
      case 3: // KGU ЖКХ
        return KguZkhPage(
          scaffoldKey: GlobalKey<ScaffoldState>(),
        );
      default:
        return AkimatHome(
          scaffoldKey: GlobalKey<ScaffoldState>(),
        );
    }
  }

  Widget _buildMobileDrawer(
    BuildContext context,
    List<_MenuItems> menuItems,
    String role,
    bool isSuperAdmin,
  ) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: AppColors.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Личный кабинет',
                  style: AppTextStyles.title2.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppPadding.small),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppPadding.small,
                    vertical: AppPadding.xs,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(
                      AppSize.smallRadius,
                    ),
                  ),
                  child: Text(
                    role,
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppPadding.normal),
              children: menuItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return ListTile(
                  leading: Icon(
                    item.icon,
                    color: _selectedMenuIndex == index
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  title: Text(
                    item.label,
                    style: AppTextStyles.body.copyWith(
                      color: _selectedMenuIndex == index
                          ? AppColors.primary
                          : AppColors.textPrimary,
                      fontWeight: _selectedMenuIndex == index
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  selected: _selectedMenuIndex == index,
                  selectedTileColor: AppColors.primary.withOpacity(0.1),
                  onTap: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _selectedMenuIndex = index;
                    });
                    item.onTap();
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _getMenuLabel(int index) {
    switch (index) {
      case 0:
        return 'Главная';
      case 1:
        return 'Организационная структура';
      case 2:
        return 'Пользователи Акимата';
      case 3:
        return 'KGU ЖКХ';
      default:
        return 'Личный кабинет';
    }
  }
}

class _MenuItems {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  _MenuItems({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

