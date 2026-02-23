import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/core/ui/app_textstyle.dart';
import 'package:flutter/material.dart';

class PolygonData {
  final String name;
  final String contractor;
  final String status;
  final Color color;
  final String? area;
  final double? volume;
  final DateTime? lastActivity;

  PolygonData({
    required this.name,
    required this.contractor,
    required this.status,
    required this.color,
    this.area,
    this.volume,
    this.lastActivity,
  });
}

class MapWidget extends StatelessWidget {
  final List<PolygonData> polygons;

  const MapWidget({super.key, required this.polygons});

  @override
  Widget build(BuildContext context) {
    if (polygons.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(AppSize.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: AppSize.shadowBlur,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок карты
          _buildHeader(),
          
          // Статистика подрядчиков
          _buildContractorStats(),
          
          // Сетка полигонов
          Expanded(
            child: _buildPolygonsGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(AppSize.cardRadius),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_outlined,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: AppPadding.normal),
            Text(
              'Нет активных полигонов',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppPadding.small),
            Text(
              'Полигоны подрядчиков появятся здесь',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppPadding.large),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.divider,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppPadding.small),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSize.smallRadius),
            ),
            child: Icon(
              Icons.map,
              color: Colors.green,
              size: AppSize.iconSize,
            ),
          ),
          const SizedBox(width: AppPadding.normal),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Карта полигонов',
                  style: AppTextStyles.title2,
                ),
                const SizedBox(height: 2),
                Text(
                  'Мониторинг объектов подрядчиков',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppPadding.normal,
              vertical: AppPadding.xs,
            ),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSize.smallRadius),
            ),
            child: Text(
              '${polygons.length} объектов',
              style: AppTextStyles.caption.copyWith(
                color: Colors.blue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContractorStats() {
    final contractors = polygons.map((p) => p.contractor).toSet().toList();
    final activeCount = polygons.where((p) => p.status.toUpperCase() == 'ACTIVE').length;
    
    return Container(
      padding: const EdgeInsets.all(AppPadding.normal),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              icon: Icons.business,
              label: 'Подрядчики',
              value: '${contractors.length}',
              color: Colors.blue,
            ),
          ),
          Expanded(
            child: _buildStatItem(
              icon: Icons.check_circle,
              label: 'Активны',
              value: '$activeCount',
              color: Colors.green,
            ),
          ),
          Expanded(
            child: _buildStatItem(
              icon: Icons.location_on,
              label: 'Всего',
              value: '${polygons.length}',
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: color,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.title3.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildPolygonsGrid() {
    return Container(
      padding: const EdgeInsets.all(AppPadding.normal),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6,
          childAspectRatio: 3.2,
          crossAxisSpacing: AppPadding.small,
          mainAxisSpacing: AppPadding.small,
        ),
        itemCount: polygons.length,
        itemBuilder: (context, index) {
          final polygon = polygons[index];
          return _buildPolygonCard(polygon);
        },
      ),
    );
  }

  Widget _buildPolygonCard(PolygonData polygon) {
    return Container(
      decoration: BoxDecoration(
        color: polygon.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSize.smallRadius),
        border: Border.all(
          color: polygon.color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      clipBehavior: Clip.hardEdge,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Цветовой индикатор статуса
            Container(
              width: 16,
              height: 4,
              decoration: BoxDecoration(
                color: polygon.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            const SizedBox(height: AppPadding.xs),
            
            // Название полигона
            Flexible(
              child: Text(
                polygon.name,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 9,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            const SizedBox(height: 2),
            
            // Подрядчик
            Row(
              children: [
                Icon(
                  Icons.business,
                  size: 11,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    polygon.contractor,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 8,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            
            // Статус
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 1,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(polygon.status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _getStatusText(polygon.status),
                  style: AppTextStyles.caption.copyWith(
                    color: _getStatusColor(polygon.status),
                    fontWeight: FontWeight.w600,
                    fontSize: 7,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return Colors.green;
      case 'WARNING':
        return Colors.orange;
      case 'VIOLATION':
        return Colors.red;
      case 'INACTIVE':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  String _getStatusText(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return 'Активен';
      case 'WARNING':
        return 'Внимание';
      case 'VIOLATION':
        return 'Нарушение';
      case 'INACTIVE':
        return 'Неактивен';
      default:
        return status;
    }
  }
}
