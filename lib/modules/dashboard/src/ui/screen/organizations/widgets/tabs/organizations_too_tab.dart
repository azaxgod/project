import 'package:akimat_project/modules/dashboard/src/controller/organizations_controller.dart';
import 'package:akimat_project/modules/dashboard/src/controller/organizations_state.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/organization.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/organization_type.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_data_table.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_empty_state.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_status_chip.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_tab_header.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_table_actions.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/dialogs/organizations_details_dialogs.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/dialogs/organizations_dialogs.dart';
import 'package:akimat_project/core/utils/notification_helper.dart';
import 'package:flutter/material.dart';

class OrganizationsTooTab extends StatelessWidget {
  const OrganizationsTooTab({
    super.key,
    required this.data,
    required this.controller,
  });

  final OrganizationsData data;
  final OrganizationsController controller;

  @override
  Widget build(BuildContext context) {
    final organizations = data.organizations
        .where((organization) => organization.type == OrganizationType.too)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OrganizationsTabHeader(
          title: 'Список ТОО',
          subtitle: 'Создание, редактирование и блокировка ТОО',
          actionLabel: 'Добавить ТОО',
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
              title: 'Нет ТОО',
              message: 'Добавьте ТОО, чтобы начать управлять подрядчиками.',
            ),
          )
        else
          Expanded(
            child: OrganizationsDataTable(
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
                    DataCell(Text(organization.name)),
                    DataCell(Text(organization.bin)),
                    DataCell(Text(organization.HeadFullName ?? '—')),
                    DataCell(Text(organization.address ?? '—')),
                    DataCell(Text(organization.phone ?? '—')),
                    DataCell(OrganizationsStatusChip(isActive: organization.isActive)),
                    DataCell(
                      OrganizationsTableActions(
                        actions: [
                          OrganizationsTableAction(
                            label: 'Подробнее',
                            onPressed: () => OrganizationsDetailsDialogs.showOrganizationDetails(
                              context: context,
                              organization: organization,
                              data: data,
                            ),
                          ),
                          OrganizationsTableAction(
                            label: organization.isActive ? 'Блокировать' : 'Разблокировать',
                            isDestructive: organization.isActive,
                            onPressed: () async {
                              try {
                                await controller.updateOrganization(
                                  organization.copyWith(isActive: !organization.isActive),
                                  skipReload: true,
                                );
                                if (context.mounted) {
                                  await context.showSuccessWithReload(
                                    organization.isActive 
                                        ? 'ТОО успешно заблокировано'
                                        : 'ТОО успешно разблокировано',
                                    () async {
                                      await controller.refresh();
                                    },
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  context.showErrorNotificationFromException(e);
                                }
                              }
                            },
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

