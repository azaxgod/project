import 'package:akimat_project/modules/dashboard/src/controller/organizations_controller.dart';
import 'package:akimat_project/modules/dashboard/src/controller/organizations_state.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/organization_type.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_data_table.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_empty_state.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_status_chip.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_tab_header.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_table_actions.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/dialogs/organizations_details_dialogs.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/dialogs/organizations_dialogs.dart';
import 'package:flutter/material.dart';

class OrganizationsContractorsTab extends StatelessWidget {
  const OrganizationsContractorsTab({
    super.key,
    required this.data,
    required this.controller,
    this.parentOrganizationId,
  });

  final OrganizationsData data;
  final OrganizationsController controller;
  final String? parentOrganizationId;

  bool get _shouldShowParentColumn => parentOrganizationId == null;

  @override
  Widget build(BuildContext context) {
    final contractors = data.organizations.where((organization) {
      if (organization.type != OrganizationType.contractor) return false;
      if (parentOrganizationId == null) return true;
      return organization.parentOrgId == parentOrganizationId;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        OrganizationsTabHeader(
          title: 'Подрядчики',
          subtitle: parentOrganizationId == null
              ? 'Управление подрядчиками всех КГУ ЖКХ'
              : 'Подрядчики текущего КГУ ЖКХ',
          actionLabel: '+ Добавить подрядчика',
          onAction: () => OrganizationsDialogs.showOrganizationDialog(
            context: context,
            controller: controller,
            type: OrganizationType.contractor,
            data: data,
            parentOrganizationId: parentOrganizationId,
          ),
        ),
        const SizedBox(height: 12),
        if (contractors.isEmpty)
          const OrganizationsEmptyState(
            title: 'Нет подрядчиков',
            message: 'Добавьте подрядчика, чтобы управлять водителями и транспортом.',
          )
        else
          OrganizationsDataTable(
            columns: [
              const DataColumn(label: Text('Название')),
              const DataColumn(label: Text('БИН')),
              if (_shouldShowParentColumn) const DataColumn(label: Text('Родительская организация KGU ZKH')),
              const DataColumn(label: Text('Руководитель')),
              const DataColumn(label: Text('Телефон')),
              const DataColumn(label: Text('Статус')),
              const DataColumn(label: Text('Действия')),
            ],
            rows: contractors.map((contractor) {
              final parentName = contractor.parentOrgId == null
                  ? '—'
                  : data.organizations
                          .firstWhere(
                            (org) =>
                                org.id == contractor.parentOrgId &&
                                (org.type == OrganizationType.kguZkh || org.type == OrganizationType.too),
                            orElse: () => contractor,
                          )
                          .name;
              return DataRow(
                cells: [
                  DataCell(Text(contractor.name, overflow: TextOverflow.ellipsis)),
                  DataCell(Text(contractor.bin, overflow: TextOverflow.ellipsis)),
                  if (_shouldShowParentColumn) DataCell(Text(parentName, overflow: TextOverflow.ellipsis)),
                  DataCell(Text(contractor.headFullName ?? '—', overflow: TextOverflow.ellipsis)),
                  DataCell(Text(contractor.phone ?? '—', overflow: TextOverflow.ellipsis)),
                  DataCell(OrganizationsStatusChip(isActive: contractor.isActive)),
                  DataCell(
                    OrganizationsTableActions(
                      actions: [
                        OrganizationsTableAction(
                          label: 'Подробнее',
                          onPressed: () => OrganizationsDetailsDialogs.showOrganizationDetails(
                            context: context,
                            organization: contractor,
                            data: data,
                          ),
                        ),
                        OrganizationsTableAction(
                          label: contractor.isActive ? 'Блокировать' : 'Разблокировать',
                          isDestructive: contractor.isActive,
                          onPressed: () => controller.updateOrganization(
                            contractor.copyWith(isActive: !contractor.isActive),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
      ],
    );
  }
}

