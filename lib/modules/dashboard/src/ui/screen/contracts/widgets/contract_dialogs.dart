import 'dart:math';
import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/core/ui/widgets/safe_dropdown_button.dart';
import 'package:akimat_project/l10n/l10n.dart';
import 'package:akimat_project/modules/dashboard/src/controller/contracts_controller.dart';
import 'package:akimat_project/modules/dashboard/src/controller/contracts_state.dart';
import 'package:akimat_project/modules/dashboard/src/model/contracts/contract.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/organization.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/organization_type.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ContractDialogs {
  const ContractDialogs._();

  static Future<void> showCreateContractDialog({
    required BuildContext context,
    required ContractsController controller,
    required ContractsData data,
    String? organizationId, // ID организации KGU ZKH, создающей контракт
  }) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final pricePerM3Controller = TextEditingController();
    final budgetTotalController = TextEditingController();
    final minimalVolumeM3Controller = TextEditingController();
    
    String? selectedContractorId;
    DateTime? startAt;
    DateTime? endAt;
    
    // Фильтруем только активных подрядчиков
    final activeContractors = data.contractors
        .where((org) => org.type == OrganizationType.contractor && org.isActive)
        .toList();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModal) => AlertDialog(
            title: Text(
              S.of(context)!.create_contract,
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
                      // Подрядчик
                      SafeDropdownButtonFormField<String?>(
                        value: selectedContractorId,
                        decoration: InputDecoration(
                          labelText: '${S.of(context)!.contractor}*',
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
                            : (value) => setModal(() => selectedContractorId = value),
                        validator: (value) =>
                            value == null ? 'Выберите подрядчика' : null,
                      ),
                      const SizedBox(height: AppPadding.normal),
                      
                      // Наименование договора
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Наименование договора*',
                          hintText: 'Номер договора',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSize.smallRadius),
                          ),
                          isDense: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Введите наименование договора';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppPadding.normal),
                      
                      // Ставка за 1 м³
                      TextFormField(
                        controller: pricePerM3Controller,
                        decoration: InputDecoration(
                          labelText: 'Ставка за 1 м³*',
                          hintText: '0.00',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSize.smallRadius),
                          ),
                          suffixText: '₸',
                          isDense: true,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Введите ставку за 1 м³';
                          }
                          final price = double.tryParse(value.trim());
                          if (price == null) {
                            return 'Введите корректное число';
                          }
                          if (price <= 0) {
                            return 'Ставка должна быть больше 0';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppPadding.normal),
                      
                      // Общий бюджет договора
                      TextFormField(
                        controller: budgetTotalController,
                        decoration: InputDecoration(
                          labelText: 'Общий бюджет договора*',
                          hintText: '0.00',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSize.smallRadius),
                          ),
                          suffixText: '₸',
                          isDense: true,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Введите общий бюджет';
                          }
                          final budget = double.tryParse(value.trim());
                          if (budget == null) {
                            return 'Введите корректное число';
                          }
                          if (budget <= 0) {
                            return 'Бюджет должен быть больше 0';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppPadding.normal),
                      
                      // Минимальный целевой объём
                      TextFormField(
                        controller: minimalVolumeM3Controller,
                        decoration: InputDecoration(
                          labelText: 'Минимальный целевой объём*',
                          hintText: '0.00',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSize.smallRadius),
                          ),
                          suffixText: 'м³',
                          isDense: true,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Введите минимальный объём';
                          }
                          final volume = double.tryParse(value.trim());
                          if (volume == null) {
                            return 'Введите корректное число';
                          }
                          if (volume <= 0) {
                            return 'Объём должен быть больше 0';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppPadding.normal),
                      
                      // Дата начала действия
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Дата начала действия*',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSize.smallRadius),
                          ),
                          suffixIcon: const Icon(Icons.calendar_today),
                          isDense: true,
                        ),
                        readOnly: true,
                        controller: TextEditingController(
                          text: startAt != null
                              ? DateFormat('dd.MM.yyyy').format(startAt!)
                              : '',
                        ),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: startAt ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (date != null) {
                            setModal(() {
                              startAt = date;
                              if (endAt != null && startAt!.isAfter(endAt!)) {
                                endAt = null;
                              }
                            });
                          }
                        },
                        validator: (value) {
                          if (startAt == null) {
                            return 'Выберите дату начала';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppPadding.normal),
                      
                      // Дата окончания действия
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Дата окончания действия*',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSize.smallRadius),
                          ),
                          suffixIcon: const Icon(Icons.calendar_today),
                          isDense: true,
                        ),
                        readOnly: true,
                        controller: TextEditingController(
                          text: endAt != null
                              ? DateFormat('dd.MM.yyyy').format(endAt!)
                              : '',
                        ),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: endAt ?? (startAt ?? DateTime.now()),
                            firstDate: startAt ?? DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (date != null) {
                            setModal(() => endAt = date);
                          }
                        },
                        validator: (value) {
                          if (endAt == null) {
                            return 'Выберите дату окончания';
                          }
                          if (startAt != null && (startAt!.isAfter(endAt!) || startAt!.isAtSameMomentAs(endAt!))) {
                            return 'Дата окончания должна быть позже даты начала';
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
                child: Text(S.of(context)!.cancel),
              ),
              FilledButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  
                  // Дополнительная валидация дат
                  if (startAt == null || endAt == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Выберите период действия контракта'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  
                  if (startAt!.isAfter(endAt!) || startAt!.isAtSameMomentAs(endAt!)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Дата начала должна быть раньше даты окончания'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  
                  try {
                    await controller.createContract(
                      contractType: ContractType.contractorService, 
                      contractorId: selectedContractorId!,
                      name: nameController.text.trim(),
                      workType: ContractWorkType.road, // Дефолтное значение, можно добавить поле в форму
                      pricePerM3: double.parse(pricePerM3Controller.text.trim()),
                      budgetTotal: double.parse(budgetTotalController.text.trim()),
                      minimalVolumeM3: double.parse(minimalVolumeM3Controller.text.trim()),
                      startAt: startAt!,
                      endAt: endAt!,
                      isActive: true,
                      createdByOrgId: organizationId, // Передаем ID организации создателя
                    );
                    
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Контракт успешно создан'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Ошибка при создании контракта: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: Text(S.of(context)!.save),
              ),
            ],
          ),
        );
      },
    );
  }
}

