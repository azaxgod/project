import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/core/ui/app_textstyle.dart';
import 'package:akimat_project/modules/dashboard/src/controller/monitoring_controller.dart';
import 'package:akimat_project/modules/dashboard/src/controller/monitoring_state.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/organization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomePolygonsContractorsCard extends ConsumerWidget {
  const HomePolygonsContractorsCard({
    super.key,
    this.limit = 6,
  });

  final int limit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(monitoringControllerProvider);

    return Container(
      padding: const EdgeInsets.all(AppPadding.large),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSize.cardRadius),
        border: Border.all(color: AppColors.divider, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: AppSize.shadowBlur,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: state.data.when(
        data: (data) => _buildData(context, data),
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(AppPadding.large),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (e, _) => Text(
          e.toString(),
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _buildData(BuildContext context, MonitoringData data) {
    final polygons = data.polygons.take(limit).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppPadding.small),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(26),
                borderRadius: BorderRadius.circular(AppSize.smallRadius),
              ),
              child: Icon(
                Icons.map_outlined,
                color: AppColors.primary,
                size: AppSize.iconSize,
              ),
            ),
            const SizedBox(width: AppPadding.normal),
            Expanded(
              child: Text(
                'Полигоны и подрядчики',
                style: AppTextStyles.title2,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppPadding.normal),
        if (polygons.isEmpty)
          Text(
            'Нет полигонов',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          )
        else
          Column(
            children: [
              for (final polygon in polygons)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppPadding.small),
                  child: _PolygonRow(
                    polygonName: polygon.name,
                    isActive: polygon.isActive,
                    contractors: _getPolygonContractors(
                      data: data,
                      polygonId: polygon.id,
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  List<Organization> _getPolygonContractors({
    required MonitoringData data,
    required String polygonId,
  }) {
    final accesses = data.polygonAccesses[polygonId] ?? const [];
    final contractorIds = accesses.where((a) => a.isActive).map((a) => a.contractorId).toSet();
    return data.contractors.where((c) => contractorIds.contains(c.id)).toList();
  }
}

class _PolygonRow extends StatelessWidget {
  const _PolygonRow({
    required this.polygonName,
    required this.isActive,
    required this.contractors,
  });

  final String polygonName;
  final bool isActive;
  final List<Organization> contractors;

  @override
  Widget build(BuildContext context) {
    final statusText = isActive ? 'Активен' : 'Неактивен';
    final statusColor = isActive ? Colors.green : Colors.grey;

    return Container(
      padding: const EdgeInsets.all(AppPadding.normal),
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground,
        borderRadius: BorderRadius.circular(AppSize.cardRadius),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  polygonName,
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppPadding.xs),
                Wrap(
                  spacing: AppPadding.xs,
                  runSpacing: AppPadding.xs,
                  children: [
                    _SmallBadge(
                      text: statusText,
                      color: statusColor,
                    ),
                    if (contractors.isEmpty)
                      const _SmallBadge(
                        text: 'Без подрядчика',
                        color: Colors.blueGrey,
                      )
                    else
                      for (final c in contractors)
                        _SmallBadge(
                          text: c.name,
                          color: Colors.blue,
                        ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  const _SmallBadge({
    required this.text,
    required this.color,
  });

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppPadding.small,
        vertical: AppPadding.xs,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(AppSize.smallRadius),
        border: Border.all(color: color.withAlpha(64), width: 0.5),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
