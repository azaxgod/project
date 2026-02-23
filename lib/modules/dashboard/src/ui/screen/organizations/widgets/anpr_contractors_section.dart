import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/core/ui/app_textstyle.dart';
import 'package:akimat_project/modules/analytics/src/controller/analytics_providers.dart';
import 'package:akimat_project/modules/analytics/src/controller/anpr_controller.dart';
import 'package:akimat_project/modules/analytics/src/ui/widgets/animated_kpi_card.dart';
import 'package:akimat_project/services/anpr/model/anpr_event.dart';
import 'package:akimat_project/services/anpr/model/anpr_report.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Виджет для отображения ANPR данных на странице подрядчиков
class AnprContractorsSection extends ConsumerStatefulWidget {
  const AnprContractorsSection({
    super.key,
    this.contractorId,
  });

  final String? contractorId;

  @override
  ConsumerState<AnprContractorsSection> createState() =>
      _AnprContractorsSectionState();
}

class _AnprContractorsSectionState
    extends ConsumerState<AnprContractorsSection> {
  DateTime? _dateFrom;
  DateTime? _dateTo;

  @override
  void initState() {
    super.initState();
    // Устанавливаем диапазон по умолчанию (текущий месяц)
    final now = DateTime.now();
    _dateTo = now;
    _dateFrom = DateTime(now.year, now.month, 1);
  }

  @override
  Widget build(BuildContext context) {
    final anprState = ref.watch(anprControllerProvider);
    final anprController = ref.read(anprControllerProvider.notifier);

    // Загружаем данные при первой загрузке
    if (anprState.statistics == null && _dateFrom != null && _dateTo != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        anprController.loadStatistics(from: _dateFrom, to: _dateTo);
        anprController.loadEvents(from: _dateFrom, to: _dateTo);
        anprController.loadReports(from: _dateFrom, to: _dateTo);
      });
    }

    return Container(
      margin: const EdgeInsets.only(top: AppPadding.large),
      padding: const EdgeInsets.all(AppPadding.large),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppPadding.small),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSize.smallRadius),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppPadding.normal),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ANPR - Распознавание номеров',
                      style: AppTextStyles.title2.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Данные системы автоматического распознавания номеров',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppPadding.large),
          // Фильтры
          Container(
            padding: const EdgeInsets.all(AppPadding.normal),
            decoration: BoxDecoration(
              color: AppColors.secondaryBackground,
              borderRadius: BorderRadius.circular(AppSize.smallRadius),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Период',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppPadding.xs),
                      Text(
                        _dateFrom != null && _dateTo != null
                            ? '${DateFormat('dd.MM.yyyy').format(_dateFrom!)} - ${DateFormat('dd.MM.yyyy').format(_dateTo!)}'
                            : 'Не выбран',
                        style: AppTextStyles.body,
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final now = DateTime.now();
                    final firstDay = DateTime(now.year, now.month, 1);
                    final lastDay = DateTime(now.year, now.month + 1, 0);
                    
                    setState(() {
                      _dateFrom = firstDay;
                      _dateTo = lastDay;
                    });
                    
                    anprController.loadStatistics(
                      from: _dateFrom,
                      to: _dateTo,
                    );
                    anprController.loadEvents(
                      from: _dateFrom,
                      to: _dateTo,
                    );
                    anprController.loadReports(
                      from: _dateFrom,
                      to: _dateTo,
                    );
                  },
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: const Text('Текущий месяц'),
                ),
                const SizedBox(width: AppPadding.small),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Обновить',
                  onPressed: () {
                    anprController.loadStatistics(
                      from: _dateFrom,
                      to: _dateTo,
                    );
                    anprController.loadEvents(
                      from: _dateFrom,
                      to: _dateTo,
                    );
                    anprController.loadReports(
                      from: _dateFrom,
                      to: _dateTo,
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppPadding.large),
          // Статистика
          anprState.statistics?.when(
            data: (stats) => _buildStatistics(stats),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(AppPadding.large),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stack) => _buildErrorState(error.toString()),
          ) ?? const SizedBox.shrink(),
          const SizedBox(height: AppPadding.large),
          // Отчеты по объему снега
          Text(
            'Отчеты по объему снега',
            style: AppTextStyles.title2,
          ),
          const SizedBox(height: AppPadding.normal),
          anprState.reports?.when(
            data: (reportData) => _buildReportsSummary(reportData),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(AppPadding.large),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stack) => _buildErrorState(error.toString()),
          ) ?? const SizedBox.shrink(),
          const SizedBox(height: AppPadding.large),
          // Последние события
          Text(
            'Последние события',
            style: AppTextStyles.title2,
          ),
          const SizedBox(height: AppPadding.normal),
          anprState.events?.when(
            data: (events) => _buildRecentEvents(events, anprController, anprState.reports?.valueOrNull),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(AppPadding.large),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stack) => _buildErrorState(error.toString()),
          ) ?? const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildStatistics(AnprStatistics stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Статистика',
          style: AppTextStyles.title2,
        ),
        const SizedBox(height: AppPadding.normal),
        Row(
          children: [
            Expanded(
              child: AnimatedKPICard(
                title: 'Всего событий',
                value: stats.totalEvents.toString(),
                icon: Icons.event,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: AppPadding.normal),
            Expanded(
              child: AnimatedKPICard(
                title: 'Уникальных номеров',
                value: stats.uniquePlates.toString(),
                icon: Icons.directions_car,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppPadding.normal),
        Row(
          children: [
            // Expanded(
            //   child: AnimatedKPICard(
            //     title: 'Въездов',
            //     value: stats.enterEvents.toString(),
            //     icon: Icons.arrow_downward,
            //     color: Colors.orange,
            //   ),
            // ),
            const SizedBox(width: AppPadding.normal),
            Expanded(
              child: AnimatedKPICard(
                title: 'Выездов',
                value: stats.exitEvents.toString(),
                icon: Icons.arrow_upward,
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentEvents(List<AnprEvent> events, AnprController controller, AnprReportData? reportsData) {
    if (events.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppPadding.large),
        decoration: BoxDecoration(
          color: AppColors.secondaryBackground,
          borderRadius: BorderRadius.circular(AppSize.smallRadius),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.event_busy,
                size: 48,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: AppPadding.normal),
              Text(
                'Нет событий за выбранный период',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final recentEvents = events.take(10).toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground,
        borderRadius: BorderRadius.circular(AppSize.smallRadius),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: recentEvents.length,
        itemBuilder: (context, index) {
          final event = recentEvents[index];
          return Container(
            margin: const EdgeInsets.only(bottom: AppPadding.small),
            padding: const EdgeInsets.all(AppPadding.normal),
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
                        event.normalizedPlate,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd.MM.yyyy HH:mm:ss').format(event.eventTime),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Показываем объем снега: confidence * body_volume_m3 или из отчетов
                Builder(
                  builder: (context) {
                    // Вычисляем объем снега: confidence * body_volume_m3
                    double? volume = event.calculatedSnowVolume;
                    
                    // Если вычисленный объем отсутствует, пытаемся найти в отчетах
                    if ((volume == null || volume == 0) && reportsData != null) {
                      try {
                        final reportEvent = reportsData.events.firstWhere(
                          (e) => e.plateNumber == event.normalizedPlate && 
                                 e.eventTime.difference(event.eventTime).inSeconds.abs() < 60,
                        );
                        volume = reportEvent.snowVolumeM3;
                      } catch (e) {
                        volume = null;
                      }
                    }
                    
                    // Если все еще нет объема, но есть готовый snow_volume_m3, используем его
                    if ((volume == null || volume == 0) && event.snowVolumeM3 != null && event.snowVolumeM3! > 0) {
                      volume = event.snowVolumeM3;
                    }
                    
                    if (volume != null && volume > 0) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppPadding.small,
                          vertical: AppPadding.xs,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.cyan.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppSize.smallRadius),
                        ),
                        child: Text(
                          '${volume.toStringAsFixed(1)} м³',
                          style: AppTextStyles.body.copyWith(
                            color: Colors.cyan,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildReportsSummary(AnprReportData reportData) {
    return Container(
      padding: const EdgeInsets.all(AppPadding.normal),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.cyan.withOpacity(0.15),
            Colors.cyan.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSize.smallRadius),
        border: Border.all(color: Colors.cyan.withOpacity(0.3), width: 0.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Всего поездок',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reportData.tripCount.toString(),
                      style: AppTextStyles.title2.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Общий объем снега',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${reportData.totalVolume.toStringAsFixed(1)} м³',
                      style: AppTextStyles.title2.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.cyan,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (reportData.events.isNotEmpty) ...[
            const SizedBox(height: AppPadding.normal),
            const Divider(),
            const SizedBox(height: AppPadding.normal),
            Text(
              'Последние поездки с объемом',
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppPadding.small),
            ...reportData.events.take(5).map((event) => Container(
                  margin: const EdgeInsets.only(bottom: AppPadding.small),
                  padding: const EdgeInsets.all(AppPadding.small),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(AppSize.smallRadius),
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
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('dd.MM.yyyy HH:mm').format(event.eventTime),
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
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
                            color: Colors.cyan.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppSize.smallRadius),
                          ),
                          child: Text(
                            '${event.snowVolumeM3!.toStringAsFixed(1)} м³',
                            style: AppTextStyles.body.copyWith(
                              color: Colors.cyan,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      padding: const EdgeInsets.all(AppPadding.large),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSize.smallRadius),
        border: Border.all(color: Colors.red.withOpacity(0.3), width: 0.5),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red,
          ),
          const SizedBox(height: AppPadding.normal),
          Text(
            'Ошибка загрузки данных ANPR',
            style: AppTextStyles.title2.copyWith(
              color: Colors.red,
            ),
          ),
          const SizedBox(height: AppPadding.small),
          Text(
            error,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}


