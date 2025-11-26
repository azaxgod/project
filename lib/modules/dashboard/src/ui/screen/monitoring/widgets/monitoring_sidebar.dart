import 'package:akimat_project/core/platform/platform_utils.dart';
import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/core/ui/app_textstyle.dart';
import 'package:akimat_project/modules/dashboard/src/controller/monitoring_controller.dart';
import 'package:akimat_project/modules/dashboard/src/controller/monitoring_state.dart';
import 'package:akimat_project/modules/dashboard/src/model/monitoring/vehicle_monitoring.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/user_role.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/monitoring/widgets/monitoring_areas_tab.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/monitoring/widgets/monitoring_polygons_tab.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/monitoring/widgets/vehicle_info_panel.dart';
import 'package:flutter/material.dart';

class MonitoringSidebar extends StatelessWidget {
  final MonitoringState state;
  final MonitoringData data;
  final MonitoringController controller;

  const MonitoringSidebar({
    super.key,
    required this.state,
    required this.data,
    required this.controller,
  });

  bool _canEdit() {
    return state.role == UserRole.akimatAdmin ||
        state.role == UserRole.kguZkhAdmin ||
        state.role == UserRole.landfillAdmin;
  }

  @override
  Widget build(BuildContext context) {
    final config = PlatformConfig.instance;

    return Container(
      margin: EdgeInsets.all(config.padding),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSize.cardRadius),
        border: Border.all(color: AppColors.divider, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: AppSize.shadowBlur,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Заголовок с вкладками
          Container(
            padding: const EdgeInsets.all(AppPadding.normal),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.divider, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton('Участки', 'areas'),
                ),
                const SizedBox(width: AppPadding.small),
                Expanded(
                  child: _buildTabButton('Полигоны', 'polygons'),
                ),
              ],
            ),
          ),
          // Информация о выбранной машине
          if (state.selectedVehicleId != null)
            _buildSelectedVehicleInfo(),
          // Контент вкладок
          Expanded(
            child: _buildTabContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, String tab) {
    final isActive = state.selectedTab == tab;
    return InkWell(
      onTap: () => controller.setSelectedTab(tab),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppPadding.normal,
          vertical: AppPadding.small,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSize.smallRadius),
          border: isActive
              ? Border.all(color: AppColors.primary, width: 1)
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.body.copyWith(
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedVehicleInfo() {
    final vehicle = data.vehicles.firstWhere(
      (v) => v.vehicleId == state.selectedVehicleId,
      orElse: () => throw StateError('Vehicle not found'),
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppPadding.normal),
      padding: const EdgeInsets.only(bottom: AppPadding.normal),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Информация о машине',
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () {
                  controller.selectVehicle(null);
                },
                icon: const Icon(Icons.close, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                tooltip: 'Закрыть',
              ),
            ],
          ),
          const SizedBox(height: AppPadding.small),
          VehicleInfoPanel(vehicle: vehicle),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    switch (state.selectedTab) {
      case 'areas':
        return MonitoringAreasTab(
          state: state,
          data: data,
          controller: controller,
          canEdit: _canEdit(),
        );
      case 'polygons':
        return MonitoringPolygonsTab(
          state: state,
          data: data,
          controller: controller,
          canEdit: _canEdit(),
        );
      default:
        return const Center(child: Text('Выберите вкладку'));
    }
  }
}

