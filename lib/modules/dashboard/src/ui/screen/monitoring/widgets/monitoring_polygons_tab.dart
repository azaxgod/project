import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/core/ui/app_textstyle.dart';
import 'package:akimat_project/modules/dashboard/src/controller/monitoring_controller.dart';
import 'package:akimat_project/modules/dashboard/src/controller/monitoring_state.dart';
import 'package:akimat_project/modules/dashboard/src/model/polygons/camera.dart';
import 'package:akimat_project/modules/dashboard/src/model/polygons/polygon.dart';
import 'package:flutter/material.dart';

class MonitoringPolygonsTab extends StatelessWidget {
  final MonitoringState state;
  final MonitoringData data;
  final MonitoringController controller;
  final bool canEdit;

  const MonitoringPolygonsTab({
    super.key,
    required this.state,
    required this.data,
    required this.controller,
    required this.canEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Кнопки создания (только для тех, кто может редактировать)
        if (canEdit)
          Padding(
            padding: const EdgeInsets.all(AppPadding.normal),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      controller.setCreateMode('polygon');
                    },
                    icon: const Icon(Icons.add_circle_outline, size: 22),
                    label: const Text(
                      'Создать полигон',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSize.smallRadius),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppPadding.small),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      controller.setCreateMode('camera');
                    },
                    icon: const Icon(Icons.videocam_outlined, size: 22),
                    label: const Text(
                      'Добавить камеру',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSize.smallRadius),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        // Список полигонов
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppPadding.normal),
            itemCount: data.polygons.length,
            itemBuilder: (context, index) {
              final polygon = data.polygons[index];
              final isSelected = polygon.id == state.selectedPolygonId;
              final polygonCameras = data.cameras
                  .where((c) => c.polygonId == polygon.id)
                  .toList();
              return _buildPolygonCard(polygon, polygonCameras, isSelected);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPolygonCard(
    Polygon polygon,
    List<Camera> cameras,
    bool isSelected,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppPadding.small),
      color: isSelected
          ? AppColors.primary.withOpacity(0.1)
          : AppColors.cardBackground,
      child: InkWell(
        onTap: () => controller.selectPolygon(polygon.id),
        child: Padding(
          padding: const EdgeInsets.all(AppPadding.normal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                polygon.name,
                style: AppTextStyles.title2.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (polygon.address != null) ...[
                const SizedBox(height: AppPadding.small),
                Text(
                  polygon.address!,
                  style: AppTextStyles.caption,
                ),
              ],
              const SizedBox(height: AppPadding.small),
              Row(
                children: [
                  Chip(
                    label: Text('${cameras.length} камер'),
                    labelStyle: AppTextStyles.caption,
                  ),
                  const SizedBox(width: AppPadding.small),
                  Chip(
                    label: Text(polygon.isActive ? 'Активен' : 'Неактивен'),
                    labelStyle: AppTextStyles.caption.copyWith(
                      color: polygon.isActive ? Colors.green : Colors.grey,
                    ),
                    backgroundColor: (polygon.isActive
                            ? Colors.green
                            : Colors.grey)
                        .withOpacity(0.1),
                  ),
                ],
              ),
              // Список камер полигона
              if (cameras.isNotEmpty) ...[
                const SizedBox(height: AppPadding.small),
                ...cameras.map((camera) => Padding(
                      padding: const EdgeInsets.only(
                        left: AppPadding.normal,
                        top: AppPadding.small,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.videocam,
                            size: 16,
                            color: camera.isActive
                                ? Colors.purple
                                : Colors.grey,
                          ),
                          const SizedBox(width: AppPadding.small),
                          Expanded(
                            child: Text(
                              camera.name,
                              style: AppTextStyles.caption,
                            ),
                          ),
                          Chip(
                            label: Text(camera.type.toString().split('.').last),
                            labelStyle: AppTextStyles.caption.copyWith(
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

