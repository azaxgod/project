import 'package:akimat_project/l10n/l10n.dart';
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
import 'package:akimat_project/core/utils/notification_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class OrganizationsKguZkhTab extends StatelessWidget {
  const OrganizationsKguZkhTab({
    super.key,
    required this.data,
    required this.controller,
  });

  final OrganizationsData data;
  final OrganizationsController controller;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final organizations = data.organizations
        .where((organization) => organization.type == OrganizationType.kguZkh)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        OrganizationsTabHeader(
          title: s.kgu_zkh,
          subtitle: 'Создание, редактирование и блокировка КГУ ЖКХ',
          actionLabel: 'Добавить КГУ ЖКХ',
          onAction: () => OrganizationsDialogs.showOrganizationDialog(
            context: context,
            controller: controller,
            type: OrganizationType.kguZkh,
            data: data,
          ),
        ),
        const SizedBox(height: 12),
        if (organizations.isEmpty)
          OrganizationsEmptyState(
            title: 'Нет КГУ ЖКХ',
            message: 'Добавьте КГУ ЖКХ, чтобы начать управлять подрядчиками.',
          )
        else
          OrganizationsDataTable(
            columns: const [
              DataColumn(label: Text('Название')),
              DataColumn(label: Text('БИН')),
              DataColumn(label: Text('Руководитель')),
              DataColumn(label: Text('Телефон')),
              DataColumn(label: Text('Статус')),
              DataColumn(label: Text('Действия')),
            ],
            rows: organizations.map((organization) {
              return DataRow(
                cells: [
                  DataCell(Text(organization.name, overflow: TextOverflow.ellipsis)),
                  DataCell(Text(organization.bin, overflow: TextOverflow.ellipsis)),
                  DataCell(Text(organization.HeadFullName ?? '—', overflow: TextOverflow.ellipsis)),
                  DataCell(Text(organization.phone ?? '—', overflow: TextOverflow.ellipsis)),
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
                              // Сохраняем новое значение isActive
                              final newIsActive = !organization.isActive;
                              debugPrint('OrganizationsKguZkhTab: Blocking/unblocking organization ${organization.id}, current isActive: ${organization.isActive}, new isActive: $newIsActive');
                              
                              await controller.updateOrganization(
                                organization.copyWith(isActive: newIsActive),
                                skipReload: true,
                              );
                              
                              debugPrint('OrganizationsKguZkhTab: Organization updated, refreshing data...');
                              
                              if (context.mounted) {
                                // Сразу обновляем данные без задержки
                                await controller.refresh();
                                
                                debugPrint('OrganizationsKguZkhTab: Data refreshed');
                                
                                // Показываем уведомление после обновления
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        newIsActive 
                                            ? 'КГУ ЖКХ успешно разблокировано'
                                            : 'КГУ ЖКХ успешно заблокировано',
                                      ),
                                      backgroundColor: Colors.green,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              }
                            } catch (e) {
                              debugPrint('OrganizationsKguZkhTab: Error blocking/unblocking organization: $e');
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
      ],
    );
  }
}

