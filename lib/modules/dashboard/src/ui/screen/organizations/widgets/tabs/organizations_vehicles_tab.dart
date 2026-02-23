import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/modules/dashboard/src/controller/organizations_controller.dart';
import 'package:akimat_project/modules/dashboard/src/controller/organizations_state.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/driver.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/organization.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/organization_type.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_data_table.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_empty_state.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_status_chip.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_tab_header.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_table_actions.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/dialogs/organizations_details_dialogs.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/dialogs/organizations_dialogs.dart';
import 'package:flutter/material.dart';

class OrganizationsVehiclesTab extends StatefulWidget {
  const OrganizationsVehiclesTab({
    super.key,
    required this.data,
    required this.controller,
    this.contractorId,
    this.showAll = false,
  });

  final OrganizationsData data;
  final OrganizationsController controller;
  final String? contractorId;
  final bool showAll;

  @override
  State<OrganizationsVehiclesTab> createState() =>
      _OrganizationsVehiclesTabState();
}

class _OrganizationsVehiclesTabState extends State<OrganizationsVehiclesTab> {
  final TextEditingController _plateSearchController = TextEditingController();
  String? _selectedContractorId;

  @override
  void initState() {
    super.initState();
    _plateSearchController.addListener(_onFiltersChanged);
    _selectedContractorId = widget.showAll ? null : widget.contractorId;
  }

  @override
  void didUpdateWidget(covariant OrganizationsVehiclesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.showAll) {
      _selectedContractorId = widget.contractorId;
      return;
    }
    if (!oldWidget.showAll && widget.showAll) {
      _selectedContractorId = null;
    }
  }

  @override
  void dispose() {
    _plateSearchController.removeListener(_onFiltersChanged);
    _plateSearchController.dispose();
    super.dispose();
  }

  void _onFiltersChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  String _normalize(String value) => value.trim().toLowerCase();

  Driver _fallbackDriver() {
    return const Driver(
      id: '',
      contractorId: '',
      fullName: 'Не назначен',
      iin: '',
      phone: '',
      isActive: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final contractors = widget.data.organizations
        .where(
            (organization) => organization.type == OrganizationType.contractor)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    final contractorById = <String, Organization>{
      for (final contractor in contractors)
        _normalize(contractor.id): contractor,
    };

    final driverById = <String, Driver>{
      for (final driver in widget.data.drivers) _normalize(driver.id): driver,
    };

    final normalizedContractorId =
        widget.contractorId != null ? _normalize(widget.contractorId!) : null;
    final baseVehicles = widget.showAll
        ? widget.data.vehicles.toList()
        : widget.data.vehicles
            .where(
              (vehicle) =>
                  _normalize(vehicle.contractorId) == normalizedContractorId,
            )
            .toList();

    final selectedContractorId = contractors.any(
      (contractor) =>
          _normalize(contractor.id) == _normalize(_selectedContractorId ?? ''),
    )
        ? _selectedContractorId
        : null;

    final searchQuery = _normalize(_plateSearchController.text);

    final filteredVehicles = baseVehicles.where((vehicle) {
      if (selectedContractorId != null &&
          _normalize(vehicle.contractorId) !=
              _normalize(selectedContractorId)) {
        return false;
      }
      if (searchQuery.isNotEmpty &&
          !_normalize(vehicle.plateNumber).contains(searchQuery)) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => a.plateNumber.compareTo(b.plateNumber));

    final hasFilters = _plateSearchController.text.trim().isNotEmpty ||
        selectedContractorId != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OrganizationsTabHeader(
          title: 'Транспорт',
          subtitle: widget.showAll
              ? 'Список транспорта всех подрядчиков с быстрыми фильтрами'
              : 'Управляйте транспортом подрядчика',
          actionLabel:
              widget.contractorId != null ? 'Добавить транспорт' : null,
          onAction: widget.contractorId != null
              ? () => OrganizationsDialogs.showVehicleDialog(
                    context: context,
                    controller: widget.controller,
                    data: widget.data,
                    contractorId: widget.contractorId!,
                  )
              : () {},
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(AppPadding.normal),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black12),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final filterWidth =
                  constraints.maxWidth < 360 ? constraints.maxWidth : 320.0;
              return Wrap(
                spacing: AppPadding.normal,
                runSpacing: AppPadding.small,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: filterWidth,
                    child: TextField(
                      controller: _plateSearchController,
                      decoration: InputDecoration(
                        labelText: 'Поиск по номеру',
                        hintText: 'Например: 123ABC02',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _plateSearchController.text.trim().isEmpty
                            ? null
                            : IconButton(
                                onPressed: _plateSearchController.clear,
                                icon: const Icon(Icons.close),
                              ),
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  if (widget.showAll)
                    SizedBox(
                      width: filterWidth,
                      child: DropdownButtonFormField<String?>(
                        key: ValueKey<String?>(selectedContractorId),
                        initialValue: selectedContractorId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Подрядчик',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Все подрядчики'),
                          ),
                          ...contractors.map(
                            (contractor) => DropdownMenuItem<String?>(
                              value: contractor.id,
                              child: Text(
                                contractor.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedContractorId = value;
                          });
                        },
                      ),
                    ),
                  if (hasFilters)
                    OutlinedButton.icon(
                      onPressed: () {
                        _plateSearchController.clear();
                        setState(() {
                          _selectedContractorId = null;
                        });
                      },
                      icon: const Icon(Icons.clear),
                      label: const Text('Сбросить фильтры'),
                    ),
                  Chip(
                    label: Text(
                        'Найден: ${filteredVehicles.length}/${baseVehicles.length}'),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        if (baseVehicles.isEmpty)
          const Expanded(
            child: OrganizationsEmptyState(
              title: 'Нет транспорта',
              message: 'Добавьте транспорт, чтобы начать работу.',
            ),
          )
        else if (filteredVehicles.isEmpty)
          const Expanded(
            child: OrganizationsEmptyState(
              title: 'Ничего не найдено',
              message: 'Измените фильтры и повторите поиск.',
            ),
          )
        else
          Expanded(
            child: OrganizationsDataTable(
              maxWidth: 0,
              columns: const [
                DataColumn(label: Text('Номер')),
                DataColumn(label: Text('Марка и модель')),
                DataColumn(label: Text('Подрядчик')),
                DataColumn(label: Text('Кузов, м3')),
                DataColumn(label: Text('Статус')),
                DataColumn(label: Text('Действия')),
              ],
              rows: filteredVehicles.map((vehicle) {
                final driver = vehicle.driverId != null &&
                        vehicle.driverId!.trim().isNotEmpty
                    ? driverById[_normalize(vehicle.driverId!)]
                    : null;

                final contractorName =
                    contractorById[_normalize(vehicle.contractorId)]?.name ??
                        vehicle.contractorId;

                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        vehicle.plateNumber,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    DataCell(Text('${vehicle.brand} ${vehicle.model}')),
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 220),
                        child: Text(
                          contractorName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(Text(vehicle.bodyVolumeM3.toStringAsFixed(1))),
                    DataCell(
                        OrganizationsStatusChip(isActive: vehicle.isActive)),
                    DataCell(
                      OrganizationsTableActions(
                        actions: [
                          OrganizationsTableAction(
                            label: 'Подробнее',
                            onPressed: () =>
                                OrganizationsDetailsDialogs.showVehicleDetails(
                              context: context,
                              vehicle: vehicle,
                              driver: driver ?? _fallbackDriver(),
                            ),
                          ),
                          if (widget.contractorId != null)
                            OrganizationsTableAction(
                              label: 'Редактировать',
                              onPressed: () =>
                                  OrganizationsDialogs.showVehicleDialog(
                                context: context,
                                controller: widget.controller,
                                data: widget.data,
                                contractorId: widget.contractorId!,
                                vehicle: vehicle,
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
