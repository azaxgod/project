import 'dart:math';
import 'package:akimat_project/core/platform/platform_utils.dart';
import 'package:akimat_project/generated/l10n.dart' hide S;
import 'package:akimat_project/modules/dashboard/src/controller/organizations_controller.dart';
import 'package:akimat_project/modules/dashboard/src/controller/organizations_state.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/user_role.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_empty_state.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/tabs/organizations_contractors_tab.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/tabs/organizations_drivers_tab.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/tabs/organizations_too_tab.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/tabs/organizations_vehicles_tab.dart';
import 'package:flutter/material.dart';
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

class _OrganizationsTabsState extends State<OrganizationsTabs> {
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

    return DefaultTabController(
      length: tabs.length,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.config.topOffset > 0) SizedBox(height: widget.config.topOffset),
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
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  s.organizations_contractors_drivers,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
          TabBar(
            isScrollable: true,
            labelColor: Theme.of(context).colorScheme.primary,
            indicatorColor: Theme.of(context).colorScheme.primary,
            tabs: tabs.map((tab) => Tab(text: tab.getLabel(context))).toList(),
          ),
          Expanded(
            child: TabBarView(
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
      ),
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
            getLabel: (ctx) => S.of(ctx)!.too,
            builder: (context, controller) => OrganizationsTooTab(
              data: data,
              controller: controller,
            ),
          ),
          _OrganizationsTabDefinition(
            getLabel: (ctx) => S.of(ctx)!.contractors,
            builder: (context, controller) => OrganizationsContractorsTab(
              data: data,
              controller: controller,
            ),
          ),
          _OrganizationsTabDefinition(
            getLabel: (ctx) => S.of(ctx)!.drivers,
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
              getLabel: (ctx) => S.of(ctx)!.contractors,
              builder: (context, controller) => OrganizationsContractorsTab(
                data: data,
                controller: controller,
                parentOrganizationId: organizationId,
              ),
            ),
            _OrganizationsTabDefinition(
              getLabel: (ctx) => S.of(ctx)!.drivers,
              builder: (context, controller) => OrganizationsDriversTab(
                data: data,
                controller: controller,
                canManage: false,
                organizationId: organizationId,
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
            _OrganizationsTabDefinition(
              getLabel: (ctx) => S.of(ctx)!.drivers,

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
              getLabel: (ctx) => S.of(ctx)!.drivers,
              builder: (context, controller) => OrganizationsDriversTab(
                data: data,
                controller: controller,
                canManage: true,
                organizationId: organizationId,
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
  final Widget Function(BuildContext context, OrganizationsController controller) builder;
}

