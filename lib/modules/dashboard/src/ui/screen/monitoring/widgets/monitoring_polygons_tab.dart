import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/core/ui/app_textstyle.dart';
import 'package:akimat_project/modules/dashboard/src/controller/monitoring_controller.dart';
import 'package:akimat_project/modules/dashboard/src/controller/monitoring_state.dart';
import 'package:akimat_project/modules/dashboard/src/model/polygons/camera.dart';
import 'package:akimat_project/modules/dashboard/src/model/polygons/polygon.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MonitoringPolygonsTab extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    // ВАЖНО: Получаем актуальное состояние через ref.watch
    // чтобы виджет перестраивался при изменении createMode
    final currentState = ref.watch(monitoringControllerProvider);
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
                  child: Material(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppSize.smallRadius),
                    child: InkWell(
                      onTap: () {
                        debugPrint('MonitoringPolygonsTab: Create polygon button pressed');
                        try {
                          controller.setCreateMode('polygon');
                          debugPrint('MonitoringPolygonsTab: setCreateMode called successfully, createMode=${currentState.createMode}');
                        } catch (e, stack) {
                          debugPrint('MonitoringPolygonsTab: Error calling setCreateMode: $e');
                          debugPrint('MonitoringPolygonsTab: Stack: $stack');
                        }
                      },
                      borderRadius: BorderRadius.circular(AppSize.smallRadius),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppSize.smallRadius),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_circle_outline, size: 22, color: Colors.white),
                            const SizedBox(width: 8),
                            const Text(
                              'Создать полигон',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppPadding.small),
                SizedBox(
                  width: double.infinity,
                  child: Material(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(AppSize.smallRadius),
                    child: InkWell(
                      onTap: () {
                        debugPrint('MonitoringPolygonsTab: Add camera button pressed');
                        debugPrint('MonitoringPolygonsTab: Current createMode=${currentState.createMode}');
                        try {
                          controller.setCreateMode('camera');
                          debugPrint('MonitoringPolygonsTab: setCreateMode("camera") called successfully');
                          // Проверяем состояние после вызова
                          Future.delayed(const Duration(milliseconds: 100), () {
                            final updatedState = ref.read(monitoringControllerProvider);
                            debugPrint('MonitoringPolygonsTab: Updated createMode=${updatedState.createMode}');
                          });
                        } catch (e, stack) {
                          debugPrint('MonitoringPolygonsTab: Error calling setCreateMode: $e');
                          debugPrint('MonitoringPolygonsTab: Stack: $stack');
                        }
                      },
                      borderRadius: BorderRadius.circular(AppSize.smallRadius),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppSize.smallRadius),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.secondary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.videocam_outlined, size: 22, color: Colors.white),
                            const SizedBox(width: 8),
                            const Text(
                              'Добавить камеру',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
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
              final isSelected = polygon.id == currentState.selectedPolygonId;
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

