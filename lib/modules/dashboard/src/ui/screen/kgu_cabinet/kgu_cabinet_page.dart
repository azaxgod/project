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
import 'package:akimat_project/modules/dashboard/src/ui/screen/kgu_cabinet/widgets/kgu_menu_item.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/kgu_cabinet/kgu_home_page.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/kgu_cabinet/contractors_page.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/kgu_cabinet/landfills_page.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/polygons/polygons_page.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/contracts/contracts_page.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/kgu_cabinet/acts_page.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/monitoring/monitoring_page.dart';
import 'package:akimat_project/modules/analytics/src/ui/screen/analytics_dashboard_page.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/kgu_cabinet/kgu_users_page.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/akimat_cabinet/organizational_structure_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class KguCabinetPage extends ConsumerStatefulWidget {
  const KguCabinetPage({
    super.key,
    required this.scaffoldKey,
    this.webNavbarWidgets,
    this.mobileNavbarWidgets,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;
  final List<Widget>? webNavbarWidgets;
  final List<Widget>? mobileNavbarWidgets;

  @override
  ConsumerState<KguCabinetPage> createState() => _KguCabinetPageState();
}

class _KguCabinetPageState extends ConsumerState<KguCabinetPage> {
  int _selectedMenuIndex = 0;

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final s = S.of(context)!;
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final isAdmin = user?.role == 'KGU_ZKH_ADMIN';
    final config = PlatformConfig.instance;

    final menuItems = _buildMenuItems(isAdmin);

    return Scaffold(
      key: widget.scaffoldKey,
      drawer: !kIsWeb ? _buildMobileDrawer(context, menuItems, user?.role ?? 'KGU_ZKH_USER', isAdmin) : null,
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
                                'Личный кабинет КГУ',
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
                                  user?.role ?? 'KGU_ZKH_USER',
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
                              return KguMenuItem(
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
                  child: _buildContent(_selectedMenuIndex, isAdmin),
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

  List<_MenuItems> _buildMenuItems(bool isAdmin) {
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
      if (isAdmin)
        _MenuItems(
          icon: Icons.people,
          label: 'Пользователи КГУ',
          onTap: () {},
        ),
      _MenuItems(
        icon: Icons.local_shipping,
        label: 'Подрядчики',
        onTap: () {},
      ),
      _MenuItems(
        icon: Icons.delete_outline,
        label: 'Организации приёма снега (LANDFILL)',
        onTap: () {},
      ),
      _MenuItems(
        icon: Icons.map,
        label: 'Полигоны',
        onTap: () {},
      ),
      _MenuItems(
        icon: Icons.receipt_long,
        label: 'Контракты',
        onTap: () {},
      ),
      _MenuItems(
        icon: Icons.description,
        label: 'Акты',
        onTap: () {},
      ),
      _MenuItems(
        icon: Icons.map,
        label: 'Мониторинг',
        onTap: () => context.go('/monitoring'),
      ),
      _MenuItems(
        icon: Icons.analytics,
        label: 'Аналитика',
        onTap: () => context.go('/analytics'),
      ),
    ];
  }

  Widget _buildContent(int index, bool isAdmin) {
    switch (index) {
      case 0: // Главная
        return KguHomePage(
          scaffoldKey: GlobalKey<ScaffoldState>(),
        );
      case 1: // Организационная структура
        return OrganizationalStructurePage(
          scaffoldKey: GlobalKey<ScaffoldState>(),
        );
      case 2: // Пользователи КГУ (только для ADMIN)
        if (isAdmin) {
          return KguUsersPage(
            scaffoldKey: GlobalKey<ScaffoldState>(),
          );
        }
        return const SizedBox.shrink();
      case 3: // Подрядчики
        return ContractorsPage(
          scaffoldKey: GlobalKey<ScaffoldState>(),
        );
      case 4: // Организации приёма снега
        return LandfillsPage(
          scaffoldKey: GlobalKey<ScaffoldState>(),
        );
      case 5: // Полигоны
        return PolygonsPage(
          scaffoldKey: GlobalKey<ScaffoldState>(),
        );
      case 6: // Контракты
        return ContractsPage(
          scaffoldKey: GlobalKey<ScaffoldState>(),
        );
      case 7: // Акты
        return ActsPage(
          scaffoldKey: GlobalKey<ScaffoldState>(),
        );
      case 8: // Мониторинг
        return MonitoringPage(
          scaffoldKey: GlobalKey<ScaffoldState>(),
        );
      case 9: // Аналитика
        return AnalyticsDashboardPage(
          scaffoldKey: GlobalKey<ScaffoldState>(),
        );
      default:
        return KguHomePage(
          scaffoldKey: GlobalKey<ScaffoldState>(),
        );
    }
  }

  Widget _buildMobileDrawer(
    BuildContext context,
    List<_MenuItems> menuItems,
    String role,
    bool isAdmin,
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
                  'Личный кабинет КГУ',
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
        return 'Пользователи КГУ';
      case 3:
        return 'Подрядчики';
      case 4:
        return 'Организации приёма снега';
      case 5:
        return 'Полигоны';
      case 6:
        return 'Контракты';
      case 7:
        return 'Акты';
      case 8:
        return 'Мониторинг';
      case 9:
        return 'Аналитика';
      default:
        return 'Личный кабинет КГУ';
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

