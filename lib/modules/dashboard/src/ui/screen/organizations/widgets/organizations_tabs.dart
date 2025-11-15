import 'package:akimat_project/core/platform/platform_utils.dart';
import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/core/ui/app_textstyle.dart';
import 'package:akimat_project/generated/l10n.dart';
import 'package:akimat_project/modules/dashboard/src/controller/organizations_controller.dart';
import 'package:akimat_project/modules/dashboard/src/controller/organizations_state.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/user_role.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_empty_state.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/tabs/organizations_contractors_tab.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/tabs/organizations_drivers_tab.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/tabs/organizations_kgu_zkh_tab.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/tabs/organizations_too_tab.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/tabs/organizations_vehicles_tab.dart';
import 'package:flutter/material.dart';

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

  List<_OrganizationsTabDefinition> _getTabs(BuildContext context) {
    return _buildTabs(
      context,
      widget.state.role,
      widget.state.organizationId,
      widget.data,
    );
  }

  void _updateTabController(int length) {
    if (_tabController?.length != length) {
      _tabController?.dispose();
      _tabController = TabController(length: length, vsync: this);
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final tabs = _getTabs(context);
    
    // Initialize or update TabController
    _updateTabController(tabs.length);
    
    final tabController = _tabController!;
    
    if (tabs.isEmpty) {
      return OrganizationsEmptyState(
        title: s.no_available_tabs,
        message: s.contact_admin_for_permissions,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.config.topOffset > 0) SizedBox(height: widget.config.topOffset),
        Container(
          margin: EdgeInsets.all(widget.config.padding),
          padding: const EdgeInsets.all(AppPadding.large),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppSize.cardRadius),
            border: Border.all(
              color: AppColors.divider,
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: AppSize.shadowBlur,
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppPadding.normal),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSize.cardRadius),
                    ),
                    child: Icon(
                      Icons.business_center,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: AppPadding.normal),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.role_management,
                          style: AppTextStyles.title1,
                        ),
                        const SizedBox(height: AppPadding.xs),
                        Text(
                          s.organizations_contractors_drivers,
                          style: AppTextStyles.footnote,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          margin: EdgeInsets.symmetric(horizontal: widget.config.padding),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSize.cardRadius)),
            border: Border(
              bottom: BorderSide(
                color: AppColors.separator,
                width: 0.5,
              ),
            ),
          ),
          child: TabBar(
            controller: tabController,
            isScrollable: true,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.tab,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 15,
            ),
            tabs: tabs.map((tab) => Tab(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppPadding.small),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getTabIcon(tab.getLabel(context)),
                          size: AppSize.iconSize - 6,
                        ),
                        const SizedBox(width: AppPadding.small),
                        Text(tab.getLabel(context)),
                      ],
                    ),
                  ),
                )).toList(),
          ),
        ),
        Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: widget.config.padding),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppSize.cardRadius)),
            ),
            child: TabBarView(
              controller: tabController,
              children: tabs
                  .map(
                    (tab) => Padding(
                      padding: const EdgeInsets.all(AppPadding.large),
                      child: tab.builder(context, widget.controller),
                    ),
                  )
                  .toList(),
            ),
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
    final s = S.of(context);
    switch (role) {
      case UserRole.akimatAdmin:
        return [
          _OrganizationsTabDefinition(
            getLabel: (ctx) => S.of(ctx).kgu_zkh,
            builder: (context, controller) => OrganizationsKguZkhTab(
              data: data,
              controller: controller,
            ),
          ),
          _OrganizationsTabDefinition(
            getLabel: (ctx) => S.of(ctx).contractors,
            builder: (context, controller) => OrganizationsContractorsTab(
              data: data,
              controller: controller,
            ),
          ),
          _OrganizationsTabDefinition(
            getLabel: (ctx) => S.of(ctx).drivers,
            builder: (context, controller) => OrganizationsDriversTab(
              data: data,
              controller: controller,
              canManage: false,
              organizationId: null,
            ),
          ),
        ];
      case UserRole.kguZkhAdmin:
        if (organizationId != null) {
          return [
            _OrganizationsTabDefinition(
              getLabel: (ctx) => S.of(ctx).contractors,
              builder: (context, controller) => OrganizationsContractorsTab(
                data: data,
                controller: controller,
                parentOrganizationId: organizationId,
              ),
            ),
            _OrganizationsTabDefinition(
              getLabel: (ctx) => S.of(ctx).drivers,
              builder: (context, controller) => OrganizationsDriversTab(
                data: data,
                controller: controller,
                canManage: false,
                organizationId: organizationId,
              ),
            ),
          ];
        }
        return [];
      case UserRole.tooAdmin:
        if (organizationId != null) {
          return [
            _OrganizationsTabDefinition(
              getLabel: (ctx) => S.of(ctx).contractors,
              builder: (context, controller) => OrganizationsContractorsTab(
                data: data,
                controller: controller,
                parentOrganizationId: organizationId,
              ),
            ),
            _OrganizationsTabDefinition(
              getLabel: (ctx) => S.of(ctx).drivers,
              builder: (context, controller) => OrganizationsDriversTab(
                data: data,
                controller: controller,
                canManage: false,
                organizationId: organizationId,
              ),
            ),
          ];
        }
        return [];
      case UserRole.contractorAdmin:
        if (organizationId != null) {
          return [
            _OrganizationsTabDefinition(
              getLabel: (ctx) => S.of(ctx).drivers,
              builder: (context, controller) => OrganizationsDriversTab(
                data: data,
                controller: controller,
                canManage: true,
                organizationId: organizationId,
              ),
            ),
            _OrganizationsTabDefinition(
              getLabel: (ctx) => S.of(ctx).vehicles,
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
      case UserRole.unknown:
        return [];
    }
    // This should never be reached, but satisfies the analyzer
    return [];
  }
}

class _OrganizationsTabDefinition {
  const _OrganizationsTabDefinition({
    required this.getLabel,
    required this.builder,
  });

  final String Function(BuildContext context) getLabel;
  final Widget Function(BuildContext context, OrganizationsController controller) builder;
}

IconData _getTabIcon(String label) {
  if (label.contains('КГУ') || label.contains('KGU')) {
    return Icons.apartment;
  } else if (label.contains('ТОО') || label.contains('TOO')) {
    return Icons.business;
  } else if (label.contains('Подрядчик') || label.contains('Contractor')) {
    return Icons.handshake;
  } else if (label.contains('Водител') || label.contains('Driver')) {
    return Icons.person;
  } else if (label.contains('Транспорт') || label.contains('Vehicle')) {
    return Icons.directions_car;
  }
  return Icons.list;
}

