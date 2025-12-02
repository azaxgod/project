import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/modules/dashboard/src/controller/organizations_controller.dart';
import 'package:akimat_project/modules/dashboard/src/controller/organizations_state.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/driver.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/contractor_cabinet/widgets/vehicle_card.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_empty_state.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_tab_header.dart';
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
          const Expanded(
            child: OrganizationsEmptyState(
              title: 'Нет транспорта',
              message: 'Добавьте транспорт, чтобы закреплять водителей.',
            ),
          )
        else
          Expanded(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Scrollbar(
                  thumbVisibility: true,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: AppPadding.large),
                    itemCount: vehicles.length,
                    itemBuilder: (context, index) {
                final vehicle = vehicles[index];
                Driver? driver;
                if (vehicle.driverId != null && vehicle.driverId!.isNotEmpty) {
                  try {
                    driver = data.drivers.firstWhere(
                      (d) => d.id == vehicle.driverId,
                    );
                  } catch (e) {
                    driver = null;
                  }
                }

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index < vehicles.length - 1 ? AppPadding.normal : 0,
                  ),
                  child: VehicleCard(
                    vehicle: vehicle,
                    driver: driver,
                    onTap: () => OrganizationsDetailsDialogs.showVehicleDetails(
                      context: context,
                      vehicle: vehicle,
                      driver: driver ?? Driver(
                        id: '',
                        contractorId: '',
                        fullName: 'Не назначен',
                        iin: '',
                        phone: '',
                        isActive: false,
                      ),
                    ),
                    onEdit: () => OrganizationsDialogs.showVehicleDialog(
                      context: context,
                      controller: controller,
                      data: data,
                      contractorId: contractorId,
                      vehicle: vehicle,
                    ),
                    onAssignDriver: () => OrganizationsDialogs.showAssignDriverDialog(
                      context: context,
                      controller: controller,
                      data: data,
                      vehicle: vehicle,
                    ),
                  ),
                );
              },
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
