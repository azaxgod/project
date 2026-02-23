import 'package:akimat_project/modules/dashboard/src/controller/organizations_state.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/driver.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/organization.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/organization_type.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/vehicle.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_info_row.dart';
import 'package:flutter/material.dart';

class OrganizationsDetailsDialogs {
  const OrganizationsDetailsDialogs._();

  static Future<void> showOrganizationDetails({
    required BuildContext context,
    required Organization organization,
    required OrganizationsData data,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(organization.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OrganizationsInfoRow(label: 'БИН', value: organization.bin),
            OrganizationsInfoRow(
              label: 'Руководитель',
              value: organization.HeadFullName ?? '—',
            ),
            OrganizationsInfoRow(label: 'Телефон', value: organization.phone ?? '—'),
            OrganizationsInfoRow(label: 'Адрес', value: organization.address ?? '—'),
            if (organization.parentOrgId != null)
              OrganizationsInfoRow(
                label: 'Наименование',
                value: data.organizations
                        .firstWhere(
                          (too) =>
                              too.id == organization.parentOrgId &&
                              too.type == OrganizationType.too,
                          orElse: () => organization,
                        )
                        .name,
              ),
            OrganizationsInfoRow(
              label: 'Статус',
              value: organization.isActive ? 'ACTIVE' : 'BLOCKED',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  static Future<void> showDriverDetails({
    required BuildContext context,
    required Driver driver,
    required Organization contractor,
    required Vehicle vehicle,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(driver.fullName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OrganizationsInfoRow(label: 'ИИН', value: driver.iin),
            OrganizationsInfoRow(label: 'Телефон', value: driver.phone),
            OrganizationsInfoRow(label: 'Подрядчик', value: contractor.name),
            OrganizationsInfoRow(
              label: 'Назначенный транспорт',
              value: vehicle.id.isEmpty ? 'Не назначен' : vehicle.plateNumber,
            ),
            OrganizationsInfoRow(
              label: 'Год рождения',
              value: driver.birthYear?.toString() ?? '—',
            ),
            OrganizationsInfoRow(
              label: 'Статус',
              value: driver.isActive ? 'ACTIVE' : 'BLOCKED',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  static Future<void> showVehicleDetails({
    required BuildContext context,
    required Vehicle vehicle,
    required Driver driver,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(vehicle.plateNumber),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            OrganizationsInfoRow(label: 'Марка', value: vehicle.brand),
            OrganizationsInfoRow(label: 'Модель', value: vehicle.model),
            OrganizationsInfoRow(label: 'Цвет', value: vehicle.color),
            OrganizationsInfoRow(label: 'Год', value: vehicle.year.toString()),
            OrganizationsInfoRow(
              label: 'Объём кузова',
              value: vehicle.bodyVolumeM3.toStringAsFixed(1),
            ),
            OrganizationsInfoRow(label: 'Фото', value: vehicle.photoUrl ?? '—'),
            OrganizationsInfoRow(
              label: 'Водитель',
              value: driver.id.isEmpty ? 'Не назначен' : driver.fullName,
            ),
            OrganizationsInfoRow(
              label: 'Статус',
              value: vehicle.isActive ? 'ACTIVE' : 'BLOCKED',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }
}
