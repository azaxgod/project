import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/core/ui/widgets/safe_dropdown_button.dart';
import 'package:akimat_project/modules/dashboard/src/controller/areas_controller.dart';
import 'package:akimat_project/modules/dashboard/src/controller/areas_state.dart';
import 'package:akimat_project/modules/dashboard/src/model/areas/cleaning_area.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_text_field.dart';
import 'package:flutter/material.dart';

class AreasDialogs {
  const AreasDialogs._();

  static Future<void> showCreateAreaDialog({
    required BuildContext context,
    required AreasController controller,
    required AreasData data,
    required List<List<double>> geometry,
  }) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    CleaningAreaStatus selectedStatus = CleaningAreaStatus.active;
    String? selectedContractorId;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModal) => AlertDialog(
            title: const Text('Создать участок'),
            content: SizedBox(
              width: 420,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OrganizationsTextField(
                        controller: nameController,
                        label: 'Название*',
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Введите название' : null,
                      ),
                      const SizedBox(height: AppPadding.normal),
                      TextFormField(
                        controller: descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Описание',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSize.smallRadius),
                          ),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: AppPadding.normal),
                      SafeDropdownButtonFormField<CleaningAreaStatus>(
                        value: selectedStatus,
                        decoration: InputDecoration(
                          labelText: 'Статус*',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSize.smallRadius),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: CleaningAreaStatus.active,
                            child: Text('Активный'),
                          ),
                          DropdownMenuItem(
                            value: CleaningAreaStatus.inactive,
                            child: Text('Неактивный'),
                          ),
                        ],
                        onChanged: (value) => setModal(() => selectedStatus = value!),
                      ),
                      const SizedBox(height: AppPadding.normal),
                      SafeDropdownButtonFormField<String?>(
                        value: selectedContractorId,
                        decoration: InputDecoration(
                          labelText: 'Ответственный подрядчик',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSize.smallRadius),
                          ),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Не назначен'),
                          ),
                          ...data.contractors.map(
                            (contractor) => DropdownMenuItem(
                              value: contractor.id,
                              child: Text(contractor.name),
                            ),
                          ),
                        ],
                        onChanged: (value) => setModal(() => selectedContractorId = value),
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
                  final area = CleaningArea(
                    id: '',
                    name: nameController.text.trim(),
                    description: descriptionController.text.trim().isEmpty
                        ? null
                        : descriptionController.text.trim(),
                    geometry: geometry,
                    status: selectedStatus,
                    defaultContractorId: selectedContractorId,
                    isActive: true,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                  controller.createArea(area);
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

