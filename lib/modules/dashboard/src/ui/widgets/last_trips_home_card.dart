import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/core/ui/app_textstyle.dart';
import 'package:akimat_project/modules/analytics/src/controller/analytics_providers.dart';
import 'package:akimat_project/services/anpr/model/anpr_report.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class LastTripsHomeCard extends ConsumerStatefulWidget {
  const LastTripsHomeCard({
    super.key,
    this.limit = 5,
  });

  final int limit;

  @override
  ConsumerState<LastTripsHomeCard> createState() => _LastTripsHomeCardState();
}

class _LastTripsHomeCardState extends ConsumerState<LastTripsHomeCard> {
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
            limit: 50,
            offset: 0,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final state = ref.watch(anprControllerProvider);
    final reports = state.reports;

    return Container(
      padding: const EdgeInsets.all(AppPadding.normal),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppSize.cardRadius),
        border: Border.all(
          color: scheme.outlineVariant.withAlpha(140),
          width: 0.8,
        ),
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
            'Последние рейсы',
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final events = reportData.events.take(widget.limit).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Последние рейсы (24ч)',
                style: AppTextStyles.title3.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Обновить',
              onPressed: () {
                final now = DateTime.now();
                final from = now.subtract(const Duration(hours: 24));
                ref.read(anprControllerProvider.notifier).loadReports(
                      from: from,
                      to: now,
                      limit: 50,
                      offset: 0,
                    );
              },
              icon: Icon(
                Icons.refresh,
                color: scheme.onSurface.withAlpha(220),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppPadding.normal),
        const Divider(height: 1),
        const SizedBox(height: AppPadding.normal),
        if (events.isEmpty)
          Text(
            'Нет данных за период',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          )
        else
          ...events.map((event) => _eventRow(context, event)),
      ],
    );
  }

  Widget _eventRow(BuildContext context, AnprReportEvent event) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(event.eventTime.toLocal());
    final vehicle = [event.vehicleBrand, event.vehicleModel]
        .where((e) => e != null && e.trim().isNotEmpty)
        .map((e) => e as String)
        .join(' ');

    return Container(
      margin: const EdgeInsets.only(bottom: AppPadding.small),
      padding: const EdgeInsets.all(AppPadding.small),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(200),
        borderRadius: BorderRadius.circular(AppSize.smallRadius),
        border: Border.all(color: scheme.outlineVariant.withAlpha(140), width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.plateNumber,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
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
