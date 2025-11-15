import 'dart:math';
import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/core/ui/widgets/safe_dropdown_button.dart';
import 'package:akimat_project/l10n/l10n.dart';
import 'package:akimat_project/modules/dashboard/src/controller/tickets_controller.dart';
import 'package:akimat_project/modules/dashboard/src/controller/tickets_state.dart';
import 'package:akimat_project/modules/dashboard/src/model/areas/cleaning_area.dart';
import 'package:akimat_project/modules/dashboard/src/model/contracts/contract.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/organization.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/organization_type.dart';
import 'package:akimat_project/modules/dashboard/src/model/tickets/ticket.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_text_field.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TicketCreateDialog {
  const TicketCreateDialog._();

  /// Диалог создания тикета для KGU ZKH
  static Future<void> show({
    required BuildContext context,
    required TicketsController controller,
    required TicketsData data,
    String? organizationId,
  }) async {
    final formKey = GlobalKey<FormState>();
    final descriptionController = TextEditingController();
    String? selectedAreaId;
    String? selectedContractorId;
    String? selectedContractId;
    DateTime? plannedStartAt;
    DateTime? plannedEndAt;

    // Фильтруем активные участки
    final activeAreas = data.areas
        .where((area) => area.status == CleaningAreaStatus.active && area.isActive)
        .toList();

    // Фильтруем активных подрядчиков
    final activeContractors = data.contractors
        .where((org) => org.type == OrganizationType.contractor && org.isActive)
        .toList();

    // Контракты будут фильтроваться по выбранному подрядчику
    List<Contract> availableContracts = [];

    await showDialog<void>(
      context: context,
      builder: (context) {
        final s = S.of(context)!;
        return StatefulBuilder(
          builder: (context, setModal) => AlertDialog(
            title: Text(
              s.create_ticket,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: min(MediaQuery.sizeOf(context).width * 0.9, 500),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Участок уборки
                      SafeDropdownButtonFormField<String?>(
                        value: selectedAreaId,
                        decoration: InputDecoration(
                          labelText: '${s.area}*',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSize.smallRadius),
                          ),
                          isDense: true,
                        ),
                        isExpanded: true,
                        items: activeAreas.isEmpty
                            ? [
                                DropdownMenuItem(
                                  value: null,
                                  child: Text('Нет доступных участков'),
                                ),
                              ]
                            : activeAreas.map(
                                (area) => DropdownMenuItem(
                                  value: area.id,
                                  child: Text(area.name),
                                ),
                              ).toList(),
                        onChanged: activeAreas.isEmpty
                            ? null
                            : (value) => setModal(() => selectedAreaId = value),
                        validator: (value) =>
                            value == null ? 'Выберите участок уборки' : null,
                      ),
                      const SizedBox(height: AppPadding.normal),

                      // Подрядчик
                      SafeDropdownButtonFormField<String?>(
                        value: selectedContractorId,
                        decoration: InputDecoration(
                          labelText: '${s.contractor}*',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSize.smallRadius),
                          ),
                          isDense: true,
                        ),
                        isExpanded: true,
                        items: activeContractors.isEmpty
                            ? [
                                DropdownMenuItem(
                                  value: null,
                                  child: Text('Нет доступных подрядчиков'),
                                ),
                              ]
                            : activeContractors.map(
                                (contractor) => DropdownMenuItem(
                                  value: contractor.id,
                                  child: Text(contractor.name),
                                ),
                              ).toList(),
                        onChanged: activeContractors.isEmpty
                            ? null
                            : (value) {
                                setModal(() {
                                  selectedContractorId = value;
                                  selectedContractId = null; // Сбрасываем контракт
                                  // Фильтруем контракты по выбранному подрядчику
                                  availableContracts = data.contracts
                                      .where((c) =>
                                          c.contractorId == value && c.isActive)
                                      .toList();
                                });
                              },
                        validator: (value) =>
                            value == null ? 'Выберите подрядчика' : null,
                      ),
                      const SizedBox(height: AppPadding.normal),

                      // Контракт
                      SafeDropdownButtonFormField<String?>(
                        value: selectedContractId,
                        decoration: InputDecoration(
                          labelText: '${s.contract}*',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSize.smallRadius),
                          ),
                          isDense: true,
                        ),
                        isExpanded: true,
                        items: availableContracts.isEmpty
                            ? [
                                DropdownMenuItem(
                                  value: null,
                                  child: Text(
                                    selectedContractorId == null
                                        ? 'Сначала выберите подрядчика'
                                        : 'Нет доступных контрактов',
                                  ),
                                ),
                              ]
                            : availableContracts.map(
                                (contract) => DropdownMenuItem(
                                  value: contract.id,
                                  child: Text(contract.name),
                                ),
                              ).toList(),
                        onChanged: selectedContractorId == null
                            ? null
                            : (value) => setModal(() => selectedContractId = value),
                        validator: (value) =>
                            value == null ? 'Выберите контракт' : null,
                      ),
                      const SizedBox(height: AppPadding.normal),

                      // Дата начала работ
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Дата начала работ*',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSize.smallRadius),
                          ),
                          suffixIcon: const Icon(Icons.calendar_today),
                          isDense: true,
                        ),
                        readOnly: true,
                        controller: TextEditingController(
                          text: plannedStartAt != null
                              ? DateFormat('dd.MM.yyyy').format(plannedStartAt!)
                              : '',
                        ),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: plannedStartAt ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (date != null) {
                            setModal(() {
                              plannedStartAt = date;
                              if (plannedEndAt != null &&
                                  plannedStartAt!.isAfter(plannedEndAt!)) {
                                plannedEndAt = null;
                              }
                            });
                          }
                        },
                        validator: (value) {
                          if (plannedStartAt == null) {
                            return 'Выберите дату начала';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppPadding.normal),

                      // Дата окончания работ
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Дата окончания работ*',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSize.smallRadius),
                          ),
                          suffixIcon: const Icon(Icons.calendar_today),
                          isDense: true,
                        ),
                        readOnly: true,
                        controller: TextEditingController(
                          text: plannedEndAt != null
                              ? DateFormat('dd.MM.yyyy').format(plannedEndAt!)
                              : '',
                        ),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: plannedEndAt ??
                                (plannedStartAt ?? DateTime.now()),
                            firstDate: plannedStartAt ?? DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (date != null) {
                            setModal(() => plannedEndAt = date);
                          }
                        },
                        validator: (value) {
                          if (plannedEndAt == null) {
                            return 'Выберите дату окончания';
                          }
                          if (plannedStartAt != null &&
                              (plannedStartAt!.isAfter(plannedEndAt!) ||
                                  plannedStartAt!.isAtSameMomentAs(plannedEndAt!))) {
                            return 'Дата окончания должна быть позже даты начала';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppPadding.normal),

                      // Описание
                      OrganizationsTextField(
                        controller: descriptionController,
                        label: s.description,
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(s.cancel),
              ),
              FilledButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;

                  // Дополнительная валидация
                  if (selectedAreaId == null ||
                      selectedContractorId == null ||
                      selectedContractId == null ||
                      plannedStartAt == null ||
                      plannedEndAt == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Заполните все обязательные поля'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  if (plannedStartAt!.isAfter(plannedEndAt!) ||
                      plannedStartAt!.isAtSameMomentAs(plannedEndAt!)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Дата начала должна быть раньше даты окончания'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  // Проверка периода контракта (предупреждение, но не блокируем)
                  final selectedContract = data.contracts.firstWhere(
                    (c) => c.id == selectedContractId,
                    orElse: () => data.contracts.first,
                  );
                  if (plannedStartAt!.isBefore(selectedContract.startAt) ||
                      plannedEndAt!.isAfter(selectedContract.endAt)) {
                    // Показываем предупреждение, но не блокируем сохранение
                    final shouldContinue = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Предупреждение'),
                        content: Text(
                          'Период тикета не попадает в период действия контракта '
                          '(${DateFormat('dd.MM.yyyy').format(selectedContract.startAt)} - '
                          '${DateFormat('dd.MM.yyyy').format(selectedContract.endAt)}). '
                          'Продолжить?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text(s.cancel),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: Text('Продолжить'),
                          ),
                        ],
                      ),
                    );
                    if (shouldContinue != true) return;
                  }

                  try {
                    final ticket = Ticket(
                      id: '',
                      cleaningAreaId: selectedAreaId!,
                      contractorId: selectedContractorId!,
                      contractId: selectedContractId!,
                      plannedStartAt: plannedStartAt!,
                      plannedEndAt: plannedEndAt!,
                      description: descriptionController.text.trim().isEmpty
                          ? null
                          : descriptionController.text.trim(),
                      status: TicketStatus.planned,
                      createdByOrgId: organizationId,
                      isActive: true,
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    );

                    await controller.createTicket(ticket);

                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Тикет успешно создан'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      // TODO: Переход в карточку тикета после реализации
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Ошибка при создании тикета: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: Text(s.save),
              ),
            ],
          ),
        );
      },
    );
  }
}

