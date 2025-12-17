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

    // Загружаем данные при первой загрузке, но только если виджет виден
    // Используем Future.microtask для неблокирующей загрузки
    // Загружаем статистику только если её нет и не загружается
    final statsIsLoading = anprState.statistics?.isLoading ?? false;
    if (anprState.statistics == null && !statsIsLoading) {
      Future.microtask(() {
        anprController.loadStatistics(from: effectiveFrom, to: effectiveTo);
      });
    }
    
    // Загружаем отчеты только если их нет и не загружается
    // Согласно документации: отчеты показывают поездки и объем снега
    final reportsIsLoading = anprState.reports?.isLoading ?? false;
    if (anprState.reports == null && !reportsIsLoading) {
      Future.microtask(() {
        anprController.loadReports(
          from: effectiveFrom,
          to: effectiveTo,
          contractorId: contractorId,
          polygonId: polygonId,
          vehicleId: vehicleId,
          plate: plate,
          limit: 100, // Согласно документации: по умолчанию 100, макс 1000
        );
      });
    }
    
    // Загружаем события только если их нет и не загружается
    // Согласно документации: по умолчанию 50, максимум 100
    final eventsIsLoading = anprState.events?.isLoading ?? false;
    if (anprState.events == null && !eventsIsLoading) {
      Future.microtask(() {
        anprController.loadEvents(
          from: effectiveFrom, 
          to: effectiveTo,
          limit: 50, // Согласно документации: по умолчанию 50
        );
      });
    }

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
        // Показываем карточки событий вместо таблицы
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: AppPadding.normal,
            mainAxisSpacing: AppPadding.normal,
            childAspectRatio: 1.2,
          ),
          itemCount: events.take(12).length,
          itemBuilder: (context, index) {
            final event = events[index];
            return _buildEventCard(context, event, controller, reportsData);
          },
        ),
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
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withOpacity(0.1),
              AppColors.primary.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(AppSize.cardRadius),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: AppSize.shadowBlur,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  if (event.confidence != null)
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
              ),
              const SizedBox(height: AppPadding.normal),
              // Веб-оптимизированный виджет
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
                            // Контент
                            Padding(
                              padding: EdgeInsets.all(padding),
                              child: Row(
                                children: [
                                  // Левая часть - номер
                                  Expanded(
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
                                                color: AppColors.primary.withOpacity(0.1),
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
                                  // Разделитель
                                  Container(
                                    width: 1,
                                    height: isWeb ? 70 : 60,
                                    margin: EdgeInsets.symmetric(
                                      horizontal: isWeb ? 28 : 20,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          AppColors.primary.withOpacity(0.2),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Правая часть - объем
                                  if (volume != null && volume > 0) ...[
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'ОБЪЕМ СНЕГА',
                                          style: AppTextStyles.caption.copyWith(
                                            color: AppColors.textSecondary,
                                            fontSize: isWeb ? 11 : 10,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: isWeb ? 2.0 : 1.5,
                                          ),
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
                                                      Icons.ac_unit,
                                                      color: Colors.cyan.shade600,
                                                      size: iconSize,
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
                                  ] else ...[
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'ОБЪЕМ СНЕГА',
                                          style: AppTextStyles.caption.copyWith(
                                            color: AppColors.textSecondary,
                                            fontSize: isWeb ? 11 : 10,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: isWeb ? 2.0 : 1.5,
                                          ),
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
              const SizedBox(height: AppPadding.xs),
              Text(
                DateFormat('dd.MM.yyyy\nHH:mm:ss').format(event.eventTime),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventsTableOld(
    BuildContext context,
    List<AnprEvent> events,
    AnprController controller,
    AnprReportData? reportsData,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppSize.cardRadius),
          border: Border.all(color: AppColors.divider, width: 0.5),
        ),
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Время')),
            DataColumn(label: Text('Номер')),
            DataColumn(label: Text('Объем снега (м³)')),
            DataColumn(label: Text('Действия')),
          ],
          rows: events.take(50).map((event) {
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
                  Text(
                    DateFormat('dd.MM.yyyy HH:mm:ss').format(event.eventTime),
                    style: AppTextStyles.body,
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppPadding.small,
                      vertical: AppPadding.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSize.smallRadius),
                    ),
                    child: Text(
                      event.normalizedPlate,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    volume != null && volume > 0
                        ? '${volume.toStringAsFixed(2)} м³'
                        : '—',
                    style: AppTextStyles.body.copyWith(
                      color: volume != null && volume > 0 ? Colors.cyan : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.visibility, size: 20),
                    tooltip: 'Подробнее',
                    onPressed: () {
                      controller.loadEventById(event.id);
                      // Показываем диалог с деталями
                      _showEventDetails(context, event, controller);
                    },
                  ),
                ),  
              ],
            );
          }).toList(),
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
        // Карточки событий из отчета
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
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: AppPadding.normal,
              mainAxisSpacing: AppPadding.normal,
              childAspectRatio: 1.2,
            ),
            itemCount: reportData.events.length,
            itemBuilder: (context, index) {
              final event = reportData.events[index];
              return _buildReportEventCard(context, event, controller);
            },
          ),
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
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.cyan.withOpacity(0.15),
              Colors.cyan.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(AppSize.cardRadius),
          border: Border.all(
            color: Colors.cyan.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: AppSize.shadowBlur,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  if (event.contractorName != null)
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
              ),
              const SizedBox(height: AppPadding.normal),
              // Веб-оптимизированный виджет
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
                            // Контент
                            Padding(
                              padding: EdgeInsets.all(padding),
                              child: Row(
                                children: [
                                  // Левая часть - номер
                                  Expanded(
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
                                                color: Colors.cyan.withOpacity(0.15),
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
                                  // Разделитель
                                  Container(
                                    width: 1,
                                    height: isWeb ? 70 : 60,
                                    margin: EdgeInsets.symmetric(
                                      horizontal: isWeb ? 28 : 20,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.cyan.withOpacity(0.3),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Правая часть - объем
                                  if (event.snowVolumeM3 != null && event.snowVolumeM3! > 0) ...[
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'ОБЪЕМ СНЕГА',
                                          style: AppTextStyles.caption.copyWith(
                                            color: AppColors.textSecondary,
                                            fontSize: isWeb ? 11 : 10,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: isWeb ? 2.0 : 1.5,
                                          ),
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
                                                      Icons.ac_unit,
                                                      color: Colors.cyan.shade600,
                                                      size: iconSize,
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
                                  ] else ...[
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'ОБЪЕМ СНЕГА',
                                          style: AppTextStyles.caption.copyWith(
                                            color: AppColors.textSecondary,
                                            fontSize: isWeb ? 11 : 10,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: isWeb ? 2.0 : 1.5,
                                          ),
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
              const SizedBox(height: AppPadding.xs),
              if (event.vehicleBrand != null || event.vehicleModel != null)
                Text(
                  '${event.vehicleBrand ?? ''} ${event.vehicleModel ?? ''}'.trim(),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: AppPadding.xs),
              Text(
                DateFormat('dd.MM.yyyy\nHH:mm').format(event.eventTime),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppSize.cardRadius),
          border: Border.all(color: AppColors.divider, width: 0.5),
        ),
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Время')),
            DataColumn(label: Text('Номер')),
            DataColumn(label: Text('Транспорт')),
            DataColumn(label: Text('Подрядчик')),
            DataColumn(label: Text('Объем снега (м³)')),
            DataColumn(label: Text('Действия')),
          ],
          rows: reportData.events.map((event) {
            final volume = event.snowVolumeM3;
            
            return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          DateFormat('dd.MM.yyyy HH:mm:ss').format(event.eventTime),
                          style: AppTextStyles.body,
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppPadding.small,
                            vertical: AppPadding.xs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppSize.smallRadius),
                          ),
                          child: Text(
                            event.plateNumber,
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          event.vehicleBrand != null && event.vehicleModel != null
                              ? '${event.vehicleBrand} ${event.vehicleModel}'
                              : event.vehicleBrand ?? event.vehicleModel ?? '—',
                          style: AppTextStyles.body,
                        ),
                      ),
                      DataCell(
                        Text(
                          event.contractorName ?? '—',
                          style: AppTextStyles.body,
                        ),
                      ),
                      DataCell(
                        Text(
                          volume != null && volume > 0
                              ? '${volume.toStringAsFixed(2)} м³'
                              : '—',
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: volume != null && volume > 0 ? Colors.cyan : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.visibility, size: 20),
                          tooltip: 'Подробнее',
                          onPressed: () {
                            controller.loadEventById(event.id);
                            _showReportEventDetails(context, event, controller);
                          },
                        ),
                      ),
                    ],
                  );
                }).toList(),
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
