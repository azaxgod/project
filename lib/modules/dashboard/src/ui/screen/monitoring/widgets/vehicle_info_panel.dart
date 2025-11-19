import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/core/ui/app_textstyle.dart';
import 'package:akimat_project/modules/dashboard/src/model/monitoring/vehicle_monitoring.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Панель с информацией о выбранной машине
class VehicleInfoPanel extends StatelessWidget {
  final VehicleMonitoring vehicle;

  const VehicleInfoPanel({
    super.key,
    required this.vehicle,
  });

  @override
  Widget build(BuildContext context) {
    final speed = vehicle.lastGps.speedKmh;
    final heading = vehicle.lastGps.headingDeg;
    final statusColor = _getStatusColor(vehicle.status);
    final statusText = _getStatusText(vehicle.status);
    final headingText = _getHeadingText(heading);
    final dateFormat = DateFormat('HH:mm:ss');
    final timeText = dateFormat.format(vehicle.lastGps.capturedAt);

    return Container(
      margin: const EdgeInsets.all(AppPadding.normal),
      padding: const EdgeInsets.all(AppPadding.normal),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSize.cardRadius),
        border: Border.all(color: AppColors.divider, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Заголовок с 3D иконкой
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      statusColor,
                      statusColor.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.local_shipping_rounded,
                  color: Colors.white,
                  size: 28,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppPadding.small),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.plateNumber,
                      style: AppTextStyles.headline.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (vehicle.contractorName != null)
                      Text(
                        vehicle.contractorName!,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppPadding.normal),
          // Статус
          _buildInfoRow(
            icon: Icons.circle,
            iconColor: statusColor,
            label: 'Статус',
            value: statusText,
            valueColor: statusColor,
          ),
          const Divider(height: 24),
          // Скорость (большой виджет)
          Container(
            padding: const EdgeInsets.all(AppPadding.normal),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getSpeedColor(speed).withValues(alpha: 0.1),
                  _getSpeedColor(speed).withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppSize.smallRadius),
              border: Border.all(
                color: _getSpeedColor(speed).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.speed,
                      color: _getSpeedColor(speed),
                      size: 28,
                    ),
                    const SizedBox(width: AppPadding.small),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Скорость',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '${speed.toInt()} км/ч',
                          style: AppTextStyles.headline.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _getSpeedColor(speed),
                            fontSize: 24,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Индикатор скорости (визуальный)
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _getSpeedColor(speed),
                      width: 3,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${speed.toInt()}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _getSpeedColor(speed),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppPadding.normal),
          const Divider(height: 24),
          // Направление
          _buildInfoRow(
            icon: Icons.explore,
            iconColor: AppColors.primary,
            label: 'Направление',
            value: headingText,
          ),
          // Координаты
          _buildInfoRow(
            icon: Icons.location_on,
            iconColor: AppColors.secondary,
            label: 'Координаты',
            value: '${vehicle.lastGps.lat.toStringAsFixed(6)}, ${vehicle.lastGps.lon.toStringAsFixed(6)}',
          ),
          // Время обновления
          _buildInfoRow(
            icon: Icons.access_time,
            iconColor: AppColors.textSecondary,
            label: 'Обновлено',
            value: timeText,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: AppPadding.small),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.body.copyWith(
                    color: valueColor ?? AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(VehicleStatus status) {
    switch (status) {
      case VehicleStatus.inTrip:
        return Colors.green;
      case VehicleStatus.idle:
        return Colors.orange;
      case VehicleStatus.offline:
        return Colors.grey;
    }
  }

  String _getStatusText(VehicleStatus status) {
    switch (status) {
      case VehicleStatus.inTrip:
        return 'В движении';
      case VehicleStatus.idle:
        return 'Простой';
      case VehicleStatus.offline:
        return 'Офлайн';
    }
  }

  String _getHeadingText(double heading) {
    if (heading >= 337.5 || heading < 22.5) return 'Север';
    if (heading >= 22.5 && heading < 67.5) return 'Северо-Восток';
    if (heading >= 67.5 && heading < 112.5) return 'Восток';
    if (heading >= 112.5 && heading < 157.5) return 'Юго-Восток';
    if (heading >= 157.5 && heading < 202.5) return 'Юг';
    if (heading >= 202.5 && heading < 247.5) return 'Юго-Запад';
    if (heading >= 247.5 && heading < 292.5) return 'Запад';
    if (heading >= 292.5 && heading < 337.5) return 'Северо-Запад';
    return '${heading.toInt()}°';
  }

  Color _getSpeedColor(double speed) {
    if (speed < 10) {
      return Colors.grey;
    } else if (speed < 30) {
      return Colors.orange;
    } else if (speed < 60) {
      return Colors.blue;
    } else {
      return Colors.red;
    }
  }
}

