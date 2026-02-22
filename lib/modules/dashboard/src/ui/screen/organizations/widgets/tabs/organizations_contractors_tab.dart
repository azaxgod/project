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
    this.canManage = true,
  });

  final OrganizationsData data;
  final OrganizationsController controller;
  final String? parentOrganizationId;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final contractors = data.organizations.where((organization) {
      if (organization.type != OrganizationType.contractor) return false;
      if (parentOrganizationId == null) return true;
      return organization.parentOrgId == parentOrganizationId;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OrganizationsTabHeader(
          title: 'Подрядчики',
          subtitle: parentOrganizationId == null
              ? (canManage
                  ? 'Управление подрядчиками всех КГУ ЖКХ'
                  : 'Просмотр подрядчиков всех КГУ ЖКХ')
              : (canManage
                  ? 'Подрядчики текущего КГУ ЖКХ'
                  : 'Просмотр подрядчиков текущего КГУ ЖКХ'),
          actionLabel: canManage ? 'Добавить подрядчика' : null,
          onAction: canManage
              ? () => OrganizationsDialogs.showOrganizationDialog(
                    context: context,
                    controller: controller,
                    type: OrganizationType.contractor,
                    data: data,
                    parentOrganizationId: parentOrganizationId,
                  )
              : () {},
        ),
        const SizedBox(height: 12),
        if (contractors.isEmpty)
          const Expanded(
            child: OrganizationsEmptyState(
              title: 'Нет подрядчиков',
              message:
                  'Добавьте подрядчика, чтобы управлять водителями и транспортом.',
            ),
          )
        else
          Expanded(
            child: OrganizationsDataTable(
              maxWidth: 0,
              columns: const [
                DataColumn(label: Text('Название')),
                DataColumn(label: Text('БИН')),
                DataColumn(label: Text('Руководитель')),
                DataColumn(label: Text('Адрес')),
                DataColumn(label: Text('Телефон')),
                DataColumn(label: Text('Статус')),
                DataColumn(label: Text('Действия')),
              ],
              rows: contractors.map((contractor) {
                return DataRow(
                  cells: [
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 220),
                        child: Text(
                          contractor.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 130),
                        child: Text(
                          contractor.bin,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 190),
                        child: Text(
                          contractor.HeadFullName ?? '—',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 240),
                        child: Text(
                          contractor.address ?? '—',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 150),
                        child: Text(
                          contractor.phone ?? '—',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                        OrganizationsStatusChip(isActive: contractor.isActive)),
                    DataCell(
                      OrganizationsTableActions(
                        actions: [
                          OrganizationsTableAction(
                            label: 'Подробнее',
                            onPressed: () => OrganizationsDetailsDialogs
                                .showOrganizationDetails(
                              context: context,
                              organization: contractor,
                              data: data,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
