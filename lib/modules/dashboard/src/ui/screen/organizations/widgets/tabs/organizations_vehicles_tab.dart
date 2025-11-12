import 'package:akimat_project/modules/dashboard/src/controller/organizations_controller.dart';
import 'package:akimat_project/modules/dashboard/src/controller/organizations_state.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/driver.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/vehicle.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_data_table.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_empty_state.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_status_chip.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_tab_header.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_table_actions.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/dialogs/organizations_details_dialogs.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/dialogs/organizations_dialogs.dart';
import 'package:flutter/material.dart';

class OrganizationsVehiclesTab extends StatelessWidget {
  const OrganizationsVehiclesTab({
    super.key,
    required this.data,
    required this.controller,
    required this.contractorId,
  });

  final OrganizationsData data;
  final OrganizationsController controller;
  final String contractorId;

  @override
  Widget build(BuildContext context) {
    final vehicles = data.vehicles
        .where((vehicle) => vehicle.contractorId == contractorId)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OrganizationsTabHeader(
          title: 'Транспорт',
          subtitle: 'Управляйте транспортом подрядчика и назначайте водителей',
          actionLabel: '+ Добавить транспорт',
          onAction: () => OrganizationsDialogs.showVehicleDialog(
            context: context,
            controller: controller,
            data: data,
            contractorId: contractorId,
          ),
        ),
        const SizedBox(height: 12),
        if (vehicles.isEmpty)
          const OrganizationsEmptyState(
            title: 'Нет транспорта',
            message: 'Добавьте транспорт, чтобы закреплять водителей.',
          )
        else
          OrganizationsDataTable(
            columns: const [
              DataColumn(label: Text('Гос. номер')),
              DataColumn(label: Text('Марка')),
              DataColumn(label: Text('Модель')),
              DataColumn(label: Text('Цвет')),
              DataColumn(label: Text('Год')),
              DataColumn(label: Text('Объём кузова')),
              DataColumn(label: Text('Водитель')),
              DataColumn(label: Text('Статус')),
              DataColumn(label: Text('Действия')),
            ],
            rows: vehicles.map((vehicle) {
              final driver = data.drivers.firstWhere(
                (driver) => driver.id == vehicle.driverId,
                orElse: () => Driver(
                  id: '',
                  contractorId: '',
                  fullName: '',
                  iin: '',
                  phone: '',
                  isActive: false,
                ),
              );
              return DataRow(
                cells: [
                  DataCell(Text(vehicle.plateNumber)),
                  DataCell(Text(vehicle.brand)),
                  DataCell(Text(vehicle.model)),
                  DataCell(Text(vehicle.color)),
                  DataCell(Text(vehicle.year.toString())),
                  DataCell(Text(vehicle.bodyVolumeM3.toStringAsFixed(1))),
                  DataCell(Text(driver.id.isEmpty ? 'Не назначен' : driver.fullName)),
                  DataCell(OrganizationsStatusChip(isActive: vehicle.isActive)),
                  DataCell(
                    OrganizationsTableActions(
                      actions: [
                        OrganizationsTableAction(
                          label: 'Подробнее',
                          onPressed: () => OrganizationsDetailsDialogs.showVehicleDetails(
                            context: context,
                            vehicle: vehicle,
                            driver: driver,
                          ),
                        ),
                        OrganizationsTableAction(
                          label: 'Редактировать',
                          onPressed: () => OrganizationsDialogs.showVehicleDialog(
                            context: context,
                            controller: controller,
                            data: data,
                            contractorId: contractorId,
                            vehicle: vehicle,
                          ),
                        ),
                        OrganizationsTableAction(
                          label: 'Назначить водителя',
                          onPressed: () => OrganizationsDialogs.showAssignDriverDialog(
                            context: context,
                            controller: controller,
                            data: data,
                            vehicle: vehicle,
                          ),
                        ),
                        OrganizationsTableAction(
                          label: vehicle.isActive ? 'Удалить' : 'Восстановить',
                          isDestructive: vehicle.isActive,
                          onPressed: () => controller.updateVehicle(
                            vehicle.copyWith(
                              isActive: !vehicle.isActive,
                              driverId: vehicle.isActive ? null : vehicle.driverId,
                            ),
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

