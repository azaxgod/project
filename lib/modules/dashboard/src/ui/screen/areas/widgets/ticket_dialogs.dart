import 'dart:math';

import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/core/ui/widgets/safe_dropdown_button.dart';
import 'package:akimat_project/l10n/l10n.dart';
import 'package:akimat_project/modules/dashboard/src/controller/tickets_controller.dart';
import 'package:akimat_project/modules/auth/src/controller/auth_notifier.dart';
import 'package:akimat_project/modules/dashboard/src/model/areas/cleaning_area.dart';
import 'package:akimat_project/modules/dashboard/src/model/contracts/contract.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/organization.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/organization_type.dart';
import 'package:akimat_project/modules/dashboard/src/model/tickets/ticket.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_text_field.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class TicketDialogs {
  const TicketDialogs._();

  static Future<void> showCreateTicketDialog({
    required BuildContext context,
    required TicketsController controller,
    required CleaningArea area,
    required List<Organization> contractors,
    required List<Contract> contracts,
    String? organizationId, // ID организации создателя (для createdByOrgId)
  }) async {
    final formKey = GlobalKey<FormState>();
    final descriptionController = TextEditingController();
    String? selectedContractorId = area.defaultContractorId;
    String? selectedContractId;
    DateTime? startDate;
    DateTime? endDate;
    
    // Фильтруем контракты по выбранному подрядчику
    List<Contract> availableContracts = contracts
        .where((c) => c.contractorId == selectedContractorId && c.isActive)
        .toList();

    await showDialog<void>(
      context: context,
      builder: (context) {
        final s = S.of(context)!;
        return StatefulBuilder(
          builder: (context, setModal) => AlertDialog(
            title: Text(s.create_ticket),
            content: SizedBox(
              width: min(MediaQuery.sizeOf(context).width * 0.8, 500),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Участок (заблокирован)
                      TextFormField(
                        initialValue: area.name,
                        decoration: InputDecoration(
                          labelText: s.area,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSize.smallRadius),
                          ),
                          enabled: false,
                        ),
                      ),
                      const SizedBox(height: AppPadding.normal),
                      // Подрядчик
                      SafeDropdownButtonFormField<String?>(
                        value: selectedContractorId,
                        decoration: InputDecoration(
                          labelText: s.contractor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSize.smallRadius),
                          ),
                        ),
                        items: contractors.isEmpty
                            ? [
                                DropdownMenuItem(
                                  value: null,
                                  child: Text(s.no_contracts_available),
                                ),
                              ]
                            : contractors.map(
                                (contractor) => DropdownMenuItem(
                                  value: contractor.id,
                                  child: Text(contractor.name),
                                ),
                              ).toList(),
                        onChanged: (value) {
                          setModal(() {
                            selectedContractorId = value;
                            selectedContractId = null; // Сбрасываем контракт при смене подрядчика
                            availableContracts = contracts
                                .where((c) => c.contractorId == value && c.isActive)
                                .toList();
                          });
                        },
                        validator: (value) => value == null ? s.select_contractor : null,
                      ),
                      const SizedBox(height: AppPadding.normal),
                      // Контракт
                      SafeDropdownButtonFormField<String?>(
                        value: selectedContractId,
                        decoration: InputDecoration(
                          labelText: s.contract,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSize.smallRadius),
                          ),
                        ),
                        items: availableContracts.isEmpty
                            ? [
                                DropdownMenuItem(
                                  value: null,
                                  child: Text(
                                    selectedContractorId == null
                                        ? s.select_contractor_first
                                        : s.no_contracts_available,
                                  ),
                                ),
                              ]
                            : [
                                if (selectedContractorId != null)
                                  DropdownMenuItem(
                                    value: null,
                                    child: Text(s.all),
                                  ),
                                ...availableContracts.map(
                                  (contract) => DropdownMenuItem(
                                    value: contract.id,
                                    child: Text(contract.name),
                                  ),
                                ),
                              ],
                        onChanged: selectedContractorId == null
                            ? null
                            : (value) => setModal(() => selectedContractId = value),
                        validator: (value) => value == null ? s.select_contract : null,
                      ),
                      const SizedBox(height: AppPadding.normal),
                      // Период начала
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setModal(() => startDate = date);
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: s.start_date,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppSize.smallRadius),
                            ),
                          ),
                          child: Text(
                            startDate != null
                                ? DateFormat('dd.MM.yyyy').format(startDate!)
                                : s.select_date,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppPadding.normal),
                      // Период окончания
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: startDate ?? DateTime.now(),
                            firstDate: startDate ?? DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setModal(() => endDate = date);
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: s.end_date,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppSize.smallRadius),
                            ),
                          ),
                          child: Text(
                            endDate != null
                                ? DateFormat('dd.MM.yyyy').format(endDate!)
                                : s.select_date,
                          ),
                        ),
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
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;
                  if (selectedContractorId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(s.select_contractor)),
                    );
                    return;
                  }
                  if (startDate == null || endDate == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(s.select_period)),
                    );
                    return;
                  }
                  if (endDate!.isBefore(startDate!)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(s.end_date_must_be_after_start)),
                    );
                    return;
                  }
                  if (selectedContractId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(s.select_contract)),
                    );
                    return;
                  }
                  final ticket = Ticket(
                    id: '',
                    cleaningAreaId: area.id,
                    contractorId: selectedContractorId!,
                    contractId: selectedContractId!,
                    plannedStartAt: startDate!,
                    plannedEndAt: endDate!,
                    description: descriptionController.text.trim().isEmpty
                        ? null
                        : descriptionController.text.trim(),
                    status: TicketStatus.planned,
                    createdByOrgId: organizationId,
                    isActive: true,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                  controller.createTicket(ticket);
                  Navigator.of(context).pop();
                  // Переход на страницу тикетов после создания
                  context.go('/tickets');
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

