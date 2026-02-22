import 'package:akimat_project/modules/dashboard/src/controller/organizations_controller.dart';
import 'package:akimat_project/modules/dashboard/src/controller/organizations_state.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/organization_type.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/user_role.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_data_table.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_empty_state.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_status_chip.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_tab_header.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_table_actions.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/dialogs/organizations_details_dialogs.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/dialogs/organizations_dialogs.dart';
import 'package:flutter/material.dart';

class OrganizationsTooTab extends StatelessWidget {
  const OrganizationsTooTab({
    super.key,
    required this.data,
    required this.controller,
    this.userRole,
  });

  final OrganizationsData data;
  final OrganizationsController controller;
  final UserRole? userRole;

  @override
  Widget build(BuildContext context) {
    final organizations = data.organizations
        .where((organization) => organization.type == OrganizationType.too)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OrganizationsTabHeader(
          title: 'Полигоны по вывозу снега',
          subtitle: 'Создание и редактирование полигонов',
          actionLabel: 'Добавить полигон',
          onAction: () => OrganizationsDialogs.showOrganizationDialog(
            context: context,
            controller: controller,
            type: OrganizationType.too,
            data: data,
          ),
        ),
        const SizedBox(height: 12),
        if (organizations.isEmpty)
          const Expanded(
            child: OrganizationsEmptyState(
              title: 'Нет полигонов',
              message: 'Добавьте полигон, чтобы начать управлять подрядчиками.',
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
              rows: organizations.map((organization) {
                return DataRow(
                  cells: [
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 220),
                        child: Text(
                          organization.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 130),
                        child: Text(
                          organization.bin,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 190),
                        child: Text(
                          organization.HeadFullName ?? '—',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 240),
                        child: Text(
                          organization.address ?? '—',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 150),
                        child: Text(
                          organization.phone ?? '—',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(OrganizationsStatusChip(
                        isActive: organization.isActive)),
                    DataCell(
                      OrganizationsTableActions(
                        actions: [
                          OrganizationsTableAction(
                            label: 'Подробнее',
                            onPressed: () => OrganizationsDetailsDialogs
                                .showOrganizationDetails(
                              context: context,
                              organization: organization,
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
