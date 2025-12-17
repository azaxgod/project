import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/core/ui/app_textstyle.dart';
import 'package:akimat_project/modules/analytics/src/controller/analytics_providers.dart';
import 'package:akimat_project/modules/analytics/src/controller/anpr_controller.dart';
import 'package:akimat_project/modules/analytics/src/ui/widgets/animated_kpi_card.dart';
import 'package:akimat_project/modules/analytics/src/ui/widgets/animated_section.dart';
import 'package:akimat_project/services/anpr/model/anpr_event.dart';
import 'package:akimat_project/services/anpr/model/anpr_report.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Виджет для отображения секции ANPR данных
/// Согласно документации: период по умолчанию - последние 24 часа
class AnprSection extends ConsumerWidget {
  const AnprSection({
    super.key,
    this.dateFrom,
    this.dateTo,
    this.contractorId,
    this.polygonId,
    this.vehicleId,
    this.plate,
  });

  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? contractorId; // Фильтр по подрядчику (для админов)
  final String? polygonId; // Фильтр по полигону
  final String? vehicleId; // Фильтр по машине
  final String? plate; // Поиск по номеру

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final anprState = ref.watch(anprControllerProvider);
    final anprController = ref.read(anprControllerProvider.notifier);

    // Согласно документации: период по умолчанию - последние 24 часа
    final effectiveFrom = dateFrom ?? DateTime.now().subtract(const Duration(hours: 24));
    final effectiveTo = dateTo ?? DateTime.now();

    // Загружаем данные при первой загрузке
    // Используем addPostFrameCallback для гарантированной загрузки
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Загружаем статистику только если её нет и не загружается
      final statsIsLoading = anprState.statistics?.isLoading ?? false;
      if (anprState.statistics == null && !statsIsLoading) {
        anprController.loadStatistics(from: effectiveFrom, to: effectiveTo);
      }
      
      // Загружаем отчеты только если их нет и не загружается
      // Согласно документации: отчеты показывают поездки и объем снега
      final reportsIsLoading = anprState.reports?.isLoading ?? false;
      if (anprState.reports == null && !reportsIsLoading) {
        anprController.loadReports(
          from: effectiveFrom,
          to: effectiveTo,
          contractorId: contractorId,
          polygonId: polygonId,
          vehicleId: vehicleId,
          plate: plate,
          limit: 100, // Согласно документации: по умолчанию 100, макс 1000
        );
      }
      
      // Загружаем события только если их нет и не загружается
      // Согласно документации: по умолчанию 50, максимум 100
      final eventsIsLoading = anprState.events?.isLoading ?? false;
      if (anprState.events == null && !eventsIsLoading) {
        anprController.loadEvents(
          from: effectiveFrom, 
          to: effectiveTo,
          limit: 50, // Согласно документации: по умолчанию 50
        );
      }
    });

    // Получаем данные отчетов для использования в таблице событий
    final reportsData = anprState.reports?.valueOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Статистика ANPR
        AnimatedSection(
          title: 'ANPR - Распознавание номеров',
          icon: Icons.camera_alt,
          child: anprState.statistics?.when(
            data: (stats) => _buildStatistics(stats),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(AppPadding.large),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stack) => _buildErrorState(error.toString()),
          ) ?? const SizedBox.shrink(),
        ),
        const SizedBox(height: AppPadding.large),
        // Отчеты по объему снега и поездкам
        // Согласно документации: показывает total_volume, trip_count и список событий
        AnimatedSection(
          title: 'Отчеты по объему снега и поездкам',
          icon: Icons.assessment,
          child: anprState.reports?.when(
            data: (reportData) => _buildReportsSection(context, reportData, anprController),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(AppPadding.large),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stack) => _buildErrorState(error.toString()),
          ) ?? const SizedBox.shrink(),
        ),
        const SizedBox(height: AppPadding.large),
        // События ANPR
        AnimatedSection(
          title: 'События распознавания',
          icon: Icons.event,
          child: anprState.events?.when(
            data: (events) => _buildEventsTable(context, events, anprController, reportsData),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(AppPadding.large),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stack) => _buildErrorState(error.toString()),
          ) ?? const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildStatistics(AnprStatistics stats) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AnimatedKPICard(
                title: 'Всего событий',
                value: stats.totalEvents.toString(),
                icon: Icons.event,
                color: Colors.blue,
                onTap: () {
                  // Можно показать фильтрованные события
                },
              ),
            ),
            const SizedBox(width: AppPadding.normal),
            Expanded(
              child: AnimatedKPICard(
                title: 'Уникальных номеров',
                value: stats.uniquePlates.toString(),
                icon: Icons.directions_car,
                color: Colors.green,
                onTap: () {
                  // Можно показать список уникальных номеров
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppPadding.normal),
        Row(
          children: [
            Expanded(
              child: AnimatedKPICard(
                title: 'Въездов',
                value: stats.enterEvents.toString(),
                icon: Icons.arrow_downward,
                color: Colors.orange,
                onTap: () {
                  // Можно показать только события въезда
                },
              ),
            ),
            const SizedBox(width: AppPadding.normal),
            Expanded(
              child: AnimatedKPICard(
                title: 'Выездов',
                value: stats.exitEvents.toString(),
                icon: Icons.arrow_upward,
                color: Colors.purple,
                onTap: () {
                  // Можно показать только события выезда
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppPadding.normal),
        AnimatedKPICard(
          title: 'Средняя уверенность',
          value: '${(stats.avgConfidence * 100).toStringAsFixed(1)}%',
          icon: Icons.verified,
          color: stats.avgConfidence > 0.8 ? Colors.green : Colors.orange,
          onTap: () {
            // Можно показать статистику по уверенности
          },
        ),
      ],
    );
  }

  Widget _buildEventsTable(
    BuildContext context,
    List<AnprEvent> events,
    AnprController controller,
    AnprReportData? reportsData,
  ) {
    if (events.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppPadding.large),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppSize.cardRadius),
          border: Border.all(color: AppColors.divider, width: 0.5),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.event_busy,
                size: 64,
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

    // Вычисляем статистику по объему снега
    final snowVolumeStats = _calculateSnowVolumeStats(events, reportsData);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Виджет для отображения объема снега
        _buildSnowVolumeWidget(snowVolumeStats),
        const SizedBox(height: AppPadding.large),
        // Таблица событий
        _buildEventsDataTable(context, events, controller, reportsData),
      ],
    );
  }

  Map<String, dynamic> _calculateSnowVolumeStats(
    List<AnprEvent> events,
    AnprReportData? reportsData,
  ) {
    double totalVolume = 0.0;
    int eventsWithVolume = 0;
    double maxVolume = 0.0;
    double minVolume = double.infinity;

    for (final event in events) {
      double? volume = event.calculatedSnowVolume;
      
      if (volume == null && reportsData != null) {
        try {
          final reportEventById = reportsData.events.where(
            (e) => e.id == event.id,
          ).firstOrNull;
          
          if (reportEventById != null && reportEventById.snowVolumeM3 != null && reportEventById.snowVolumeM3! > 0) {
            volume = reportEventById.snowVolumeM3;
          } else {
            final reportEventByPlate = reportsData.events.where(
              (e) => e.plateNumber == event.normalizedPlate && 
                     e.eventTime.difference(event.eventTime).inSeconds.abs() < 60,
            ).firstOrNull;
            
            if (reportEventByPlate != null && reportEventByPlate.snowVolumeM3 != null && reportEventByPlate.snowVolumeM3! > 0) {
              volume = reportEventByPlate.snowVolumeM3;
            }
          }
        } catch (e) {
          // Не нашли в отчетах
        }
      }
      
      if (volume == null && event.snowVolumeM3 != null && event.snowVolumeM3! > 0) {
        volume = event.snowVolumeM3;
      }

      if (volume != null && volume > 0) {
        totalVolume += volume;
        eventsWithVolume++;
        if (volume > maxVolume) maxVolume = volume;
        if (volume < minVolume) minVolume = volume;
      }
    }

    final avgVolume = eventsWithVolume > 0 ? totalVolume / eventsWithVolume : 0.0;

    return {
      'totalVolume': totalVolume,
      'avgVolume': avgVolume,
      'maxVolume': maxVolume == double.infinity ? 0.0 : maxVolume,
      'minVolume': minVolume == double.infinity ? 0.0 : minVolume,
      'eventsWithVolume': eventsWithVolume,
      'totalEvents': events.length,
    };
  }

  /// Декоративный разделитель между секциями
  Widget _buildSectionDivider({bool isCyan = false}) {
    final color = isCyan ? Colors.cyan : AppColors.primary;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppPadding.large),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.transparent,
                    color.withOpacity(0.3),
                    color.withOpacity(0.5),
                    color.withOpacity(0.3),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Icon(
              isCyan ? Icons.assessment : Icons.event,
              color: color,
              size: 20,
            ),
          ),
          Expanded(
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.transparent,
                    color.withOpacity(0.3),
                    color.withOpacity(0.5),
                    color.withOpacity(0.3),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSnowVolumeWidget(Map<String, dynamic> stats) {
    final totalVolume = stats['totalVolume'] as double;
    final avgVolume = stats['avgVolume'] as double;
    final maxVolume = stats['maxVolume'] as double;
    final eventsWithVolume = stats['eventsWithVolume'] as int;
    final totalEvents = stats['totalEvents'] as int;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.cyan.withOpacity(0.2),
            Colors.blue.withOpacity(0.15),
            Colors.cyan.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSize.cardRadius),
        border: Border.all(
          color: Colors.cyan.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.cyan.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppPadding.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.cyan.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.snowing,
                  color: Colors.cyan,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppPadding.normal),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Объем снега',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${totalVolume.toStringAsFixed(2)} м³',
                      style: AppTextStyles.headline.copyWith(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.cyan.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (eventsWithVolume > 0) ...[
            const SizedBox(height: AppPadding.large),
            Container(
              padding: const EdgeInsets.all(AppPadding.normal),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(AppSize.smallRadius),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Средний объем',
                      '${avgVolume.toStringAsFixed(2)} м³',
                      Icons.trending_up,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.cyan.withOpacity(0.3),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Максимальный',
                      '${maxVolume.toStringAsFixed(2)} м³',
                      Icons.arrow_upward,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.cyan.withOpacity(0.3),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'С событий',
                      '$eventsWithVolume / $totalEvents',
                      Icons.event,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppPadding.small),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: Colors.cyan.shade700,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.cyan.shade700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(
    BuildContext context,
    AnprEvent event,
    AnprController controller,
    AnprReportData? reportsData,
  ) {
    // Вычисляем объем снега
    double? volume = event.calculatedSnowVolume;
    
    if (volume == null && reportsData != null) {
      try {
        final reportEventById = reportsData.events.where(
          (e) => e.id == event.id,
        ).firstOrNull;
        
        if (reportEventById != null && reportEventById.snowVolumeM3 != null && reportEventById.snowVolumeM3! > 0) {
          volume = reportEventById.snowVolumeM3;
        } else {
          final reportEventByPlate = reportsData.events.where(
            (e) => e.plateNumber == event.normalizedPlate && 
                   e.eventTime.difference(event.eventTime).inSeconds.abs() < 60,
          ).firstOrNull;
          
          if (reportEventByPlate != null && reportEventByPlate.snowVolumeM3 != null && reportEventByPlate.snowVolumeM3! > 0) {
            volume = reportEventByPlate.snowVolumeM3;
          }
        }
      } catch (e) {
        // Не нашли в отчетах
      }
    }
    
    if (volume == null && event.snowVolumeM3 != null && event.snowVolumeM3! > 0) {
      volume = event.snowVolumeM3;
    }

    final directionColor = event.direction == 'enter' ? Colors.green : Colors.orange;
    final directionIcon = event.direction == 'enter' ? Icons.arrow_downward : Icons.arrow_upward;

    return GestureDetector(
      onTap: () {
        controller.loadEventById(event.id);
        _showEventDetails(context, event, controller);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSize.cardRadius),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: AppColors.primary.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 3),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppPadding.normal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Верхняя строка с датой и иконками
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Красивое отображение даты вверху
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isWeb = kIsWeb;
                        final isWideScreen = constraints.maxWidth > 800;
                        
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isWeb ? (isWideScreen ? 12 : 10) : 8,
                            vertical: isWeb ? (isWideScreen ? 8 : 6) : 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.primary.withOpacity(0.08),
                                AppColors.primary.withOpacity(0.04),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.15),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: isWeb ? (isWideScreen ? 14 : 12) : 12,
                                color: AppColors.primary,
                              ),
                              SizedBox(width: isWeb ? 6 : 4),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      DateFormat('dd MMM yyyy', 'ru').format(event.eventTime),
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.primary,
                                        fontSize: isWeb ? (isWideScreen ? 11 : 10) : 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.3,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 1),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          size: isWeb ? (isWideScreen ? 10 : 9) : 9,
                                          color: AppColors.primary.withOpacity(0.7),
                                        ),
                                        SizedBox(width: 2),
                                        Text(
                                          DateFormat('HH:mm:ss').format(event.eventTime),
                                          style: AppTextStyles.caption.copyWith(
                                            color: AppColors.primary.withOpacity(0.8),
                                            fontSize: isWeb ? (isWideScreen ? 9 : 8) : 8,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Иконки справа
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: directionColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          directionIcon,
                          color: directionColor,
                          size: 20,
                        ),
                      ),
                      if (event.confidence != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: (event.confidence! > 0.8 ? Colors.green : Colors.orange).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${(event.confidence! * 100).toStringAsFixed(0)}%',
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.bold,
                              color: event.confidence! > 0.8 ? Colors.green.shade700 : Colors.orange.shade700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              // Горизонтальный разделитель
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(vertical: AppPadding.normal),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.transparent,
                      AppColors.primary.withOpacity(0.2),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
              // Веб-оптимизированный виджет с четким разделением
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWeb = kIsWeb;
                  final isWideScreen = constraints.maxWidth > 800;
                  final padding = isWeb 
                      ? (isWideScreen ? 32.0 : 24.0)
                      : 20.0;
                  final fontSize = isWeb 
                      ? (isWideScreen ? 28.0 : 24.0)
                      : 24.0;
                  final volumeFontSize = isWeb 
                      ? (isWideScreen ? 32.0 : 28.0)
                      : 28.0;
                  final iconSize = isWeb 
                      ? (isWideScreen ? 32.0 : 28.0)
                      : 28.0;
                  
                  return Material(
                    elevation: isWeb ? 2 : 0,
                    borderRadius: BorderRadius.circular(isWeb ? 28 : 24),
                    shadowColor: isWeb ? Colors.black.withOpacity(0.1) : Colors.transparent,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(isWeb ? 28 : 24),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(isWeb ? 0.2 : 0.15),
                          width: isWeb ? 2 : 1.5,
                        ),
                        boxShadow: isWeb ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                            spreadRadius: 0,
                          ),
                        ] : null,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(isWeb ? 28 : 24),
                        child: Stack(
                          children: [
                            // Декоративный фон
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.primary.withOpacity(isWeb ? 0.1 : 0.08),
                                      Colors.transparent,
                                      Colors.blue.withOpacity(isWeb ? 0.08 : 0.05),
                                    ],
                                    stops: const [0.0, 0.4, 1.0],
                                  ),
                                ),
                              ),
                            ),
                            // Контент с четким разделением
                            Padding(
                              padding: EdgeInsets.all(padding),
                              child: Row(
                                children: [
                                  // Левая часть - номер (обернута в контейнер для четкости)
                                  Expanded(
                                    child: Container(
                                      padding: EdgeInsets.all(isWeb ? 16 : 12),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: AppColors.primary.withOpacity(0.15),
                                          width: 1,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                width: isWeb ? 5 : 4,
                                                height: isWeb ? 24 : 20,
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topCenter,
                                                    end: Alignment.bottomCenter,
                                                    colors: [
                                                      AppColors.primary,
                                                      AppColors.primary.withOpacity(0.6),
                                                    ],
                                                  ),
                                                  borderRadius: BorderRadius.circular(2),
                                                ),
                                              ),
                                              SizedBox(width: isWeb ? 12 : 10),
                                              Text(
                                                'ГОС. НОМЕР',
                                                style: AppTextStyles.caption.copyWith(
                                                  color: AppColors.textSecondary,
                                                  fontSize: isWeb ? 11 : 10,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: isWeb ? 2.0 : 1.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: isWeb ? 16 : 12),
                                          Row(
                                            children: [
                                              Container(
                                                padding: EdgeInsets.all(isWeb ? 12 : 10),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary.withOpacity(0.15),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Icon(
                                                  Icons.confirmation_number_outlined,
                                                  color: AppColors.primary,
                                                  size: isWeb ? 24 : 20,
                                                ),
                                              ),
                                              SizedBox(width: isWeb ? 16 : 12),
                                              Expanded(
                                                child: Text(
                                                  event.normalizedPlate,
                                                  style: AppTextStyles.title2.copyWith(
                                                    fontWeight: FontWeight.w800,
                                                    color: AppColors.primary,
                                                    fontSize: fontSize,
                                                    letterSpacing: isWeb ? 2.5 : 2,
                                                    height: 1.2,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Визуальный разделитель
                                  Container(
                                    width: 2,
                                    height: isWeb ? 90 : 80,
                                    margin: EdgeInsets.symmetric(
                                      horizontal: isWeb ? 24 : 16,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          AppColors.primary.withOpacity(0.3),
                                          AppColors.primary.withOpacity(0.3),
                                          Colors.transparent,
                                        ],
                                        stops: const [0.0, 0.2, 0.8, 1.0],
                                      ),
                                      borderRadius: BorderRadius.circular(1),
                                    ),
                                  ),
                                  // Правая часть - объем (обернута в контейнер для четкости)
                                  if (volume != null && volume > 0) ...[
                                    Container(
                                      padding: EdgeInsets.all(isWeb ? 16 : 12),
                                      decoration: BoxDecoration(
                                        color: Colors.cyan.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.cyan.withOpacity(0.2),
                                          width: 1,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: isWeb ? 5 : 4,
                                                height: isWeb ? 24 : 20,
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topCenter,
                                                    end: Alignment.bottomCenter,
                                                    colors: [
                                                      Colors.cyan.shade600,
                                                      Colors.cyan.shade400,
                                                    ],
                                                  ),
                                                  borderRadius: BorderRadius.circular(2),
                                                ),
                                              ),
                                              SizedBox(width: isWeb ? 8 : 6),
                                              Text(
                                                'ОБЪЕМ СНЕГА',
                                                style: AppTextStyles.caption.copyWith(
                                                  color: AppColors.textSecondary,
                                                  fontSize: isWeb ? 11 : 10,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: isWeb ? 2.0 : 1.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: isWeb ? 16 : 12),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    crossAxisAlignment: CrossAxisAlignment.center,
                                                    children: [
                                                      Container(
                                                        padding: EdgeInsets.all(isWeb ? 8 : 6),
                                                        decoration: BoxDecoration(
                                                          color: Colors.cyan.shade100,
                                                          borderRadius: BorderRadius.circular(10),
                                                        ),
                                                        child: Icon(
                                                          Icons.ac_unit,
                                                          color: Colors.cyan.shade700,
                                                          size: isWeb ? 28 : 24,
                                                        ),
                                                      ),
                                                      SizedBox(width: isWeb ? 12 : 8),
                                                      Text(
                                                        '${volume.toStringAsFixed(1)}',
                                                        style: AppTextStyles.title2.copyWith(
                                                          fontWeight: FontWeight.w800,
                                                          color: Colors.cyan.shade700,
                                                          fontSize: volumeFontSize,
                                                          height: 1,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(height: isWeb ? 6 : 4),
                                                  Container(
                                                    padding: EdgeInsets.symmetric(
                                                      horizontal: isWeb ? 12 : 10,
                                                      vertical: isWeb ? 6 : 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.cyan.shade50,
                                                      borderRadius: BorderRadius.circular(8),
                                                      border: Border.all(
                                                        color: Colors.cyan.shade200,
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      'м³',
                                                      style: AppTextStyles.caption.copyWith(
                                                        color: Colors.cyan.shade700,
                                                        fontSize: isWeb ? 12 : 11,
                                                        fontWeight: FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ] else ...[
                                    Container(
                                      padding: EdgeInsets.all(isWeb ? 16 : 12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.grey.withOpacity(0.2),
                                          width: 1,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: isWeb ? 5 : 4,
                                                height: isWeb ? 24 : 20,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade400,
                                                  borderRadius: BorderRadius.circular(2),
                                                ),
                                              ),
                                              SizedBox(width: isWeb ? 8 : 6),
                                              Text(
                                                'ОБЪЕМ СНЕГА',
                                                style: AppTextStyles.caption.copyWith(
                                                  color: AppColors.textSecondary,
                                                  fontSize: isWeb ? 11 : 10,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: isWeb ? 2.0 : 1.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: isWeb ? 16 : 12),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    crossAxisAlignment: CrossAxisAlignment.center,
                                                    children: [
                                                      Icon(
                                                        Icons.ac_unit_outlined,
                                                        color: Colors.grey.shade400,
                                                        size: iconSize,
                                                      ),
                                                      SizedBox(width: isWeb ? 12 : 8),
                                                      Text(
                                                        '—',
                                                        style: AppTextStyles.title2.copyWith(
                                                          fontWeight: FontWeight.w800,
                                                          color: Colors.grey.shade500,
                                                          fontSize: volumeFontSize,
                                                          height: 1,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(height: isWeb ? 6 : 4),
                                                  Container(
                                                    padding: EdgeInsets.symmetric(
                                                      horizontal: isWeb ? 12 : 10,
                                                      vertical: isWeb ? 6 : 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey.shade100,
                                                      borderRadius: BorderRadius.circular(8),
                                                      border: Border.all(
                                                        color: Colors.grey.shade300,
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      'м³',
                                                      style: AppTextStyles.caption.copyWith(
                                                        color: Colors.grey.shade600,
                                                        fontSize: isWeb ? 12 : 11,
                                                        fontWeight: FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventsDataTable(
    BuildContext context,
    List<AnprEvent> events,
    AnprController controller,
    AnprReportData? reportsData,
  ) {
    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSize.cardRadius),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            AppColors.primary.withOpacity(0.08),
          ),
          headingRowHeight: 56,
          dataRowMinHeight: 64,
          dataRowMaxHeight: 80,
          columns: [
            DataColumn(
              label: Row(
                children: [
                  Icon(
                    Icons.numbers,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '#',
                    style: AppTextStyles.title3.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            DataColumn(
              label: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Время',
                    style: AppTextStyles.title3.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            DataColumn(
              label: Row(
                children: [
                  Icon(
                    Icons.confirmation_number,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Номер',
                    style: AppTextStyles.title3.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            DataColumn(
              label: Row(
                children: [
                  Icon(
                    Icons.ac_unit,
                    size: 18,
                    color: Colors.cyan.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Объем снега (м³)',
                    style: AppTextStyles.title3.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.cyan.shade700,
                    ),
                  ),
                ],
              ),
            ),
            DataColumn(
              label: Text(
                'Действия',
                style: AppTextStyles.title3.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
          rows: events.take(50).toList().asMap().entries.map((entry) {
            final index = entry.key;
            final event = entry.value;
            
            // Вычисляем объем снега: confidence * body_volume_m3 или используем готовый
            double? volume = event.calculatedSnowVolume;
            
            // Если calculatedSnowVolume вернул null, но есть confidence, пытаемся найти объем в отчетах
            if (volume == null && reportsData != null) {
              try {
                // Сначала ищем по ID события
                final reportEventById = reportsData.events.where(
                  (e) => e.id == event.id,
                ).firstOrNull;
                
                if (reportEventById != null && reportEventById.snowVolumeM3 != null && reportEventById.snowVolumeM3! > 0) {
                  volume = reportEventById.snowVolumeM3;
                } else {
                  // Если не нашли по ID, ищем по номеру и времени (в пределах 60 секунд)
                  final reportEventByPlate = reportsData.events.where(
                    (e) => e.plateNumber == event.normalizedPlate && 
                           e.eventTime.difference(event.eventTime).inSeconds.abs() < 60,
                  ).firstOrNull;
                  
                  if (reportEventByPlate != null && reportEventByPlate.snowVolumeM3 != null && reportEventByPlate.snowVolumeM3! > 0) {
                    volume = reportEventByPlate.snowVolumeM3;
                  }
                }
              } catch (e) {
                // Не нашли в отчетах
              }
            }
            
            // Если все еще нет объема, но есть готовый snow_volume_m3, используем его
            if (volume == null && event.snowVolumeM3 != null && event.snowVolumeM3! > 0) {
              volume = event.snowVolumeM3;
            }
            
            // Если есть confidence, но нет bodyVolumeM3 и нет объема в отчетах,
            // пытаемся вычислить хотя бы приблизительно (но это не рекомендуется)
            // Пока оставляем null, чтобы не показывать неверные данные
            
            return DataRow(
              cells: [
                DataCell(
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: AppTextStyles.title3.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              DateFormat('dd MMM yyyy', 'ru').format(event.eventTime),
                              style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('HH:mm:ss').format(event.eventTime),
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.grey.shade600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary.withOpacity(0.15),
                          AppColors.primary.withOpacity(0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.confirmation_number,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          event.normalizedPlate,
                          style: AppTextStyles.title3.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                DataCell(
                  volume != null && volume > 0
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.cyan.shade400,
                                Colors.cyan.shade600,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.cyan.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.ac_unit,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${volume.toStringAsFixed(1)} м³',
                                style: AppTextStyles.title3.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.ac_unit_outlined,
                                size: 18,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '—',
                                style: AppTextStyles.title3.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
                DataCell(
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.visibility,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      tooltip: 'Подробнее',
                      onPressed: () {
                        controller.loadEventById(event.id);
                        _showEventDetails(context, event, controller);
                      },
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildReportsSection(
    BuildContext context,
    AnprReportData reportData,
    AnprController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Статистика отчетов
        Row(
          children: [
            Expanded(
              child: AnimatedKPICard(
                title: 'Всего поездок',
                value: reportData.tripCount.toString(),
                icon: Icons.directions_car,
                color: Colors.blue,
                onTap: () {
                  // Можно показать детальную информацию о поездках
                },
              ),
            ),
            const SizedBox(width: AppPadding.normal),
            Expanded(
              child: AnimatedKPICard(
                title: 'Общий объем снега',
                value: '${reportData.totalVolume.toStringAsFixed(1)} м³',
                icon: Icons.snowing,
                color: Colors.cyan,
                onTap: () {
                  // Можно показать детальную информацию об объеме
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppPadding.large),
        // Таблица событий из отчета
        if (reportData.events.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppPadding.large),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(AppSize.cardRadius),
              border: Border.all(color: AppColors.divider, width: 0.5),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_busy,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: AppPadding.normal),
                  Text(
                    'Нет событий с объемом снега за выбранный период',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          _buildReportsTable(context, reportData, controller),
      ],
    );
  }

  Widget _buildReportEventCard(
    BuildContext context,
    AnprReportEvent event,
    AnprController controller,
  ) {
    final volume = event.snowVolumeM3;
    
    return GestureDetector(
      onTap: () {
        _showReportEventDetails(context, event, controller);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSize.cardRadius),
          border: Border.all(
            color: Colors.cyan.withOpacity(0.25),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.cyan.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 3),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppPadding.normal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Верхняя строка с датой и иконками
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Красивое отображение даты вверху
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isWeb = kIsWeb;
                        final isWideScreen = constraints.maxWidth > 800;
                        
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isWeb ? (isWideScreen ? 12 : 10) : 8,
                            vertical: isWeb ? (isWideScreen ? 8 : 6) : 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.cyan.withOpacity(0.1),
                                Colors.cyan.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.cyan.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: isWeb ? (isWideScreen ? 14 : 12) : 12,
                                color: Colors.cyan.shade700,
                              ),
                              SizedBox(width: isWeb ? 6 : 4),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      DateFormat('dd MMM yyyy', 'ru').format(event.eventTime),
                                      style: AppTextStyles.caption.copyWith(
                                        color: Colors.cyan.shade700,
                                        fontSize: isWeb ? (isWideScreen ? 11 : 10) : 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.3,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 1),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          size: isWeb ? (isWideScreen ? 10 : 9) : 9,
                                          color: Colors.cyan.shade600.withOpacity(0.7),
                                        ),
                                        SizedBox(width: 2),
                                        Text(
                                          DateFormat('HH:mm:ss').format(event.eventTime),
                                          style: AppTextStyles.caption.copyWith(
                                            color: Colors.cyan.shade600.withOpacity(0.8),
                                            fontSize: isWeb ? (isWideScreen ? 9 : 8) : 8,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Иконки справа
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.cyan.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.assessment,
                          color: Colors.cyan,
                          size: 20,
                        ),
                      ),
                      if (event.contractorName != null) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            event.contractorName!,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              // Горизонтальный разделитель
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(vertical: AppPadding.normal),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.transparent,
                      Colors.cyan.withOpacity(0.3),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
              // Веб-оптимизированный виджет с четким разделением
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWeb = kIsWeb;
                  final isWideScreen = constraints.maxWidth > 800;
                  final padding = isWeb 
                      ? (isWideScreen ? 32.0 : 24.0)
                      : 20.0;
                  final fontSize = isWeb 
                      ? (isWideScreen ? 28.0 : 24.0)
                      : 24.0;
                  final volumeFontSize = isWeb 
                      ? (isWideScreen ? 32.0 : 28.0)
                      : 28.0;
                  final iconSize = isWeb 
                      ? (isWideScreen ? 32.0 : 28.0)
                      : 28.0;
                  
                  return Material(
                    elevation: isWeb ? 2 : 0,
                    borderRadius: BorderRadius.circular(isWeb ? 28 : 24),
                    shadowColor: isWeb ? Colors.black.withOpacity(0.1) : Colors.transparent,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(isWeb ? 28 : 24),
                        border: Border.all(
                          color: Colors.cyan.withOpacity(isWeb ? 0.25 : 0.2),
                          width: isWeb ? 2 : 1.5,
                        ),
                        boxShadow: isWeb ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                            spreadRadius: 0,
                          ),
                        ] : null,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(isWeb ? 28 : 24),
                        child: Stack(
                          children: [
                            // Декоративный фон
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.cyan.withOpacity(isWeb ? 0.12 : 0.1),
                                      Colors.transparent,
                                      Colors.blue.withOpacity(isWeb ? 0.08 : 0.06),
                                    ],
                                    stops: const [0.0, 0.4, 1.0],
                                  ),
                                ),
                              ),
                            ),
                            // Контент с четким разделением
                            Padding(
                              padding: EdgeInsets.all(padding),
                              child: Row(
                                children: [
                                  // Левая часть - номер (обернута в контейнер для четкости)
                                  Expanded(
                                    child: Container(
                                      padding: EdgeInsets.all(isWeb ? 16 : 12),
                                      decoration: BoxDecoration(
                                        color: Colors.cyan.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.cyan.withOpacity(0.2),
                                          width: 1,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                width: isWeb ? 5 : 4,
                                                height: isWeb ? 24 : 20,
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topCenter,
                                                    end: Alignment.bottomCenter,
                                                    colors: [
                                                      Colors.cyan.shade600,
                                                      Colors.cyan.shade400,
                                                    ],
                                                  ),
                                                  borderRadius: BorderRadius.circular(2),
                                                ),
                                              ),
                                              SizedBox(width: isWeb ? 12 : 10),
                                              Text(
                                                'ГОС. НОМЕР',
                                                style: AppTextStyles.caption.copyWith(
                                                  color: AppColors.textSecondary,
                                                  fontSize: isWeb ? 11 : 10,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: isWeb ? 2.0 : 1.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: isWeb ? 16 : 12),
                                          Row(
                                            children: [
                                              Container(
                                                padding: EdgeInsets.all(isWeb ? 12 : 10),
                                                decoration: BoxDecoration(
                                                  color: Colors.cyan.withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Icon(
                                                  Icons.confirmation_number_outlined,
                                                  color: Colors.cyan.shade700,
                                                  size: isWeb ? 24 : 20,
                                                ),
                                              ),
                                              SizedBox(width: isWeb ? 16 : 12),
                                              Expanded(
                                                child: Text(
                                                  event.plateNumber,
                                                  style: AppTextStyles.title2.copyWith(
                                                    fontWeight: FontWeight.w800,
                                                    color: Colors.cyan.shade700,
                                                    fontSize: fontSize,
                                                    letterSpacing: isWeb ? 2.5 : 2,
                                                    height: 1.2,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Визуальный разделитель
                                  Container(
                                    width: 2,
                                    height: isWeb ? 90 : 80,
                                    margin: EdgeInsets.symmetric(
                                      horizontal: isWeb ? 24 : 16,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.cyan.withOpacity(0.4),
                                          Colors.cyan.withOpacity(0.4),
                                          Colors.transparent,
                                        ],
                                        stops: const [0.0, 0.2, 0.8, 1.0],
                                      ),
                                      borderRadius: BorderRadius.circular(1),
                                    ),
                                  ),
                                  // Правая часть - объем (обернута в контейнер для четкости)
                                  if (event.snowVolumeM3 != null && event.snowVolumeM3! > 0) ...[
                                    Container(
                                      padding: EdgeInsets.all(isWeb ? 16 : 12),
                                      decoration: BoxDecoration(
                                        color: Colors.cyan.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.cyan.withOpacity(0.2),
                                          width: 1,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: isWeb ? 5 : 4,
                                                height: isWeb ? 24 : 20,
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topCenter,
                                                    end: Alignment.bottomCenter,
                                                    colors: [
                                                      Colors.cyan.shade600,
                                                      Colors.cyan.shade400,
                                                    ],
                                                  ),
                                                  borderRadius: BorderRadius.circular(2),
                                                ),
                                              ),
                                              SizedBox(width: isWeb ? 8 : 6),
                                              Text(
                                                'ОБЪЕМ СНЕГА',
                                                style: AppTextStyles.caption.copyWith(
                                                  color: AppColors.textSecondary,
                                                  fontSize: isWeb ? 11 : 10,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: isWeb ? 2.0 : 1.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: isWeb ? 16 : 12),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    crossAxisAlignment: CrossAxisAlignment.center,
                                                    children: [
                                                      Container(
                                                        padding: EdgeInsets.all(isWeb ? 8 : 6),
                                                        decoration: BoxDecoration(
                                                          color: Colors.cyan.shade100,
                                                          borderRadius: BorderRadius.circular(10),
                                                        ),
                                                        child: Icon(
                                                          Icons.ac_unit,
                                                          color: Colors.cyan.shade700,
                                                          size: isWeb ? 28 : 24,
                                                        ),
                                                      ),
                                                      SizedBox(width: isWeb ? 12 : 8),
                                                      Text(
                                                        '${event.snowVolumeM3!.toStringAsFixed(1)}',
                                                        style: AppTextStyles.title2.copyWith(
                                                          fontWeight: FontWeight.w800,
                                                          color: Colors.cyan.shade700,
                                                          fontSize: volumeFontSize,
                                                          height: 1,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(height: isWeb ? 6 : 4),
                                                  Container(
                                                    padding: EdgeInsets.symmetric(
                                                      horizontal: isWeb ? 12 : 10,
                                                      vertical: isWeb ? 6 : 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.cyan.shade50,
                                                      borderRadius: BorderRadius.circular(8),
                                                      border: Border.all(
                                                        color: Colors.cyan.shade200,
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      'м³',
                                                      style: AppTextStyles.caption.copyWith(
                                                        color: Colors.cyan.shade700,
                                                        fontSize: isWeb ? 12 : 11,
                                                        fontWeight: FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ] else ...[
                                    Container(
                                      padding: EdgeInsets.all(isWeb ? 16 : 12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.grey.withOpacity(0.2),
                                          width: 1,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: isWeb ? 5 : 4,
                                                height: isWeb ? 24 : 20,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade400,
                                                  borderRadius: BorderRadius.circular(2),
                                                ),
                                              ),
                                              SizedBox(width: isWeb ? 8 : 6),
                                              Text(
                                                'ОБЪЕМ СНЕГА',
                                                style: AppTextStyles.caption.copyWith(
                                                  color: AppColors.textSecondary,
                                                  fontSize: isWeb ? 11 : 10,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: isWeb ? 2.0 : 1.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: isWeb ? 16 : 12),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    crossAxisAlignment: CrossAxisAlignment.center,
                                                    children: [
                                                      Icon(
                                                        Icons.ac_unit_outlined,
                                                        color: Colors.grey.shade400,
                                                        size: iconSize,
                                                      ),
                                                      SizedBox(width: isWeb ? 12 : 8),
                                                      Text(
                                                        '—',
                                                        style: AppTextStyles.title2.copyWith(
                                                          fontWeight: FontWeight.w800,
                                                          color: Colors.grey.shade500,
                                                          fontSize: volumeFontSize,
                                                          height: 1,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(height: isWeb ? 6 : 4),
                                                  Container(
                                                    padding: EdgeInsets.symmetric(
                                                      horizontal: isWeb ? 12 : 10,
                                                      vertical: isWeb ? 6 : 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey.shade100,
                                                      borderRadius: BorderRadius.circular(8),
                                                      border: Border.all(
                                                        color: Colors.grey.shade300,
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      'м³',
                                                      style: AppTextStyles.caption.copyWith(
                                                        color: Colors.grey.shade600,
                                                        fontSize: isWeb ? 12 : 11,
                                                        fontWeight: FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportsTable(
    BuildContext context,
    AnprReportData reportData,
    AnprController controller,
  ) {
    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSize.cardRadius),
            border: Border.all(
              color: Colors.cyan.withOpacity(0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              Colors.cyan.withOpacity(0.1),
            ),
            headingRowHeight: 56,
            dataRowMinHeight: 64,
            dataRowMaxHeight: 80,
            columns: [
              DataColumn(
                label: Row(
                  children: [
                    Icon(
                      Icons.numbers,
                      size: 18,
                      color: Colors.cyan.shade700,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '#',
                      style: AppTextStyles.title3.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.cyan.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              DataColumn(
                label: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 18,
                      color: Colors.cyan.shade700,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Время',
                      style: AppTextStyles.title3.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.cyan.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              DataColumn(
                label: Row(
                  children: [
                    Icon(
                      Icons.confirmation_number,
                      size: 18,
                      color: Colors.cyan.shade700,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Номер',
                      style: AppTextStyles.title3.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.cyan.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              DataColumn(
                label: Row(
                  children: [
                    Icon(
                      Icons.directions_car,
                      size: 18,
                      color: Colors.cyan.shade700,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Транспорт',
                      style: AppTextStyles.title3.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.cyan.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              DataColumn(
                label: Row(
                  children: [
                    Icon(
                      Icons.business,
                      size: 18,
                      color: Colors.cyan.shade700,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Подрядчик',
                      style: AppTextStyles.title3.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.cyan.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              DataColumn(
                label: Row(
                  children: [
                    Icon(
                      Icons.ac_unit,
                      size: 18,
                      color: Colors.cyan.shade700,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Объем снега (м³)',
                      style: AppTextStyles.title3.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.cyan.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              DataColumn(
                label: Text(
                  'Действия',
                  style: AppTextStyles.title3.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.cyan.shade700,
                  ),
                ),
              ),
            ],
          rows: reportData.events.asMap().entries.map((entry) {
            final index = entry.key;
            final event = entry.value;
            final volume = event.snowVolumeM3;
            
            return DataRow(
              cells: [
                DataCell(
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.cyan.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.cyan.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: AppTextStyles.title3.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.cyan.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              DateFormat('dd MMM yyyy', 'ru').format(event.eventTime),
                              style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('HH:mm:ss').format(event.eventTime),
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.grey.shade600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.cyan.withOpacity(0.15),
                          Colors.cyan.withOpacity(0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.cyan.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.cyan.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.confirmation_number,
                            size: 16,
                            color: Colors.cyan.shade700,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          event.plateNumber,
                          style: AppTextStyles.title3.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.cyan.shade700,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.blue.shade200,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      event.vehicleBrand != null && event.vehicleModel != null
                          ? '${event.vehicleBrand} ${event.vehicleModel}'
                          : event.vehicleBrand ?? event.vehicleModel ?? '—',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.purple.shade200,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      event.contractorName ?? '—',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.purple.shade700,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  volume != null && volume > 0
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.cyan.shade400,
                                Colors.cyan.shade600,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.cyan.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.ac_unit,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${volume.toStringAsFixed(1)} м³',
                                style: AppTextStyles.title3.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.ac_unit_outlined,
                                size: 18,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '—',
                                style: AppTextStyles.title3.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
                DataCell(
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.cyan.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.visibility,
                        size: 20,
                        color: Colors.cyan.shade700,
                      ),
                      tooltip: 'Подробнее',
                      onPressed: () {
                        _showReportEventDetails(context, event, controller);
                      },
                    ),
                  ),
                ),
                    ],
                  );
                }).toList(),
          ),
        ),
      ),
    );
  }

  void _showReportEventDetails(
    BuildContext context,
    AnprReportEvent event,
    AnprController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppSize.cardRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Красивый заголовок
              Container(
                padding: const EdgeInsets.all(AppPadding.large),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.cyan.withOpacity(0.2),
                      Colors.cyan.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppSize.cardRadius),
                    topRight: Radius.circular(AppSize.cardRadius),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.cyan.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.assessment,
                        color: Colors.cyan,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppPadding.normal),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Детали события отчета',
                            style: AppTextStyles.title1.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            event.plateNumber,
                            style: AppTextStyles.body.copyWith(
                              color: Colors.cyan.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppPadding.large),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildDetailRow('ID события', event.id),
                      _buildDetailRow('Номер', event.plateNumber),
                      _buildDetailRow('Исходный номер', event.rawPlate),
                      _buildDetailRow(
                        'Время',
                        DateFormat('dd.MM.yyyy HH:mm:ss').format(event.eventTime),
                      ),
                      if (event.vehicleBrand != null)
                        _buildDetailRow('Марка', event.vehicleBrand!),
                      if (event.vehicleModel != null)
                        _buildDetailRow('Модель', event.vehicleModel!),
                      if (event.contractorName != null) ...[
                        const SizedBox(height: AppPadding.normal),
                        Container(
                          padding: const EdgeInsets.all(AppPadding.normal),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryBackground,
                            borderRadius: BorderRadius.circular(AppSize.smallRadius),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.business,
                                size: 20,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildDetailRow('Подрядчик', event.contractorName!),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (event.snowVolumeM3 != null && event.snowVolumeM3! > 0) ...[
                        const SizedBox(height: AppPadding.normal),
                        Container(
                          padding: const EdgeInsets.all(AppPadding.normal),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.cyan.withOpacity(0.2),
                                Colors.cyan.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(AppSize.smallRadius),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.snowing,
                                size: 20,
                                color: Colors.cyan.shade700,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Объем снега: ${event.snowVolumeM3!.toStringAsFixed(2)} м³',
                                style: AppTextStyles.title2.copyWith(
                                  color: Colors.cyan.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (event.platePhotoUrl != null || event.bodyPhotoUrl != null) ...[
                        const SizedBox(height: AppPadding.large),
                        Container(
                          padding: const EdgeInsets.all(AppPadding.normal),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryBackground,
                            borderRadius: BorderRadius.circular(AppSize.smallRadius),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.photo_library,
                                    size: 20,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Фотографии',
                                    style: AppTextStyles.title2,
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppPadding.normal),
                              Wrap(
                                spacing: AppPadding.small,
                                runSpacing: AppPadding.small,
                                children: [
                                  if (event.platePhotoUrl != null)
                                    _buildPhotoCard('Фото номера', event.platePhotoUrl!),
                                  if (event.bodyPhotoUrl != null)
                                    _buildPhotoCard('Фото кузова', event.bodyPhotoUrl!),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoCard(String label, String url) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () {
            // Можно открыть в полноэкранном режиме
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              url,
              width: 120,
              height: 120,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 120,
                height: 120,
                color: AppColors.secondaryBackground,
                child: const Icon(Icons.error),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      padding: const EdgeInsets.all(AppPadding.large),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSize.cardRadius),
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

  void _showEventDetails(
    BuildContext context,
    AnprEvent event,
    AnprController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppSize.cardRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Красивый заголовок
              Container(
                padding: const EdgeInsets.all(AppPadding.large),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withOpacity(0.2),
                      AppColors.primary.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppSize.cardRadius),
                    topRight: Radius.circular(AppSize.cardRadius),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.event,
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
                            'Детали события ANPR',
                            style: AppTextStyles.title1.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            event.normalizedPlate,
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppPadding.large),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildDetailRow('ID события', event.id),
                      _buildDetailRow('Номер', event.normalizedPlate),
                      _buildDetailRow('Исходный номер', event.rawPlate),
                      _buildDetailRow('Камера', event.cameraId),
                      if (event.cameraModel != null)
                        _buildDetailRow('Модель камеры', event.cameraModel!),
                      _buildDetailRow(
                        'Время',
                        DateFormat('dd.MM.yyyy HH:mm:ss').format(event.eventTime),
                      ),
                      if (event.confidence != null)
                        _buildDetailRow(
                          'Уверенность',
                          '${(event.confidence! * 100).toStringAsFixed(1)}%',
                        ),
                      if (event.direction != null)
                        _buildDetailRow(
                          'Направление',
                          event.direction == 'enter' ? 'Въезд' : 'Выезд',
                        ),
                      if (event.lane != null)
                        _buildDetailRow('Полоса', event.lane.toString()),
                      if (event.vehicle != null) ...[
                        const SizedBox(height: AppPadding.normal),
                        Container(
                          padding: const EdgeInsets.all(AppPadding.normal),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryBackground,
                            borderRadius: BorderRadius.circular(AppSize.smallRadius),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.directions_car,
                                    size: 20,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Информация о ТС',
                                    style: AppTextStyles.title2,
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppPadding.small),
                              if (event.vehicle!.color != null)
                                _buildDetailRow('Цвет', event.vehicle!.color!),
                              if (event.vehicle!.type != null)
                                _buildDetailRow('Тип', event.vehicle!.type!),
                              if (event.vehicle!.brand != null)
                                _buildDetailRow('Марка', event.vehicle!.brand!),
                              if (event.vehicle!.model != null)
                                _buildDetailRow('Модель', event.vehicle!.model!),
                            ],
                          ),
                        ),
                      ],
                      if (event.bodyVolumeM3 != null) ...[
                        const SizedBox(height: AppPadding.normal),
                        Container(
                          padding: const EdgeInsets.all(AppPadding.normal),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.withOpacity(0.1),
                                Colors.blue.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(AppSize.smallRadius),
                          ),
                          child: _buildDetailRow(
                            'Объем кузова',
                            '${event.bodyVolumeM3!.toStringAsFixed(2)} м³',
                          ),
                        ),
                      ],
                      if (event.calculatedSnowVolume != null) ...[
                        const SizedBox(height: AppPadding.normal),
                        Container(
                          padding: const EdgeInsets.all(AppPadding.normal),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.cyan.withOpacity(0.2),
                                Colors.cyan.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(AppSize.smallRadius),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.snowing,
                                    size: 20,
                                    color: Colors.cyan.shade700,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Объем снега: ${event.calculatedSnowVolume!.toStringAsFixed(2)} м³',
                                    style: AppTextStyles.title2.copyWith(
                                      color: Colors.cyan.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              if (event.confidence != null && event.bodyVolumeM3 != null) ...[
                                const SizedBox(height: AppPadding.small),
                                Text(
                                  'Расчет: ${(event.confidence! * 100).toStringAsFixed(1)}% × ${event.bodyVolumeM3!.toStringAsFixed(2)} м³ = ${event.calculatedSnowVolume!.toStringAsFixed(2)} м³',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ] else if (event.snowVolumeM3 != null) ...[
                        const SizedBox(height: AppPadding.normal),
                        Container(
                          padding: const EdgeInsets.all(AppPadding.normal),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.cyan.withOpacity(0.2),
                                Colors.cyan.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(AppSize.smallRadius),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.snowing,
                                size: 20,
                                color: Colors.cyan.shade700,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Объем снега: ${event.snowVolumeM3!.toStringAsFixed(2)} м³',
                                style: AppTextStyles.title2.copyWith(
                                  color: Colors.cyan.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (event.photos.isNotEmpty) ...[
                        const SizedBox(height: AppPadding.large),
                        Container(
                          padding: const EdgeInsets.all(AppPadding.normal),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryBackground,
                            borderRadius: BorderRadius.circular(AppSize.smallRadius),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.photo_library,
                                    size: 20,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Фотографии',
                                    style: AppTextStyles.title2,
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppPadding.normal),
                              Wrap(
                                spacing: AppPadding.small,
                                runSpacing: AppPadding.small,
                                children: event.photos.map((photoUrl) {
                                  return GestureDetector(
                                    onTap: () {
                                      // Можно открыть в полноэкранном режиме
                                    },
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        photoUrl,
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          width: 100,
                                          height: 100,
                                          color: AppColors.secondaryBackground,
                                          child: const Icon(Icons.error),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppPadding.small),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.body,
            ),
          ),
        ],
      ),
    );
  }
}
