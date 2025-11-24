import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/core/ui/app_textstyle.dart';
import 'package:akimat_project/modules/dashboard/src/controller/monitoring_controller.dart';
import 'package:akimat_project/modules/dashboard/src/controller/monitoring_state.dart';
import 'package:akimat_project/modules/dashboard/src/model/areas/cleaning_area.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MonitoringAreasTab extends ConsumerWidget {
  final MonitoringState state;
  final MonitoringData data;
  final MonitoringController controller;
  final bool canEdit;

  const MonitoringAreasTab({
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
        // Кнопка создания участка (только для тех, кто может редактировать)
        if (canEdit)
          Padding(
            padding: const EdgeInsets.all(AppPadding.normal),
            child: SizedBox(
              width: double.infinity,
              child: Material(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppSize.smallRadius),
                child: InkWell(
                  onTap: () {
                    debugPrint('=== MonitoringAreasTab: Create area button pressed ===');
                    debugPrint('MonitoringAreasTab: Current createMode=${currentState.createMode}');
                    debugPrint('MonitoringAreasTab: Controller hash=${controller.hashCode}');
                    
                    // Вызываем метод напрямую
                    controller.setCreateMode('area');
                    
                    debugPrint('MonitoringAreasTab: setCreateMode("area") called');
                    
                    // Проверяем состояние сразу после вызова
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      final updatedState = ref.read(monitoringControllerProvider);
                      debugPrint('MonitoringAreasTab: After setCreateMode, createMode=${updatedState.createMode}');
                      debugPrint('MonitoringAreasTab: State hash=${updatedState.hashCode}');
                    });
                  },
                  borderRadius: BorderRadius.circular(AppSize.smallRadius),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppSize.smallRadius),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
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
                          'Создать участок',
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
          ),
        // Список участков
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppPadding.normal),
            itemCount: data.areas.length,
            itemBuilder: (context, index) {
              final area = data.areas[index];
              final isSelected = area.id == currentState.selectedAreaId;
              return _buildAreaCard(area, isSelected);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAreaCard(CleaningArea area, bool isSelected) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppPadding.small),
      color: isSelected
          ? AppColors.primary.withOpacity(0.1)
          : AppColors.cardBackground,
      child: InkWell(
        onTap: () => controller.selectArea(area.id),
        child: Padding(
          padding: const EdgeInsets.all(AppPadding.normal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                area.name,
                style: AppTextStyles.title2.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (area.description != null) ...[
                const SizedBox(height: AppPadding.small),
                Text(
                  area.description!,
                  style: AppTextStyles.caption,
                ),
              ],
              const SizedBox(height: AppPadding.small),
              Row(
                children: [
                  _buildStatusChip(area.status),
                  const SizedBox(width: AppPadding.small),
                  Chip(
                    label: Text(area.city),
                    labelStyle: AppTextStyles.caption,
                  ),
                ],
              ),
              // Подрядчик по умолчанию
              if (area.defaultContractorId != null) ...[
                const SizedBox(height: AppPadding.small),
                _buildContractorChip(area.defaultContractorId!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(CleaningAreaStatus status) {
    Color color;
    String label;
    switch (status) {
      case CleaningAreaStatus.active:
        color = Colors.green;
        label = 'Активен';
        break;
      case CleaningAreaStatus.inactive:
        color = Colors.grey;
        label = 'Неактивен';
        break;
      default:
        color = Colors.orange;
        label = 'Неизвестно';
    }
    return Chip(
      label: Text(label),
      labelStyle: AppTextStyles.caption.copyWith(color: color),
      backgroundColor: color.withOpacity(0.1),
    );
  }

  Widget _buildContractorChip(String contractorId) {
    // Находим подрядчика по ID
    final contractor = data.contractors.where(
      (org) => org.id == contractorId,
    ).firstOrNull;
    
    if (contractor == null) {
      return const SizedBox.shrink();
    }
    
    return Row(
      children: [
        Icon(Icons.business, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            'Подрядчик: ${contractor.name}',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

