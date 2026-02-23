import 'package:akimat_project/core/locale/locale_provider.dart';
import 'package:akimat_project/core/platform/platform_utils.dart';
import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/core/ui/app_textstyle.dart';
import 'package:akimat_project/modules/dashboard/src/controller/landfill_home_controller.dart';
import 'package:akimat_project/modules/dashboard/src/model/acts/act.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class LandfillHomePage extends ConsumerWidget {
  const LandfillHomePage({
    super.key,
    required this.scaffoldKey,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localeProvider);
    final config = PlatformConfig.instance;
    final state = ref.watch(landfillHomeControllerProvider);
    final controller = ref.read(landfillHomeControllerProvider.notifier);

    return Container(
      margin: EdgeInsets.all(config.padding),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Container(
              padding: const EdgeInsets.all(AppPadding.large),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(AppSize.cardRadius),
                border: Border.all(color: AppColors.divider, width: 0.5),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppPadding.normal),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSize.smallRadius),
                    ),
                    child: Icon(
                      Icons.dashboard,
                      color: AppColors.primary,
                      size: AppSize.iconSizeLarge,
                    ),
                  ),
                  const SizedBox(width: AppPadding.normal),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Главная',
                          style: AppTextStyles.title1,
                        ),
                        const SizedBox(height: AppPadding.xs),
                        Text(
                          'Дашборд организации приёма снега',
                          style: AppTextStyles.footnote.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: controller.refresh,
                    tooltip: 'Обновить',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppPadding.large),
            // KPI карточки
            Text(
              'Метрики',
              style: AppTextStyles.title2,
            ),
            const SizedBox(height: AppPadding.normal),
            state.data.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Container(
                padding: const EdgeInsets.all(AppPadding.large),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(AppSize.cardRadius),
                  border: Border.all(color: AppColors.divider, width: 0.5),
                ),
                child: Column(
                  children: [
                    Text(
                      'Ошибка загрузки данных: $error',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: AppPadding.normal),
                    ElevatedButton(
                      onPressed: controller.refresh,
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              ),
              data: (data) => Row(
                children: [
                  Expanded(
                    child: _buildKpiCard(
                      'Активные полигоны',
                      data.activePolygonsCount.toString(),
                      Icons.map,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: AppPadding.normal),
                  Expanded(
                    child: _buildKpiCard(
                      'Камеры',
                      data.camerasCount.toString(),
                      Icons.videocam,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: AppPadding.normal),
                  Expanded(
                    child: _buildKpiCard(
                      'Объём за месяц',
                      '${data.monthlyVolumeM3.toStringAsFixed(1)} м³',
                      Icons.water_drop,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppPadding.large),
            // Последние акты
            Text(
              'Последние акты',
              style: AppTextStyles.title2,
            ),
            const SizedBox(height: AppPadding.normal),
            state.data.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (data) {
                if (data.recentActs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(AppPadding.large),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(AppSize.cardRadius),
                      border: Border.all(color: AppColors.divider, width: 0.5),
                    ),
                    child: Text(
                      'Нет актов',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                }

                // Группируем акты по статусу
                final draftActs = data.recentActs
                    .where((a) => a.status == ActStatus.draft)
                    .toList();
                final sentActs = data.recentActs
                    .where((a) => a.status == ActStatus.sentToLandfill)
                    .toList();
                final confirmedActs = data.recentActs
                    .where((a) => a.status == ActStatus.confirmedByLandfill)
                    .toList();

                return Column(
                  children: [
                    if (draftActs.isNotEmpty) ...[
                      _buildActsSection('Новые черновики', draftActs),
                      const SizedBox(height: AppPadding.normal),
                    ],
                    if (sentActs.isNotEmpty) ...[
                      _buildActsSection('Отправлено КГУ', sentActs),
                      const SizedBox(height: AppPadding.normal),
                    ],
                    if (confirmedActs.isNotEmpty) ...[
                      _buildActsSection('Ожидают подтверждения', confirmedActs),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppPadding.large),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSize.cardRadius),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppPadding.small),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSize.smallRadius),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: AppPadding.normal),
          Text(
            value,
            style: AppTextStyles.title1.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppPadding.xs),
          Text(
            title,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActsSection(String title, List<Act> acts) {
    return Container(
      padding: const EdgeInsets.all(AppPadding.normal),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSize.cardRadius),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.title3,
          ),
          const SizedBox(height: AppPadding.normal),
          ...acts.map((act) => _buildActItem(act)),
        ],
      ),
    );
  }

  Widget _buildActItem(Act act) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppPadding.small),
      padding: const EdgeInsets.all(AppPadding.normal),
      decoration: BoxDecoration(
        color: AppColors.background,
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
                  'Акт №${act.actNumber}',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppPadding.xs),
                Text(
                  '${DateFormat('dd.MM.yyyy').format(act.periodStart)} - ${DateFormat('dd.MM.yyyy').format(act.periodEnd)}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppPadding.small,
              vertical: AppPadding.xs,
            ),
            decoration: BoxDecoration(
              color: _getStatusColor(act.status).withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppSize.smallRadius),
            ),
            child: Text(
              _getStatusLabel(act.status),
              style: AppTextStyles.caption.copyWith(
                color: _getStatusColor(act.status),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ActStatus status) {
    switch (status) {
      case ActStatus.draft:
        return Colors.grey;
      case ActStatus.sentToLandfill:
        return Colors.orange;
      case ActStatus.confirmedByLandfill:
        return Colors.blue;
      case ActStatus.approvedByKgu:
        return Colors.green;
      case ActStatus.rejected:
        return Colors.red;
      case ActStatus.signed:
        return Colors.purple;
    }
  }

  String _getStatusLabel(ActStatus status) {
    switch (status) {
      case ActStatus.draft:
        return 'Черновик';
      case ActStatus.sentToLandfill:
        return 'Отправлен';
      case ActStatus.confirmedByLandfill:
        return 'Подтверждён';
      case ActStatus.approvedByKgu:
        return 'Утверждён';
      case ActStatus.rejected:
        return 'Отклонён';
      case ActStatus.signed:
        return 'Подписан';
    }
  }
}
