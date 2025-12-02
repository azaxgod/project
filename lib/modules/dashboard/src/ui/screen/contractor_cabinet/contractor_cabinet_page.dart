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
import 'package:akimat_project/modules/dashboard/src/ui/screen/contractor_cabinet/widgets/contractor_menu_item.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/contractor_cabinet/contractor_home_page.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/areas/areas_page.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/contractor_cabinet/contractor_drivers_page.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/contractor_cabinet/contractor_vehicles_page.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/tickets/tickets_page.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/monitoring/monitoring_page.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/contractor_cabinet/contractor_acts_page.dart';
import 'package:akimat_project/modules/analytics/src/ui/screen/analytics_dashboard_page.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/contractor_cabinet/contractor_users_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ContractorCabinetPage extends ConsumerStatefulWidget {
  const ContractorCabinetPage({
    super.key,
    required this.scaffoldKey,
    this.webNavbarWidgets,
    this.mobileNavbarWidgets,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;
  final List<Widget>? webNavbarWidgets;
  final List<Widget>? mobileNavbarWidgets;

  @override
  ConsumerState<ContractorCabinetPage> createState() => _ContractorCabinetPageState();
}

class _ContractorCabinetPageState extends ConsumerState<ContractorCabinetPage> {
  int _selectedMenuIndex = 0;

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final s = S.of(context)!;
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final isAdmin = user?.role == 'CONTRACTOR_ADMIN';
    final config = PlatformConfig.instance;

    final menuItems = _buildMenuItems(isAdmin);

    return Scaffold(
      key: widget.scaffoldKey,
      drawer: !kIsWeb ? _buildMobileDrawer(context, menuItems, user?.role ?? 'CONTRACTOR_USER', isAdmin) : null,
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
                                  user?.role ?? 'CONTRACTOR_USER',
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
                              return ContractorMenuItem(
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
        icon: Icons.location_on,
        label: 'Участки уборки',
        onTap: () {},
      ),
      _MenuItems(
        icon: Icons.person,
        label: 'Водители',
        onTap: () {},
      ),
      _MenuItems(
        icon: Icons.local_shipping,
        label: 'Техника',
        onTap: () {},
      ),
      _MenuItems(
        icon: Icons.assignment,
        label: 'Тикеты и рейсы',
        onTap: () {},
      ),
      _MenuItems(
        icon: Icons.map,
        label: 'Мониторинг',
        onTap: () => context.go('/monitoring'),
      ),
      _MenuItems(
        icon: Icons.description,
        label: 'Акты (с КГУ)',
        onTap: () {},
      ),
      _MenuItems(
        icon: Icons.analytics,
        label: 'Аналитика',
        onTap: () => context.go('/analytics'),
      ),
      if (isAdmin)
        _MenuItems(
          icon: Icons.people,
          label: 'Пользователи',
          onTap: () {},
        ),
    ];
  }

  Widget _buildContent(int index, bool isAdmin) {
    switch (index) {
      case 0: // Главная
        return ContractorHomePage(
          scaffoldKey: GlobalKey<ScaffoldState>(),
        );
      case 1: // Участки уборки
        return AreasPage(
          scaffoldKey: GlobalKey<ScaffoldState>(),
        );
      case 2: // Водители
        return ContractorDriversPage(
          scaffoldKey: GlobalKey<ScaffoldState>(),
        );
      case 3: // Техника
        return ContractorVehiclesPage(
          scaffoldKey: GlobalKey<ScaffoldState>(),
        );
      case 4: // Тикеты и рейсы
        return TicketsPage(
          scaffoldKey: GlobalKey<ScaffoldState>(),
        );
      case 5: // Мониторинг
        return MonitoringPage(
          scaffoldKey: GlobalKey<ScaffoldState>(),
        );
      case 6: // Акты
        return ContractorActsPage(
          scaffoldKey: GlobalKey<ScaffoldState>(),
        );
      case 7: // Аналитика
        return AnalyticsDashboardPage(
          scaffoldKey: GlobalKey<ScaffoldState>(),
        );
      case 8: // Пользователи (только для ADMIN)
        if (isAdmin) {
          return ContractorUsersPage(
            scaffoldKey: GlobalKey<ScaffoldState>(),
          );
        }
        return const SizedBox.shrink();
      default:
        return ContractorHomePage(
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
        return 'Участки уборки';
      case 2:
        return 'Водители';
      case 3:
        return 'Техника';
      case 4:
        return 'Тикеты и рейсы';
      case 5:
        return 'Мониторинг';
      case 6:
        return 'Акты';
      case 7:
        return 'Аналитика';
      case 8:
        return 'Пользователи';
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

