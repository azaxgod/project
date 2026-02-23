import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/core/ui/app_textstyle.dart';
import 'package:akimat_project/modules/dashboard/src/controller/monitoring_controller.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/organization.dart';
import 'package:akimat_project/modules/dashboard/src/model/polygons/camera.dart';
import 'package:akimat_project/modules/dashboard/src/model/polygons/polygon.dart';
import 'package:flutter/material.dart';

/// Диалог создания участка уборки
Future<void> showCreateAreaDialog(
  BuildContext context,
  MonitoringController controller,
  List<Organization> contractors,
) async {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final cityController = TextEditingController(text: 'Петропавловск');
  String? selectedContractorId;

  await showDialog<void>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModal) => AlertDialog(
          title: const Text('Создать участок уборки'),
          content: SizedBox(
            width: 500,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Название*',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSize.cardRadius),
                        ),
                      ),
                      style: AppTextStyles.body,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите название';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppPadding.normal),
                    TextFormField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Описание',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSize.cardRadius),
                        ),
                      ),
                      style: AppTextStyles.body,
                      maxLines: 3,
                    ),
                    const SizedBox(height: AppPadding.normal),
                    TextFormField(
                      controller: cityController,
                      decoration: InputDecoration(
                        labelText: 'Город*',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSize.cardRadius),
                        ),
                      ),
                      style: AppTextStyles.body,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите город';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppPadding.normal),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Подрядчик по умолчанию',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSize.cardRadius),
                        ),
                      ),
                      initialValue: selectedContractorId,
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Не выбран'),
                        ),
                        ...contractors.map((org) => DropdownMenuItem<String>(
                              value: org.id,
                              child: Text(org.name),
                            )),
                      ],
                      onChanged: (value) {
                        setModal(() => selectedContractorId = value);
                      },
                    ),
                    const SizedBox(height: AppPadding.normal),
                    Container(
                      padding: const EdgeInsets.all(AppPadding.normal),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryBackground,
                        borderRadius: BorderRadius.circular(AppSize.smallRadius),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 20, color: AppColors.textSecondary),
                          const SizedBox(width: AppPadding.small),
                          Expanded(
                            child: Text(
                              'Геометрия участка будет добавлена на карте после создания',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
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
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                // Временная геометрия (квадрат вокруг центра города)
                // В реальности геометрия должна быть нарисована на карте
                const centerLat = 54.8667;
                const centerLon = 69.1500;
                const offset = 0.01; // ~1км
                final geometry = [
                  [centerLon - offset, centerLat - offset], // SW
                  [centerLon + offset, centerLat - offset], // SE
                  [centerLon + offset, centerLat + offset], // NE
                  [centerLon - offset, centerLat + offset], // NW
                  [centerLon - offset, centerLat - offset], // Close polygon
                ];

                try {
                  await controller.createCleaningArea(
                    name: nameController.text.trim(),
                    description: descriptionController.text.trim().isEmpty
                        ? null
                        : descriptionController.text.trim(),
                    geometry: geometry,
                    city: cityController.text.trim(),
                    defaultContractorId: selectedContractorId,
                  );
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Участок успешно создан'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Ошибка создания участка: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Создать'),
            ),
          ],
        ),
      );
    },
  );
}

/// Диалог создания полигона
Future<void> showCreatePolygonDialog(
  BuildContext context,
  MonitoringController controller,
) async {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final addressController = TextEditingController();
  final descriptionController = TextEditingController();
  bool isActive = true;

  await showDialog<void>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModal) => AlertDialog(
          title: const Text('Создать полигон'),
          content: SizedBox(
            width: 500,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Название*',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSize.cardRadius),
                        ),
                      ),
                      style: AppTextStyles.body,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите название';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppPadding.normal),
                    TextFormField(
                      controller: addressController,
                      decoration: InputDecoration(
                        labelText: 'Адрес',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSize.cardRadius),
                        ),
                      ),
                      style: AppTextStyles.body,
                    ),
                    const SizedBox(height: AppPadding.normal),
                    TextFormField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Описание',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSize.cardRadius),
                        ),
                      ),
                      style: AppTextStyles.body,
                      maxLines: 3,
                    ),
                    const SizedBox(height: AppPadding.normal),
                    CheckboxListTile(
                      title: const Text('Активен'),
                      value: isActive,
                      onChanged: (value) {
                        setModal(() => isActive = value ?? true);
                      },
                    ),
                    const SizedBox(height: AppPadding.normal),
                    Container(
                      padding: const EdgeInsets.all(AppPadding.normal),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryBackground,
                        borderRadius: BorderRadius.circular(AppSize.smallRadius),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 20, color: AppColors.textSecondary),
                          const SizedBox(width: AppPadding.small),
                          Expanded(
                            child: Text(
                              'Геометрия полигона будет добавлена на карте после создания',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
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
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                // Временная геометрия (квадрат вокруг центра города)
                // В реальности геометрия должна быть нарисована на карте
                const centerLat = 54.8667;
                const centerLon = 69.1500;
                const offset = 0.005; // ~500м
                final geometry = [
                  [centerLon - offset, centerLat - offset], // SW
                  [centerLon + offset, centerLat - offset], // SE
                  [centerLon + offset, centerLat + offset], // NE
                  [centerLon - offset, centerLat + offset], // NW
                  [centerLon - offset, centerLat - offset], // Close polygon
                ];

                try {
                  await controller.createPolygon(
                    name: nameController.text.trim(),
                    address: addressController.text.trim().isEmpty
                        ? null
                        : addressController.text.trim(),
                    description: descriptionController.text.trim().isEmpty
                        ? null
                        : descriptionController.text.trim(),
                    geometry: geometry,
                    isActive: isActive,
                  );
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Полигон успешно создан'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Ошибка создания полигона: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Создать'),
            ),
          ],
        ),
      );
    },
  );
}

/// Диалог создания камеры
Future<void> showCreateCameraDialog(
  BuildContext context,
  MonitoringController controller,
  List<Polygon> polygons,
) async {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  String? selectedPolygonId;
  CameraType selectedType = CameraType.lpr;
  bool isActive = true;

  await showDialog<void>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModal) => AlertDialog(
          title: const Text('Добавить камеру'),
          content: SizedBox(
            width: 500,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Полигон*',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSize.cardRadius),
                        ),
                      ),
                      initialValue: selectedPolygonId,
                      items: polygons.map((polygon) => DropdownMenuItem<String>(
                            value: polygon.id,
                            child: Text(polygon.name),
                          )).toList(),
                      onChanged: (value) {
                        setModal(() => selectedPolygonId = value);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Выберите полигон';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppPadding.normal),
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Название*',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSize.cardRadius),
                        ),
                      ),
                      style: AppTextStyles.body,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите название';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppPadding.normal),
                    DropdownButtonFormField<CameraType>(
                      decoration: InputDecoration(
                        labelText: 'Тип камеры*',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSize.cardRadius),
                        ),
                      ),
                      initialValue: selectedType,
                      items: CameraType.values.map((type) => DropdownMenuItem<CameraType>(
                            value: type,
                            child: Text(type == CameraType.lpr ? 'LPR' : 'VOLUME'),
                          )).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setModal(() => selectedType = value);
                        }
                      },
                    ),
                    const SizedBox(height: AppPadding.normal),
                    CheckboxListTile(
                      title: const Text('Активна'),
                      value: isActive,
                      onChanged: (value) {
                        setModal(() => isActive = value ?? true);
                      },
                    ),
                    const SizedBox(height: AppPadding.normal),
                    Container(
                      padding: const EdgeInsets.all(AppPadding.normal),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryBackground,
                        borderRadius: BorderRadius.circular(AppSize.smallRadius),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 20, color: AppColors.textSecondary),
                          const SizedBox(width: AppPadding.small),
                          Expanded(
                            child: Text(
                              'Местоположение камеры будет добавлено на карте после создания',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
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
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                if (selectedPolygonId == null) return;

                // Временное местоположение (центр города)
                // В реальности местоположение должно быть выбрано на карте
                const location = [69.1500, 54.8667]; // [lon, lat]

                try {
                  await controller.createCamera(
                    polygonId: selectedPolygonId!,
                    type: selectedType,
                    name: nameController.text.trim(),
                    location: location,
                    isActive: isActive,
                  );
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Камера успешно добавлена'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Ошибка создания камеры: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Создать'),
            ),
          ],
        ),
      );
    },
  );
}

