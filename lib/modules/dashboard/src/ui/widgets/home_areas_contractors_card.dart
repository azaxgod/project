import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/core/ui/app_textstyle.dart';
import 'package:akimat_project/modules/dashboard/src/controller/monitoring_controller.dart';
import 'package:akimat_project/modules/dashboard/src/controller/monitoring_state.dart';
import 'package:akimat_project/modules/dashboard/src/model/areas/cleaning_area.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/organization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeAreasContractorsCard extends ConsumerWidget {
  const HomeAreasContractorsCard({
    super.key,
    this.limit = 8,
    this.onlyActive = true,
  });

  final int limit;
  final bool onlyActive;

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
    final areas = _filteredAreas(data.areas);
    final displayed = areas.take(limit).toList();

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
                Icons.layers_outlined,
                color: AppColors.primary,
                size: AppSize.iconSize,
              ),
            ),
            const SizedBox(width: AppPadding.normal),
            Expanded(
              child: Text(
                'Участки и подрядчики',
                style: AppTextStyles.title2,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppPadding.normal),
        if (displayed.isEmpty)
          Text(
            'Нет участков',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          )
        else
          Column(
            children: [
              for (final area in displayed)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppPadding.small),
                  child: _AreaRow(
                    area: area,
                    contractor: _findContractor(
                      contractors: data.contractors,
                      contractorId: area.defaultContractorId,
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  List<CleaningArea> _filteredAreas(List<CleaningArea> areas) {
    if (!onlyActive) return areas;
    return areas.where((a) => a.status == CleaningAreaStatus.active).toList();
  }

  Organization? _findContractor({
    required List<Organization> contractors,
    required String? contractorId,
  }) {
    if (contractorId == null || contractorId.isEmpty) return null;
    try {
      return contractors.firstWhere((c) => c.id == contractorId);
    } catch (_) {
      return null;
    }
  }
}

class _AreaRow extends StatelessWidget {
  const _AreaRow({
    required this.area,
    required this.contractor,
  });

  final CleaningArea area;
  final Organization? contractor;

  @override
  Widget build(BuildContext context) {
    final isActive = area.status == CleaningAreaStatus.active;

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
                  area.name,
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppPadding.xs),
                Wrap(
                  spacing: AppPadding.xs,
                  runSpacing: AppPadding.xs,
                  children: [
                    _SmallBadge(
                      text: isActive ? 'Активен' : 'Неактивен',
                      color: isActive ? Colors.green : Colors.grey,
                    ),
                    _SmallBadge(
                      text: area.city,
                      color: Colors.blueGrey,
                    ),
                    if (contractor == null)
                      const _SmallBadge(
                        text: 'Без подрядчика',
                        color: Colors.blueGrey,
                      )
                    else
                      _SmallBadge(
                        text: contractor!.name,
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
