import 'dart:math';

import 'package:akimat_project/modules/dashboard/src/controller/organizations_controller.dart';
import 'package:akimat_project/modules/dashboard/src/controller/organizations_state.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/driver.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/organization.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/vehicle.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_text_field.dart';
import 'package:flutter/material.dart';

class OrganizationsDialogs {
  const OrganizationsDialogs._();

  static Future<void> showOrganizationDialog({
    required BuildContext context,
    required OrganizationsController controller,
    required OrganizationType type,
    required OrganizationsData data,
    String? parentOrganizationId,
  }) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final binController = TextEditingController();
    final headController = TextEditingController();
    final addressController = TextEditingController();
    final phoneController = TextEditingController();
    String? selectedTooId = parentOrganizationId;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModal) => AlertDialog(
            title: Text(type == OrganizationType.too ? 'Добавить ТОО' : 'Добавить подрядчика'),
            content: SizedBox(
              width: min(MediaQuery.sizeOf(context).width * 0.8, 420),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OrganizationsTextField(
                        controller: nameController,
                        label: 'Наименование*',
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Введите наименование' : null,
                      ),
                      OrganizationsTextField(
                        controller: binController,
                        label: 'БИН*',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Введите БИН';
                          }
                          if (data.organizations.any((org) => org.bin == value)) {
                            return 'Организация с таким БИН уже существует';
                          }
                          return null;
                        },
                      ),
                      OrganizationsTextField(
                        controller: headController,
                        label: 'ФИО руководителя',
                      ),
                      OrganizationsTextField(
                        controller: addressController,
                        label: 'Адрес',
                      ),
                      OrganizationsTextField(
                        controller: phoneController,
                        label: 'Телефон*',
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Введите номер телефона';
                          }
                          final normalized = value.replaceAll(RegExp(r'\\s+'), '');
                          final occupied = data.organizations.any(
                                (org) =>
                                    org.phone?.replaceAll(RegExp(r'\\s+'), '') == normalized,
                              ) ||
                              data.drivers.any(
                                (driver) =>
                                    driver.phone.replaceAll(RegExp(r'\\s+'), '') == normalized,
                              );
                          if (occupied) {
                            return 'Номер уже используется';
                          }
                          return null;
                        },
                      ),
                      if (type == OrganizationType.contractor)
                        DropdownButtonFormField<String>(
                          value: selectedTooId,
                          decoration: const InputDecoration(
                            labelText: 'ТОО*',
                            border: OutlineInputBorder(),
                          ),
                          items: data.organizations
                              .where((org) => org.type == OrganizationType.too)
                              .map(
                                (org) => DropdownMenuItem(
                                  value: org.id,
                                  child: Text(org.name),
                                ),
                              )
                              .toList(),
                          onChanged: parentOrganizationId != null
                              ? null
                              : (value) => setModal(() => selectedTooId = value),
                          validator: (value) =>
                              value == null ? 'Выберите родительское ТОО' : null,
                        ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Отмена'),
              ),
              FilledButton(
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;
                  final organization = Organization(
                    id: '',
                    type: type,
                    name: nameController.text.trim(),
                    bin: binController.text.trim(),
                    headFullName: headController.text.trim().isEmpty
                        ? null
                        : headController.text.trim(),
                    address: addressController.text.trim().isEmpty
                        ? null
                        : addressController.text.trim(),
                    phone: phoneController.text.trim(),
                    parentOrgId: type == OrganizationType.contractor ? selectedTooId : null,
                    isActive: true,
                  );
                  controller.createOrganization(organization);
                  Navigator.of(context).pop();
                },
                child: const Text('Сохранить'),
              ),
            ],
          ),
        );
      },
    );
  }

  static Future<void> showDriverDialog({
    required BuildContext context,
    required OrganizationsController controller,
    required OrganizationsData data,
    required String contractorId,
    Driver? driver,
  }) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: driver?.fullName ?? '');
    final iinController = TextEditingController(text: driver?.iin ?? '');
    final birthYearController =
        TextEditingController(text: driver?.birthYear?.toString() ?? '');
    final phoneController = TextEditingController(text: driver?.phone ?? '');

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(driver == null ? 'Добавить водителя' : 'Редактировать водителя'),
          content: SizedBox(
            width: min(MediaQuery.sizeOf(context).width * 0.8, 420),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OrganizationsTextField(
                      controller: nameController,
                      label: 'ФИО*',
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Введите ФИО' : null,
                    ),
                    OrganizationsTextField(
                      controller: iinController,
                      label: 'ИИН*',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите ИИН';
                        }
                        final exists = data.drivers.any(
                          (d) => d.iin == value && d.id != driver?.id,
                        );
                        if (exists) {
                          return 'Водитель с таким ИИН уже существует';
                        }
                        return null;
                      },
                    ),
                    OrganizationsTextField(
                      controller: birthYearController,
                      label: 'Год рождения',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return null;
                        final year = int.tryParse(value);
                        if (year == null || year < 1940 || year > DateTime.now().year) {
                          return 'Некорректный год';
                        }
                        return null;
                      },
                    ),
                    OrganizationsTextField(
                      controller: phoneController,
                      label: 'Телефон*',
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите телефон';
                        }
                        final normalized = value.replaceAll(RegExp(r'\\s+'), '');
                        final occupied = data.organizations.any(
                              (org) => org.phone?.replaceAll(RegExp(r'\\s+'), '') == normalized,
                            ) ||
                            data.drivers.any(
                              (d) =>
                                  d.phone.replaceAll(RegExp(r'\\s+'), '') == normalized &&
                                  d.id != driver?.id,
                            );
                        if (occupied) {
                          return 'Телефон уже используется';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                final parsedYear = int.tryParse(birthYearController.text.trim());
                final updated = Driver(
                  id: driver?.id ?? '',
                  contractorId: contractorId,
                  fullName: nameController.text.trim(),
                  iin: iinController.text.trim(),
                  birthYear: parsedYear,
                  phone: phoneController.text.trim(),
                  isActive: driver?.isActive ?? true,
                );
                if (driver == null) {
                  controller.createDriver(updated);
                } else {
                  controller.updateDriver(updated);
                }
                Navigator.of(context).pop();
              },
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );
  }

  static Future<void> showVehicleDialog({
    required BuildContext context,
    required OrganizationsController controller,
    required OrganizationsData data,
    required String contractorId,
    Vehicle? vehicle,
  }) async {
    final formKey = GlobalKey<FormState>();
    final plateController = TextEditingController(text: vehicle?.plateNumber ?? '');
    final brandController = TextEditingController(text: vehicle?.brand ?? '');
    final modelController = TextEditingController(text: vehicle?.model ?? '');
    final colorController = TextEditingController(text: vehicle?.color ?? '');
    final volumeController =
        TextEditingController(text: vehicle?.bodyVolumeM3.toString() ?? '');
    final photoController = TextEditingController(text: vehicle?.photoUrl ?? '');
    int? selectedYear = vehicle?.year ?? DateTime.now().year;

    final years = List<int>.generate(
      DateTime.now().year - 1980 + 1,
      (index) => DateTime.now().year - index,
    );

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModal) => AlertDialog(
            title: Text(vehicle == null ? 'Добавить транспорт' : 'Редактировать транспорт'),
            content: SizedBox(
              width: min(MediaQuery.sizeOf(context).width * 0.85, 460),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OrganizationsTextField(
                        controller: plateController,
                        label: 'Гос. номер*',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Введите гос. номер';
                          }
                          final exists = data.vehicles.any(
                            (item) => item.plateNumber == value && item.id != vehicle?.id,
                          );
                          if (exists) {
                            return 'Транспорт с таким номером уже существует';
                          }
                          return null;
                        },
                      ),
                      OrganizationsTextField(
                        controller: brandController,
                        label: 'Марка*',
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Введите марку' : null,
                      ),
                      OrganizationsTextField(
                        controller: modelController,
                        label: 'Модель*',
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Введите модель' : null,
                      ),
                      OrganizationsTextField(
                        controller: colorController,
                        label: 'Цвет*',
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Введите цвет' : null,
                      ),
                      DropdownButtonFormField<int>(
                        value: selectedYear,
                        decoration: const InputDecoration(
                          labelText: 'Год*',
                          border: OutlineInputBorder(),
                        ),
                        items: years
                            .map(
                              (year) => DropdownMenuItem(
                                value: year,
                                child: Text(year.toString()),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setModal(() => selectedYear = value),
                        validator: (value) => value == null ? 'Выберите год' : null,
                      ),
                      OrganizationsTextField(
                        controller: volumeController,
                        label: 'Объём кузова (м³)*',
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Введите объём';
                          }
                          final parsed = double.tryParse(value.replaceAll(',', '.'));
                          if (parsed == null || parsed <= 0) {
                            return 'Некорректное значение';
                          }
                          return null;
                        },
                      ),
                      OrganizationsTextField(
                        controller: photoController,
                        label: 'Фото (URL)',
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Укажите ссылку на фото' : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Отмена'),
              ),
              FilledButton(
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;
                  final parsedVolume = double.parse(volumeController.text.replaceAll(',', '.'));
                  final updated = Vehicle(
                    id: vehicle?.id ?? '',
                    contractorId: contractorId,
                    driverId: vehicle?.driverId,
                    plateNumber: plateController.text.trim(),
                    brand: brandController.text.trim(),
                    model: modelController.text.trim(),
                    color: colorController.text.trim(),
                    year: selectedYear!,
                    bodyVolumeM3: parsedVolume,
                    photoUrl: photoController.text.trim(),
                    isActive: vehicle?.isActive ?? true,
                  );
                  if (vehicle == null) {
                    controller.createVehicle(updated);
                  } else {
                    controller.updateVehicle(updated);
                  }
                  Navigator.of(context).pop();
                },
                child: const Text('Сохранить'),
              ),
            ],
          ),
        );
      },
    );
  }

  static Future<void> showAssignVehicleDialog({
    required BuildContext context,
    required OrganizationsController controller,
    required OrganizationsData data,
    required Driver driver,
  }) async {
    String? selectedVehicleId = data.vehicles
        .firstWhere(
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
        )
        .id;

    final availableVehicles = data.vehicles.where((vehicle) {
      final sameContractor = vehicle.contractorId == driver.contractorId;
      final noDriver = vehicle.driverId == null || vehicle.driverId == driver.id;
      return sameContractor && vehicle.isActive && noDriver;
    }).toList();

    if (availableVehicles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Нет доступного транспорта. Добавьте транспорт подрядчика.'),
        ),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModal) => AlertDialog(
            title: Text('Назначить транспорт — ${driver.fullName}'),
            content: DropdownButtonFormField<String>(
              value: selectedVehicleId?.isEmpty ?? true ? null : selectedVehicleId,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Транспорт',
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Без транспорта')),
                ...availableVehicles.map(
                  (vehicle) => DropdownMenuItem(
                    value: vehicle.id,
                    child: Text('${vehicle.plateNumber} — ${vehicle.brand} ${vehicle.model}'),
                  ),
                ),
              ],
              onChanged: (value) => setModal(() => selectedVehicleId = value),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Отмена'),
              ),
              FilledButton(
                onPressed: () {
                  for (final vehicle in data.vehicles) {
                    if (vehicle.driverId == driver.id) {
                      controller.updateVehicle(vehicle.copyWith(driverId: null));
                    }
                  }
                  if (selectedVehicleId != null) {
                    final vehicle = data.vehicles.firstWhere((item) => item.id == selectedVehicleId);
                    controller.updateVehicle(vehicle.copyWith(driverId: driver.id));
                  }
                  Navigator.of(context).pop();
                },
                child: const Text('Сохранить'),
              ),
            ],
          ),
        );
      },
    );
  }

  static Future<void> showAssignDriverDialog({
    required BuildContext context,
    required OrganizationsController controller,
    required OrganizationsData data,
    required Vehicle vehicle,
  }) async {
    String? selectedDriverId = vehicle.driverId;
    final availableDrivers = data.drivers.where((driver) {
      if (!driver.isActive) return false;
      if (driver.contractorId != vehicle.contractorId) return false;
      final assignedVehicle = data.vehicles.firstWhere(
        (item) => item.driverId == driver.id,
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
      return assignedVehicle.id.isEmpty || assignedVehicle.id == vehicle.id;
    }).toList();

    if (availableDrivers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Нет доступных водителей. Добавьте или разблокируйте водителя.'),
        ),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModal) => AlertDialog(
            title: Text('Назначить водителя — ${vehicle.plateNumber}'),
            content: DropdownButtonFormField<String>(
              value: selectedDriverId,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Водитель',
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Без водителя')),
                ...availableDrivers.map(
                  (driver) => DropdownMenuItem(
                    value: driver.id,
                    child: Text(driver.fullName),
                  ),
                ),
              ],
              onChanged: (value) => setModal(() => selectedDriverId = value),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Отмена'),
              ),
              FilledButton(
                onPressed: () {
                  if (selectedDriverId == vehicle.driverId) {
                    Navigator.of(context).pop();
                    return;
                  }
                  controller.updateVehicle(vehicle.copyWith(driverId: selectedDriverId));
                  Navigator.of(context).pop();
                },
                child: const Text('Сохранить'),
              ),
            ],
          ),
        );
      },
    );
  }
}

