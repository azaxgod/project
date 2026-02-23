import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/core/ui/widgets/safe_dropdown_button.dart';
import 'package:akimat_project/modules/dashboard/src/controller/polygons_controller.dart';
import 'package:akimat_project/modules/dashboard/src/controller/polygons_state.dart';
import 'package:akimat_project/modules/dashboard/src/model/polygons/camera.dart';
import 'package:akimat_project/modules/dashboard/src/model/polygons/polygon.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_text_field.dart';
import 'package:flutter/material.dart';

class PolygonsDialogs {
  const PolygonsDialogs._();

  static Future<void> showCreatePolygonDialog({
    required BuildContext context,
    required PolygonsController controller,
    required List<List<double>> geometry,
  }) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final descriptionController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Создать полигон'),
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
                    OrganizationsTextField(
                      controller: addressController,
                      label: 'Адрес',
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
                final polygon = Polygon(
                  id: '',
                  name: nameController.text.trim(),
                  address: addressController.text.trim().isEmpty
                      ? null
                      : addressController.text.trim(),
                  description: descriptionController.text.trim().isEmpty
                      ? null
                      : descriptionController.text.trim(),
                  geometry: geometry,
                  isActive: true,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );
                controller.createPolygon(polygon);
                Navigator.of(context).pop();
              },
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );
  }

  static Future<void> showCreateCameraDialog({
    required BuildContext context,
    required PolygonsController controller,
    required String polygonId,
  }) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    CameraType selectedType = CameraType.lpr;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModal) => AlertDialog(
            title: const Text('Добавить камеру'),
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
                        label: 'Имя камеры*',
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Введите имя' : null,
                      ),
                      const SizedBox(height: AppPadding.normal),
                      SafeDropdownButtonFormField<CameraType>(
                        value: selectedType,
                        decoration: InputDecoration(
                          labelText: 'Тип*',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSize.smallRadius),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: CameraType.lpr,
                            child: Text('LPR (Распознавание номера)'),
                          ),
                          DropdownMenuItem(
                            value: CameraType.volume,
                            child: Text('VOLUME (Объем кузова)'),
                          ),
                        ],
                        onChanged: (value) => setModal(() => selectedType = value!),
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
                  final camera = Camera(
                    id: '',
                    polygonId: polygonId,
                    type: selectedType,
                    name: nameController.text.trim(),
                    location: null,
                    isActive: true,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                  controller.createCamera(camera);
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

