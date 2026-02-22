import 'dart:math';
import 'package:akimat_project/core/platform/platform_utils.dart';
import 'package:akimat_project/core/storage/tab_storage.dart';
import 'package:akimat_project/modules/dashboard/src/controller/organizations_controller.dart';
import 'package:akimat_project/modules/dashboard/src/controller/organizations_state.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/user_role.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_empty_state.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/tabs/organizations_contractors_tab.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/tabs/organizations_too_tab.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/tabs/organizations_vehicles_tab.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/contractor_cabinet/contractor_users_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:akimat_project/l10n/l10n.dart';

class OrganizationsTabs extends StatefulWidget {
  const OrganizationsTabs({
    super.key,
    required this.config,
    required this.state,
    required this.data,
    required this.controller,
  });

  final PlatformConfig config;
  final OrganizationsState state;
  final OrganizationsData data;
  final OrganizationsController controller;

  @override
  State<OrganizationsTabs> createState() => _OrganizationsTabsState();
}

class _OrganizationsTabsState extends State<OrganizationsTabs>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  int? _savedTabIndex;
  bool _isInitializing = true;
  String? _lastTabParam;
  static const String _storageKey = 'organizations_tabs';

  @override
  void initState() {
    super.initState();
    _loadSavedTabIndex();
  }

  @override
  void didUpdateWidget(OrganizationsTabs oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Если данные изменились, нужно перепроверить длину табов
    final tabs = _getTabs(context);

    // Если TabController существует и длина табов изменилась, пересоздаем контроллер
    if (_tabController != null && _tabController!.length != tabs.length) {
      final currentIndex = _tabController!.index;
      _tabController?.removeListener(_onTabChanged);
      _tabController?.dispose();

      // Создаем новый контроллер с корректной длиной
      int newIndex = 0;
      if (currentIndex < tabs.length) {
        newIndex = currentIndex;
      } else if (_savedTabIndex != null && _savedTabIndex! < tabs.length) {
        newIndex = _savedTabIndex!;
      }

      _tabController = TabController(
        length: tabs.length,
        vsync: this,
        initialIndex: newIndex,
      );
      _tabController!.addListener(_onTabChanged);

      // Синхронизируем после обновления
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _syncTabFromRoute();
        }
      });
    }
  }

  Future<void> _loadSavedTabIndex() async {
    final savedIndex = await TabStorage.getTabIndex(_storageKey);
    if (mounted) {
      setState(() {
        _savedTabIndex = savedIndex;
        _isInitializing = false;
      });
      // Синхронизируем с URL после загрузки
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _syncTabFromRoute();
        }
      });
    }
  }

  void _onTabChanged() {
    if (_tabController != null && !_tabController!.indexIsChanging && mounted) {
      // Сохраняем индекс в локальное хранилище
      TabStorage.saveTabIndex(_storageKey, _tabController!.index);
      // Обновляем URL с параметром вкладки
      _updateRouteFromTab(_tabController!.index);
    }
  }

  /// Обновляет URL при переключении вкладки
  void _updateRouteFromTab(int index) {
    if (!mounted) return;

    try {
      final router = GoRouter.of(context);
      final currentUri = router.routerDelegate.currentConfiguration.uri;
      final currentTab = currentUri.queryParameters['tab'] ?? '';

      final tabParam = index.toString();

      // Если URL уже правильный, не обновляем
      if (currentTab == tabParam) {
        return;
      }

      // Обновляем _lastTabParam
      _lastTabParam = tabParam;

      // Обновляем URL с параметром вкладки
      final newRoute = '/organization?tab=$tabParam';
      router.go(newRoute);
    } catch (e) {
      debugPrint('Error updating route from tab: $e');
    }
  }

  /// Синхронизирует вкладку с query параметром из роута
  void _syncTabFromRoute() {
    if (!mounted || _tabController == null) return;

    try {
      final router = GoRouter.of(context);
      final uri = router.routerDelegate.currentConfiguration.uri;
      final tab = uri.queryParameters['tab'];

      final tabs = _getTabs(context);
      if (tabs.isEmpty) return;

      // Получаем актуальную длину табов из контроллера
      final controllerLength = _tabController!.length;

      // Если длина изменилась, нужно пересоздать контроллер
      if (controllerLength != tabs.length) {
        debugPrint(
            'Tab length changed from $controllerLength to ${tabs.length}, skipping sync');
        return;
      }

      int tabIndex = _savedTabIndex ?? 0;
      if (tab != null && tab.isNotEmpty) {
        final parsedIndex = int.tryParse(tab);
        if (parsedIndex != null &&
            parsedIndex >= 0 &&
            parsedIndex < tabs.length) {
          tabIndex = parsedIndex;
        } else {
          // Если индекс из URL невалиден, используем 0
          tabIndex = 0;
        }
      }

      // Дополнительная проверка валидности индекса
      if (tabIndex < 0 || tabIndex >= tabs.length) {
        debugPrint(
            'Invalid tab index: $tabIndex, tabs length: ${tabs.length}, resetting to 0');
        tabIndex = 0;
      }

      // Обновляем вкладку только если она отличается от текущей и индекс валиден
      if (_tabController!.index != tabIndex &&
          tabIndex >= 0 &&
          tabIndex < tabs.length) {
        // Временно отключаем слушатель, чтобы избежать цикла
        _tabController!.removeListener(_onTabChanged);
        try {
          _tabController!.animateTo(tabIndex);
        } catch (e) {
          debugPrint('Error animating to tab $tabIndex: $e');
        }
        // Включаем слушатель обратно после небольшой задержки
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && _tabController != null) {
            _tabController!.addListener(_onTabChanged);
          }
        });
      }

      _lastTabParam = tab ?? tabIndex.toString();
    } catch (e) {
      debugPrint('Error syncing tab from route: $e');
    }
  }

  @override
  void dispose() {
    _tabController?.removeListener(_onTabChanged);
    _tabController?.dispose();
    super.dispose();
  }

  List<_OrganizationsTabDefinition> _getTabs(BuildContext context) {
    return _buildTabs(
      context,
      widget.state.role,
      widget.state.organizationId,
      widget.data,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final tabs = _getTabs(context);

    if (tabs.isEmpty) {
      return OrganizationsEmptyState(
        title: s!.no_available_tabs,
        message: s.contact_admin_for_permissions,
      );
    }

    // Проверяем, что TabController все еще валиден после обновления данных
    if (_tabController != null && _tabController!.length != tabs.length) {
      // Если длина изменилась, контроллер будет пересоздан в didUpdateWidget
      // Здесь просто показываем loading, чтобы избежать ошибок
      return const Center(child: CircularProgressIndicator());
    }

    // Инициализируем TabController с сохраненным индексом или из URL
    if (_tabController == null && !_isInitializing) {
      int initialIndex = 0;

      // Сначала проверяем URL параметр
      try {
        final router = GoRouter.of(context);
        final uri = router.routerDelegate.currentConfiguration.uri;
        final tab = uri.queryParameters['tab'];
        if (tab != null && tab.isNotEmpty) {
          final parsedIndex = int.tryParse(tab);
          if (parsedIndex != null &&
              parsedIndex >= 0 &&
              parsedIndex < tabs.length) {
            initialIndex = parsedIndex;
          }
        } else if (_savedTabIndex != null &&
            _savedTabIndex! >= 0 &&
            _savedTabIndex! < tabs.length) {
          initialIndex = _savedTabIndex!;
        }
      } catch (e) {
        // Используем сохраненный индекс как fallback
        if (_savedTabIndex != null &&
            _savedTabIndex! >= 0 &&
            _savedTabIndex! < tabs.length) {
          initialIndex = _savedTabIndex!;
        }
      }

      // Финальная проверка валидности индекса
      if (initialIndex < 0 || initialIndex >= tabs.length) {
        initialIndex = 0;
      }

      _tabController = TabController(
        length: tabs.length,
        vsync: this,
        initialIndex: initialIndex,
      );
      _tabController!.addListener(_onTabChanged);
      _lastTabParam = initialIndex.toString();

      // Синхронизируем с URL после создания контроллера
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _syncTabFromRoute();
        }
      });
    }

    // Слушаем изменения роута и синхронизируем вкладку
    if (_tabController != null) {
      try {
        final router = GoRouter.of(context);
        final uri = router.routerDelegate.currentConfiguration.uri;
        final currentTabParam = uri.queryParameters['tab'] ?? '';

        // Если tab параметр изменился, синхронизируем вкладку
        if (currentTabParam != _lastTabParam) {
          _lastTabParam = currentTabParam;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _syncTabFromRoute();
            }
          });
        }
      } catch (e) {
        // Игнорируем ошибки
      }
    }

    // Показываем индикатор загрузки пока ждем сохраненный индекс
    if (_tabController == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.config.topOffset > 0)
          SizedBox(height: widget.config.topOffset),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: widget.config.padding,
            vertical: 8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s!.role_management,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Полигоны по вывозу снега, подрядчики и транспорт',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
        TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Theme.of(context).colorScheme.primary,
          indicatorColor: Theme.of(context).colorScheme.primary,
          tabs: tabs.map((tab) => Tab(text: tab.getLabel(context))).toList(),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: tabs
                .map(
                  (tab) => Padding(
                    padding: EdgeInsets.all(
                      max(widget.config.padding, 16),
                    ),
                    child: tab.builder(context, widget.controller),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  List<_OrganizationsTabDefinition> _buildTabs(
    BuildContext context,
    UserRole role,
    String? organizationId,
    OrganizationsData data,
  ) {
    // final s = S.of(context);

    switch (role) {
      case UserRole.akimatAdmin:
        return [
          _OrganizationsTabDefinition(
            getLabel: (ctx) => 'Полигоны по вывозу снега',
            builder: (context, controller) => OrganizationsTooTab(
              data: data,
              controller: controller,
              userRole: role,
            ),
          ),
          _OrganizationsTabDefinition(
            getLabel: (ctx) => S.of(ctx)!.contractors,
            builder: (context, controller) => OrganizationsContractorsTab(
              data: data,
              controller: controller,
              canManage: false, // AKIMAT_ADMIN только просматривает
            ),
          ),
          _OrganizationsTabDefinition(
            getLabel: (ctx) => S.of(ctx)!.vehicles,
            builder: (context, controller) => OrganizationsVehiclesTab(
              data: data,
              controller: controller,
              showAll:
                  true, // AKIMAT_ADMIN видит весь транспорт, как KGU_ZKH_ADMIN
            ),
          ),
        ];
      case UserRole.kguZkhAdmin:
        // Вкладки показываются только если organizationId != null
        if (organizationId != null) {
          return [
            _OrganizationsTabDefinition(
              getLabel: (ctx) => S.of(ctx)!.contractors,
              builder: (context, controller) => OrganizationsContractorsTab(
                data: data,
                controller: controller,
                parentOrganizationId: organizationId,
              ),
            ),
            _OrganizationsTabDefinition(
              getLabel: (ctx) => S.of(ctx)!.vehicles,
              builder: (context, controller) => OrganizationsVehiclesTab(
                data: data,
                controller: controller,
                showAll: true, // KGU_ZKH видит весь транспорт
              ),
            ),
          ];
        }
        return [];
      case UserRole.landfillAdmin:
        if (organizationId != null) {
          return [
            _OrganizationsTabDefinition(
              getLabel: (ctx) => S.of(ctx)!.contractors,
              builder: (context, controller) => OrganizationsContractorsTab(
                data: data,
                controller: controller,
                parentOrganizationId: organizationId,
              ),
            ),
          ];
        }
        return [];
      case UserRole.contractorAdmin:
        if (organizationId != null) {
          return [
            _OrganizationsTabDefinition(
              getLabel: (ctx) => 'Пользователи подрядчика',
              builder: (context, controller) => ContractorUsersPage(
                scaffoldKey: GlobalKey<ScaffoldState>(),
              ),
            ),
            _OrganizationsTabDefinition(
              getLabel: (ctx) => S.of(ctx)!.vehicles,
              builder: (context, controller) => OrganizationsVehiclesTab(
                data: data,
                controller: controller,
                contractorId: organizationId,
              ),
            ),
          ];
        }
        return [];
      case UserRole.driver:
        return [];
      case UserRole.akimatUser:
      case UserRole.kguZkhUser:
      case UserRole.landfillUser:
      case UserRole.contractorUser:
      case UserRole.unknown:
        return [];
    }
  }
}

class _OrganizationsTabDefinition {
  const _OrganizationsTabDefinition({
    required this.getLabel,
    required this.builder,
  });

  final String Function(BuildContext context) getLabel;
  final Widget Function(
      BuildContext context, OrganizationsController controller) builder;
}
