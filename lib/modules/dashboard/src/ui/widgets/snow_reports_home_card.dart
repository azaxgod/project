import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/core/ui/app_textstyle.dart';
import 'package:akimat_project/modules/analytics/src/controller/analytics_providers.dart';
import 'package:akimat_project/services/anpr/model/anpr_report.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class SnowReportsHomeCard extends ConsumerStatefulWidget {
  const SnowReportsHomeCard({
    super.key,
    this.compact = false,
  });

  final bool compact;

  @override
  ConsumerState<SnowReportsHomeCard> createState() => _SnowReportsHomeCardState();
}

class _SnowReportsHomeCardState extends ConsumerState<SnowReportsHomeCard> {
  bool _hasLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _hasLoaded) return;
      _hasLoaded = true;

      final now = DateTime.now();
      final from = now.subtract(const Duration(hours: 24));
      ref.read(anprControllerProvider.notifier).loadReports(
            from: from,
            to: now,
            limit: 5,
            offset: 0,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(anprControllerProvider);
    final reports = state.reports;

    return Container(
      padding: const EdgeInsets.all(AppPadding.normal),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.cyan.withAlpha(38),
            Colors.cyan.withAlpha(13),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSize.cardRadius),
        border: Border.all(color: Colors.cyan.withAlpha(77), width: 0.5),
      ),
      child: reports == null
          ? _buildLoading()
          : reports.when(
              data: (data) => _buildData(context, data),
              loading: _buildLoading,
              error: (e, _) => _buildError(e.toString()),
            ),
    );
  }

  Widget _buildLoading() {
    return const Padding(
      padding: EdgeInsets.all(AppPadding.large),
      child: Center(
        child: SizedBox(
          height: 28,
          width: 28,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    return Padding(
      padding: const EdgeInsets.all(AppPadding.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Отчеты по объему снега',
            style: AppTextStyles.title3.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppPadding.small),
          Text(
            message,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildData(BuildContext context, AnprReportData reportData) {
    final tripCount = reportData.tripCount;
    final totalVolume = reportData.totalVolume;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _kpi(
                title: 'Поездок (24ч)',
                value: tripCount.toString(),
                valueColor: Colors.blue,
              ),
            ),
            const SizedBox(width: AppPadding.normal),
            Expanded(
              child: _kpi(
                title: 'Объем снега (24ч)',
                value: '${totalVolume.toStringAsFixed(1)} м³',
                valueColor: Colors.cyan,
              ),
            ),
          ],
        ),
        if (!widget.compact) ...[
          const SizedBox(height: AppPadding.normal),
          const Divider(height: 1),
          const SizedBox(height: AppPadding.normal),
          Text(
            'Последние рейсы',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppPadding.small),
          if (reportData.events.isEmpty)
            Text(
              'Нет данных за период',
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            )
          else
            ...reportData.events.take(5).map((event) => _eventRow(event)),
        ] else ...[
          const SizedBox(height: AppPadding.small),
          if (reportData.events.isNotEmpty)
            _eventRow(reportData.events.first),
        ],
      ],
    );
  }

  Widget _kpi({
    required String title,
    required String value,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppPadding.normal),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSize.smallRadius),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.title2.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _eventRow(AnprReportEvent event) {
    final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(event.eventTime.toLocal());
    final vehicle = [event.vehicleBrand, event.vehicleModel]
        .where((e) => e != null && e.trim().isNotEmpty)
        .map((e) => e as String)
        .join(' ');

    return Container(
      margin: const EdgeInsets.only(bottom: AppPadding.small),
      padding: const EdgeInsets.all(AppPadding.small),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSize.smallRadius),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.plateNumber,
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  dateStr,
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                ),
                if (vehicle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    vehicle,
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                  ),
                ],
                if (event.contractorName != null && event.contractorName!.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    event.contractorName!,
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          if (event.snowVolumeM3 != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppPadding.small,
                vertical: AppPadding.xs,
              ),
              decoration: BoxDecoration(
                color: Colors.cyan.withAlpha(26),
                borderRadius: BorderRadius.circular(AppSize.smallRadius),
                border: Border.all(color: Colors.cyan.withAlpha(64), width: 0.5),
              ),
              child: Text(
                '${event.snowVolumeM3!.toStringAsFixed(1)} м³',
                style: AppTextStyles.body.copyWith(
                  color: Colors.cyan,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
