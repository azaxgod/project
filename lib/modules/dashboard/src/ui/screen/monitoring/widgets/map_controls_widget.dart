import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Плавающие виджеты управления картой
class MapControlsWidget extends StatelessWidget {
  final MapController mapController;
  final bool showAreas;
  final bool showPolygons;
  final bool showCameras;
  final bool showVehicles;
  final VoidCallback? onToggleAreas;
  final VoidCallback? onTogglePolygons;
  final VoidCallback? onToggleCameras;
  final VoidCallback? onToggleVehicles;
  final VoidCallback? onRefresh;
  final VoidCallback? onCenterMap;
  final int vehicleCount;
  final int driverCount;
  final int areaCount;
  final int polygonCount;

  const MapControlsWidget({
    super.key,
    required this.mapController,
    required this.showAreas,
    required this.showPolygons,
    required this.showCameras,
    required this.showVehicles,
    this.onToggleAreas,
    this.onTogglePolygons,
    this.onToggleCameras,
    this.onToggleVehicles,
    this.onRefresh,
    this.onCenterMap,
    this.vehicleCount = 0,
    this.driverCount = 0,
    this.areaCount = 0,
    this.polygonCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
      right: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Основные кнопки управления
          _buildControlButton(
            icon: Icons.refresh,
            tooltip: 'Обновить данные',
            onTap: onRefresh,
            color: AppColors.primary,
          ),
          const SizedBox(height: 8),
          _buildControlButton(
            icon: Icons.my_location,
            tooltip: 'Центрировать карту',
            onTap: onCenterMap ?? () => _centerToDefault(mapController),
            color: AppColors.primary,
          ),
          const SizedBox(height: 16),
          // Разделитель
          Container(
            width: 48,
            height: 1,
            color: AppColors.divider,
          ),
          const SizedBox(height: 16),
          // Переключение слоев
          _buildLayerToggle(
            icon: Icons.local_shipping_rounded,
            tooltip: 'Техника (${vehicleCount + driverCount})',
            isActive: showVehicles,
            onTap: onToggleVehicles,
            activeColor: const Color(0xFF34C759),
            count: vehicleCount + driverCount,
          ),
          const SizedBox(height: 8),
          _buildLayerToggle(
            icon: Icons.person,
            tooltip: 'Водители ($driverCount)',
            isActive: showVehicles,
            onTap: onToggleVehicles,
            activeColor: const Color(0xFF007AFF),
            count: driverCount,
            isSubLayer: true,
          ),
          const SizedBox(height: 8),
          _buildLayerToggle(
            icon: Icons.map,
            tooltip: 'Участки ($areaCount)',
            isActive: showAreas,
            onTap: onToggleAreas,
            activeColor: Colors.blue,
            count: areaCount,
          ),
          const SizedBox(height: 8),
          _buildLayerToggle(
            icon: Icons.landscape,
            tooltip: 'Полигоны ($polygonCount)',
            isActive: showPolygons,
            onTap: onTogglePolygons,
            activeColor: Colors.orange,
            count: polygonCount,
          ),
          const SizedBox(height: 8),
          _buildLayerToggle(
            icon: Icons.videocam,
            tooltip: 'Камеры',
            isActive: showCameras,
            onTap: onToggleCameras,
            activeColor: Colors.purple,
          ),
          const SizedBox(height: 16),
          // Разделитель
          Container(
            width: 48,
            height: 1,
            color: AppColors.divider,
          ),
          const SizedBox(height: 16),
          // Масштабирование
          _buildZoomButton(
            icon: Icons.add,
            tooltip: 'Приблизить',
            onTap: () => _zoomIn(mapController),
          ),
          const SizedBox(height: 4),
          _buildZoomButton(
            icon: Icons.remove,
            tooltip: 'Отдалить',
            onTap: () => _zoomOut(mapController),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onTap,
    required Color color,
  }) {
    return Material(
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(12),
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildLayerToggle({
    required IconData icon,
    required String tooltip,
    required bool isActive,
    required VoidCallback? onTap,
    required Color activeColor,
    int? count,
    bool isSubLayer = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        elevation: isActive ? 6 : 2,
        shadowColor: Colors.black.withValues(alpha: isActive ? 0.3 : 0.1),
        borderRadius: BorderRadius.circular(12),
        color: isActive ? activeColor : Colors.white,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive
                    ? activeColor.withValues(alpha: 0.5)
                    : AppColors.divider,
                width: isActive ? 2 : 1,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  icon,
                  color: isActive ? Colors.white : AppColors.textSecondary,
                  size: isSubLayer ? 20 : 22,
                ),
                if (count != null && count > 0 && !isSubLayer)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.white
                            : activeColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isActive
                              ? activeColor
                              : Colors.white,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        count > 99 ? '99+' : count.toString(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isActive
                              ? activeColor
                              : Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildZoomButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.divider,
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  void _zoomIn(MapController controller) {
    final currentZoom = controller.camera.zoom;
    controller.move(
      controller.camera.center,
      currentZoom + 1,
    );
  }

  void _zoomOut(MapController controller) {
    final currentZoom = controller.camera.zoom;
    controller.move(
      controller.camera.center,
      (currentZoom - 1).clamp(3.0, 18.0),
    );
  }

  void _centerToDefault(MapController controller) {
    const center = LatLng(54.8667, 69.1500); // Петропавловск
    controller.move(center, 12.0);
  }
}

