import 'package:akimat_project/modules/dashboard/src/controller/organizations_controller.dart';
import 'package:akimat_project/modules/dashboard/src/controller/organizations_state.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/driver.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/organization.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/organization_type.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/vehicle.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_data_table.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_empty_state.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_status_chip.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_tab_header.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_table_actions.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/dialogs/organizations_details_dialogs.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/dialogs/organizations_dialogs.dart';
import 'package:akimat_project/core/utils/notification_helper.dart';
import 'package:flutter/material.dart';

class OrganizationsDriversTab extends StatelessWidget {
  const OrganizationsDriversTab({
    super.key,
    required this.data,
    required this.controller,
    required this.canManage,
    required this.organizationId,
  });

  final OrganizationsData data;
  final OrganizationsController controller;
  final bool canManage;
  final String? organizationId;
  

  @override
  Widget build(BuildContext context) {
    // Filter drivers based on organizationId
    // If organizationId is a contractor, show its drivers
    // If organizationId is a KGU ZKH, show drivers from its contractors
    final drivers = data.drivers.where((driver) {
      if (organizationId == null) return true;
      
      // Check if organizationId is a contractor
      final org = data.organizations.firstWhere(
        (o) => o.id == organizationId,
        orElse: () => Organization(
          id: '',
          type: OrganizationType.contractor,
          name: '',
          bin: '',
          isActive: false,
        ),
      );
      
      if (org.type == OrganizationType.contractor) {
        return driver.contractorId == organizationId;
      } else if (org.type == OrganizationType.kguZkh) {
        // Show drivers from contractors that belong to this KGU ZKH
        final contractor = data.organizations.firstWhere(
          (o) => o.id == driver.contractorId && o.parentOrgId == organizationId,
          orElse: () => Organization(
            id: '',
            type: OrganizationType.contractor,
            name: '',
            bin: '',
            isActive: false,
          ),
        );
        return contractor.id.isNotEmpty;
      }
      
      return false;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OrganizationsTabHeader(
          title: 'Водители',
          subtitle: canManage
              ? 'Добавляйте и блокируйте водителей своей организации'
              : 'Просмотр водителей доступных организаций',
          actionLabel: canManage ? 'Добавить водителя' : null,
          onAction: canManage
              ? () => OrganizationsDialogs.showDriverDialog(
                    context: context,
                    controller: controller,
                    data: data,
                    contractorId: organizationId!,
                  )
              : (){},
        ),
        const SizedBox(height: 12),
        if (drivers.isEmpty)
          const Expanded(
            child: OrganizationsEmptyState(
              title: 'Нет водителей',
              message: 'Добавьте водителя, чтобы начать планировать рейсы.',
            ),
          )
        else
          Expanded(
            child: OrganizationsDataTable(
            columns: const [
              DataColumn(label: Text('ФИО')),
              DataColumn(label: Text('ИИН')),
              DataColumn(label: Text('Телефон')),
              DataColumn(label: Text('Подрядчик')),
              DataColumn(label: Text('Транспорт')),
              DataColumn(label: Text('Статус')),
              DataColumn(label: Text('Действия')),
            ],
            rows: drivers.map((driver) {
              final contractor = data.organizations.firstWhere(
                (organization) => organization.id == driver.contractorId,
                orElse: () => Organization(
                  id: '',
                  type: OrganizationType.contractor,
                  name: '—',
                  bin: '',
                  isActive: false,
                ),
              );
              final vehicle = data.vehicles.firstWhere(
                (vehicle) => vehicle.driverId == driver.id && vehicle.isActive,
                orElse: () => Vehicle(
                  id: '',
                  contractorId: '',
                  driverId: null,
                  plateNumber: '',
                  brand: '',
                  model: '',
                  color: '',
                  year: 0,
                  bodyVolumeM3: 0,
                  isActive: false,
                ),
              );
              return DataRow(
                cells: [
                  DataCell(Text(driver.fullName)),
                  DataCell(Text(driver.iin)),
                  DataCell(Text(driver.phone)),
                  DataCell(Text(contractor.name)),
                  DataCell(Text(vehicle.id.isEmpty ? 'Не назначен' : vehicle.plateNumber)),
                  DataCell(OrganizationsStatusChip(isActive: driver.isActive)),
                  DataCell(
                    OrganizationsTableActions(
                      actions: [
                        OrganizationsTableAction(
                          label: 'Подробнее',
                          onPressed: () => OrganizationsDetailsDialogs.showDriverDetails(
                            context: context,
                            driver: driver,
                            contractor: contractor,
                            vehicle: vehicle,
                          ),
                        ),
                        if (canManage)
                          OrganizationsTableAction(
                            label: 'Редактировать',
                            onPressed: () => OrganizationsDialogs.showDriverDialog(
                              context: context,
                              controller: controller,
                              data: data,
                              contractorId: organizationId!,
                              driver: driver,
                            ),
                          ),
                        if (canManage)
                          OrganizationsTableAction(
                            label: 'Назначить транспорт',
                            onPressed: () => OrganizationsDialogs.showAssignVehicleDialog(
                              context: context,
                              controller: controller,
                              data: data,
                              driver: driver,
                            ),
                          ),
                        if (canManage)
                          OrganizationsTableAction(
                            label: driver.isActive ? 'Блокировать' : 'Разблокировать',
                            isDestructive: driver.isActive,
                            onPressed: () async {
                              try {
                                await controller.updateDriver(
                                  driver.copyWith(isActive: !driver.isActive),
                                  skipReload: true,
                                );
                                if (context.mounted) {
                                  // Показываем уведомление об успехе
                                  context.showSuccessNotification(
                                    driver.isActive 
                                        ? 'Водитель успешно заблокирован'
                                        : 'Водитель успешно разблокирован',
                                  );
                                  // Сразу перезагружаем данные
                                  await controller.refresh();
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

