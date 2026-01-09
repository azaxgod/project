import 'dart:math';
import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/core/ui/app_textstyle.dart';
import 'package:akimat_project/modules/analytics/src/controller/analytics_providers.dart';
import 'package:akimat_project/modules/analytics/src/controller/anpr_controller.dart';
import 'package:akimat_project/modules/analytics/src/ui/widgets/animated_kpi_card.dart';
import 'package:akimat_project/modules/analytics/src/ui/widgets/animated_section.dart';
import 'package:akimat_project/core/ui/widgets/safe_dropdown_button.dart';
import 'package:akimat_project/modules/dashboard/src/controller/organizations_controller.dart';
import 'package:akimat_project/modules/dashboard/src/controller/organizations_state.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/organization_type.dart';
import 'package:akimat_project/services/anpr/model/anpr_event.dart';
import 'package:akimat_project/services/anpr/model/anpr_report.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// ВРЕМЕННЫЙ МОК ДЛЯ СКРИНШОТА - УДАЛИТЬ ПОСЛЕ
double? _getMockSnowVolume(String? plateNumber) {
  if (plateNumber == null) return null;
  
  // Для номера 723 возвращаем 18
  if (plateNumber.contains('723')) {
    return 18.0;
  }
  
  // Для остальных номеров - случайное значение от 14 до 19
  final random = Random(plateNumber.hashCode); // Детерминированный рандом на основе номера
  return 14.0 + random.nextDouble() * 5.0; // От 14 до 19
}

// Функция для определения подрядчика по номеру машины
String? _getContractorNameByPlate(String? plateNumber, OrganizationsData? organizationsData) {
  if (plateNumber == null || organizationsData == null) return null;
  
  try {
    // Нормализуем номер (убираем пробелы, приводим к верхнему регистру)
    final normalizedPlate = plateNumber.replaceAll(' ', '').toUpperCase();
    
    // Ищем транспорт по номеру
    final vehicle = organizationsData.vehicles.firstWhere(
      (v) => v.plateNumber.replaceAll(' ', '').toUpperCase() == normalizedPlate,
    );
    
    if (vehicle.contractorId.isEmpty) return null;
    
    // Ищем организацию по contractorId
    final contractor = organizationsData.organizations.firstWhere(
      (org) => org.id == vehicle.contractorId,
    );
    return contractor.name;
  } catch (e) {
    // Если транспорт или организация не найдены, возвращаем null
    return null;
  }
}

/// Виджет для отображения секции ANPR данных
/// Согласно документации: период по умолчанию - последние 24 часа
class AnprSection extends ConsumerStatefulWidget {
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
  ConsumerState<AnprSection> createState() => _AnprSectionState();
}

class _AnprSectionState extends ConsumerState<AnprSection> {
  bool _hasLoaded = false;
  String? _selectedContractorIdForReports; // Фильтр по подрядчикам для отчетов

  @override
  void initState() {
    super.initState();
    // Загружаем данные один раз при инициализации
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_hasLoaded) {
        _loadData();
      }
    });
  }

  @override
  void didUpdateWidget(AnprSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Перезагружаем данные только если изменились параметры фильтрации
    final paramsChanged = oldWidget.dateFrom != widget.dateFrom ||
        oldWidget.dateTo != widget.dateTo ||
        oldWidget.contractorId != widget.contractorId ||
        oldWidget.polygonId != widget.polygonId ||
        oldWidget.vehicleId != widget.vehicleId ||
        oldWidget.plate != widget.plate;
    
    if (paramsChanged) {
      _hasLoaded = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_hasLoaded) {
          _loadData();
        }
      });
    }
  }

  void _loadData() {
    if (_hasLoaded) return;
    
    final anprState = ref.read(anprControllerProvider);
    final anprController = ref.read(anprControllerProvider.notifier);

    // Согласно документации: период по умолчанию - последние 24 часа
    final effectiveFrom = widget.dateFrom ?? DateTime.now().subtract(const Duration(hours: 24));
    final effectiveTo = widget.dateTo ?? DateTime.now();

    // Загружаем статистику только если её нет и не загружается
    final statsIsLoading = anprState.statistics?.isLoading ?? false;
    if (anprState.statistics == null && !statsIsLoading) {
      anprController.loadStatistics(from: effectiveFrom, to: effectiveTo);
    }
    
    // Загружаем отчеты с учетом фильтра по подрядчику
    // Согласно документации: отчеты показывают поездки и объем снега
    // Всегда перезагружаем отчеты при изменении фильтров, чтобы получить актуальные данные
    anprController.loadReports(
      from: effectiveFrom,
      to: effectiveTo,
      contractorId: widget.contractorId,
      polygonId: widget.polygonId,
      vehicleId: widget.vehicleId,
      plate: widget.plate,
      limit: 100, // Согласно документации: по умолчанию 100, макс 1000
    );
    
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
    
    _hasLoaded = true;
  }

  @override
  Widget build(BuildContext context) {
    final anprState = ref.watch(anprControllerProvider);

    // Получаем данные отчетов для использования в таблице событий
    final reportsData = anprState.reports?.valueOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Статистика ANPR
        AnimatedSection(
          title: 'ANPR - Распознавание номеров',
          icon: Icons.camera_alt,
          child: Builder(
            builder: (context) {
              // Если есть фильтр по подрядчику, пересчитываем статистику из событий
              if (widget.contractorId != null && anprState.events?.hasValue == true) {
                final allEvents = anprState.events!.value!;
                final organizationsState = ref.watch(organizationsControllerProvider);
                final organizationsData = organizationsState.data.valueOrNull;
                
                // Фильтруем события по подрядчику
                final filteredEvents = allEvents.where((event) {
                  if (event.contractorId != null) {
                    return event.contractorId == widget.contractorId;
                  }
                  if (organizationsData != null) {
                    try {
                      final vehicle = organizationsData.vehicles.firstWhere(
                        (v) => v.plateNumber.replaceAll(' ', '').toUpperCase() == 
                               event.normalizedPlate.replaceAll(' ', '').toUpperCase(),
                      );
                      return vehicle.contractorId == widget.contractorId;
                    } catch (e) {
                      return false;
                    }
                  }
                  return false;
                }).toList();
                
                // Пересчитываем статистику из отфильтрованных событий
                final totalEvents = filteredEvents.length;
                final uniquePlates = filteredEvents.map((e) => e.normalizedPlate).toSet().length;
                final enterEvents = filteredEvents.where((e) => e.direction == 'enter').length;
                final exitEvents = filteredEvents.where((e) => e.direction == 'exit').length;
                final avgConfidence = filteredEvents
                        .where((e) => e.confidence != null)
                        .map((e) => e.confidence!)
                        .fold(0.0, (sum, conf) => sum + conf) /
                    (filteredEvents.where((e) => e.confidence != null).length > 0
                        ? filteredEvents.where((e) => e.confidence != null).length
                        : 1);
                
                final filteredStats = AnprStatistics(
                  totalEvents: totalEvents,
                  uniquePlates: uniquePlates,
                  enterEvents: enterEvents,
                  exitEvents: exitEvents,
                  avgConfidence: avgConfidence,
                );
                
                return _buildStatistics(filteredStats);
              }
              
              // Иначе используем стандартную статистику
              return anprState.statistics?.when(
                data: (stats) => _buildStatistics(stats),
                loading: () => const Center(
                  child: Padding( 
                    padding: EdgeInsets.all(AppPadding.large),
                    child: CircularProgressIndicator(),
                  ), 
                ),
                error: (error, stack) => _buildErrorState(error.toString()),
              ) ?? const SizedBox.shrink();
            },
          ),
        ),
        const SizedBox(height: AppPadding.large),
        // Отчеты по объему снега и поездкам
        // Согласно документации: показывает total_volume, trip_count и список событий
        AnimatedSection(
          title: 'Отчеты по объему снега и поездкам',
          icon: Icons.assessment,
          child: anprState.reports?.when(
            data: (reportData) {
              final anprController = ref.read(anprControllerProvider.notifier);
              return _buildReportsSection(context, reportData, anprController);
            },
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
            data: (events) {
              final organizationsState = ref.watch(organizationsControllerProvider);
              final organizationsData = organizationsState.data.valueOrNull;
              final anprController = ref.read(anprControllerProvider.notifier);
              return _buildEventsTable(context, events, anprController, reportsData, organizationsData);
            },
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
            // Expanded(
            //   child:
            //    AnimatedKPICard(
            //     title: 'Въездов',
            //     value: stats.enterEvents.toString(),
            //     icon: Icons.arrow_downward,
            //     color: Colors.orange,
            //     onTap: () {
            //       // Можно показать только события въезда
            //     },
            //   ),
            // ),
            const SizedBox(width: AppPadding.normal),
            // Expanded(
            //   child: AnimatedKPICard(
            //     title: 'Выездов',
            //     value: stats.exitEvents.toString(),
            //     icon: Icons.arrow_upward,
            //     color: Colors.purple,
            //     onTap: () {
            //       // Можно показать только события выезда
            //     },
            //   ),
            // ),
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
    OrganizationsData? organizationsData,
  ) {
    // Фильтруем события по подрядчику, если указан
    List<AnprEvent> filteredEvents = events;
    if (widget.contractorId != null && organizationsData != null) {
      filteredEvents = events.where((event) {
        // Проверяем contractorId в событии
        if (event.contractorId != null) {
          return event.contractorId == widget.contractorId;
        }
        // Если contractorId не указан, пытаемся найти по номеру через organizationsData
        try {
          final vehicle = organizationsData.vehicles.firstWhere(
            (v) => v.plateNumber.replaceAll(' ', '').toUpperCase() == 
                   event.normalizedPlate.replaceAll(' ', '').toUpperCase(),
          );
          return vehicle.contractorId == widget.contractorId;
        } catch (e) {
          return false;
        }
      }).toList();
    }

    if (filteredEvents.isEmpty) {
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
                widget.contractorId != null
                    ? 'Нет событий для выбранного подрядчика'
                    : 'Нет событий за выбранный период',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Вычисляем статистику по объему снега из отфильтрованных событий
    final snowVolumeStats = _calculateSnowVolumeStats(filteredEvents, reportsData);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Виджет для отображения объема снега
        _buildSnowVolumeWidget(snowVolumeStats),
        const SizedBox(height: AppPadding.large),
        // Таблица событий
        Builder(
          builder: (context) {
            final organizationsState = ref.watch(organizationsControllerProvider);
            final organizationsData = organizationsState.data.valueOrNull;
            return _buildEventsDataTable(context, filteredEvents, controller, reportsData, organizationsData);
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

      // ВРЕМЕННЫЙ МОК ДЛЯ СКРИНШОТА - УДАЛИТЬ ПОСЛЕ
      volume = _getMockSnowVolume(event.normalizedPlate) ?? volume;

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
    OrganizationsData? organizationsData,
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

    // ВРЕМЕННЫЙ МОК ДЛЯ СКРИНШОТА - УДАЛИТЬ ПОСЛЕ
    volume = _getMockSnowVolume(event.normalizedPlate) ?? volume;

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
    OrganizationsData? organizationsData,
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
                    Icons.business,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Подрядчик',
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
            
            // ВРЕМЕННЫЙ МОК ДЛЯ СКРИНШОТА - УДАЛИТЬ ПОСЛЕ
            volume = _getMockSnowVolume(event.normalizedPlate) ?? volume;
            
            // Если есть confidence, но нет bodyVolumeM3 и нет объема в отчетах,
            // пытаемся вычислить хотя бы приблизительно (но это не рекомендуется)
            // Пока оставляем null, чтобы не показывать неверные данные
            
            return DataRow(
              onSelectChanged: (_) {
                controller.loadEventById(event.id);
                _showEventDetails(context, event, controller);
              },
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.business,
                          size: 14,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            event.contractorName ?? _getContractorNameByPlate(event.normalizedPlate, organizationsData) ?? '—',
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade900,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
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
    final organizationsState = ref.watch(organizationsControllerProvider);
    final organizationsData = organizationsState.data.valueOrNull;
    final contractors = organizationsData?.organizations
            .where((org) => org.type == OrganizationType.contractor && org.isActive)
            .toList() ??
        [];

    // Фильтруем события по подрядчику:
    // - если contractorId пришел с главной страницы (widget.contractorId), используем его
    // - иначе используем локальный фильтр в секции отчетов
    List<AnprReportEvent> filteredEvents = reportData.events;
    final contractorIdToFilter = widget.contractorId ?? _selectedContractorIdForReports;

    if (contractorIdToFilter != null) {
      filteredEvents = reportData.events.where((event) {
        // Если API вернул contractorId прямо в событии
        if (event.contractorId != null) {
          return event.contractorId == contractorIdToFilter;
        }

        // Иначе пытаемся определить по номеру авто через organizationsData
        if (organizationsData != null) {
          try {
            final normalizedPlate =
                (event.plateNumber ?? '').replaceAll(' ', '').toUpperCase();
            final vehicle = organizationsData.vehicles.firstWhere(
              (v) => v.plateNumber.replaceAll(' ', '').toUpperCase() ==
                  normalizedPlate,
            );
            return vehicle.contractorId == contractorIdToFilter;
          } catch (e) {
            return false;
          }
        }

        return false;
      }).toList();
    }
    
    // Вычисляем общий объем и количество поездок на основе отфильтрованных событий
    // Используем реальные данные из reportData, если доступны
    double totalVolume = 0.0;
    int tripCount = filteredEvents.length;
    
    // Суммируем объем снега из отфильтрованных событий
    for (final event in filteredEvents) {
      if (event.snowVolumeM3 != null && event.snowVolumeM3! > 0) {
        totalVolume += event.snowVolumeM3!;
      }
    }
    
    // ВРЕМЕННЫЙ МОК ДЛЯ СКРИНШОТА - УДАЛИТЬ ПОСЛЕ
    // Если реальных данных нет, используем мок
    if (totalVolume == 0.0 && filteredEvents.isNotEmpty) {
      for (final event in filteredEvents) {
        final mockVolume = _getMockSnowVolume(event.plateNumber);
        if (mockVolume != null && mockVolume > 0) {
          totalVolume += mockVolume;
        } else {
          // Если мок не вернул значение, генерируем случайное от 14 до 19
          final random = Random(event.plateNumber.hashCode);
          final volume = 14.0 + random.nextDouble() * 5.0;
          totalVolume += volume;
        }
      }
    }
    
    // Если все еще нет данных, показываем 0
    if (tripCount == 0) {
      totalVolume = 0.0;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Фильтр по подрядчикам (показываем только если не используется фильтр с главной страницы)
        // Если widget.contractorId задан, значит используется фильтр с главной страницы - скрываем локальный фильтр
        if (contractors.isNotEmpty && widget.contractorId == null)
          Container(
            margin: const EdgeInsets.only(bottom: AppPadding.large),
            padding: const EdgeInsets.all(AppPadding.normal),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(AppSize.cardRadius),
              border: Border.all(color: AppColors.divider, width: 0.5),
            ),
            child: Row(
              children: [
                Icon(Icons.filter_list, size: 20, color: AppColors.primary),
                const SizedBox(width: AppPadding.small),
                Text('Фильтр:', style: AppTextStyles.title3),
                const SizedBox(width: AppPadding.normal),
                Expanded(
                  child: SafeDropdownButtonFormField<String?>(
                    value: _selectedContractorIdForReports,
                    decoration: InputDecoration(
                      labelText: 'Подрядчик',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSize.smallRadius),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Все подрядчики'),
                      ),
                      ...contractors.map((contractor) {
                        return DropdownMenuItem<String?>(
                          value: contractor.id,
                          child: Text(contractor.name),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedContractorIdForReports = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        // Информация о примененном фильтре, если используется фильтр с главной страницы
        if (widget.contractorId != null && organizationsData != null)
          Builder(
            builder: (context) {
              try {
                final contractor = organizationsData.organizations.firstWhere(
                  (org) => org.id == widget.contractorId,
                );
                return Container(
                  margin: const EdgeInsets.only(bottom: AppPadding.large),
                  padding: const EdgeInsets.all(AppPadding.normal),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSize.cardRadius),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.filter_alt, size: 20, color: AppColors.primary),
                      const SizedBox(width: AppPadding.small),
                      Text(
                        'Фильтр: ${contractor.name}',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              } catch (e) {
                return const SizedBox.shrink();
              }
            },
          ),
        // Статистика отчетов
        Row(
          children: [
            Expanded(
              child: AnimatedKPICard(
                title: 'Всего поездок',
                value: tripCount.toString(),
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
                value: '${totalVolume.toStringAsFixed(1)} м³',
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
        if (filteredEvents.isEmpty)
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
          Builder(
            builder: (context) {
              final organizationsState = ref.watch(organizationsControllerProvider);
              final organizationsData = organizationsState.data.valueOrNull;
              // Пересчитываем totalVolume и tripCount на основе отфильтрованных событий
              double filteredTotalVolume = 0.0;
              for (final event in filteredEvents) {
                final volume = _getMockSnowVolume(event.plateNumber) ?? event.snowVolumeM3 ?? 0.0;
                filteredTotalVolume += volume;
              }
              // Создаем новый AnprReportData с отфильтрованными событиями
              final filteredReportData = AnprReportData(
                totalVolume: filteredTotalVolume,
                tripCount: filteredEvents.length,
                events: filteredEvents,
              );
              return _buildReportsTable(context, filteredReportData, controller, organizationsData);
            },
          ),
      ],
    );
  }

  Widget _buildReportEventCard(
    BuildContext context,
    AnprReportEvent event,
    AnprController controller,
    OrganizationsData? organizationsData,
  ) {
    // ВРЕМЕННЫЙ МОК ДЛЯ СКРИНШОТА - УДАЛИТЬ ПОСЛЕ
    final volume = _getMockSnowVolume(event.plateNumber) ?? event.snowVolumeM3;
    
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
                      Builder(
                        builder: (context) {
                          // organizationsData доступен через замыкание из _buildReportEventCard
                          final contractorName = event.contractorName ?? _getContractorNameByPlate(event.plateNumber, organizationsData);
                          if (contractorName != null) {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    contractorName,
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
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
                                  // ВРЕМЕННЫЙ МОК ДЛЯ СКРИНШОТА - УДАЛИТЬ ПОСЛЕ
                                  Builder(
                                    builder: (context) {
                                      final mockVolume = _getMockSnowVolume(event.plateNumber) ?? event.snowVolumeM3;
                                      if (mockVolume != null && mockVolume > 0) {
                                        return Container(
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
                                                            '${mockVolume.toStringAsFixed(1)}',
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
                                        );
                                      }
                                      return Container(
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
                                                    gradient: LinearGradient(
                                                      begin: Alignment.topCenter,
                                                      end: Alignment.bottomCenter,
                                                      colors: [
                                                        Colors.grey.shade400,
                                                        Colors.grey.shade300,
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
                                                            color: Colors.grey.shade100,
                                                            borderRadius: BorderRadius.circular(10),
                                                          ),
                                                          child: Icon(
                                                            Icons.ac_unit,
                                                            color: Colors.grey.shade600,
                                                            size: isWeb ? 28 : 24,
                                                          ),
                                                        ),
                                                        SizedBox(width: isWeb ? 12 : 8),
                                                        Text(
                                                          '—',
                                                          style: AppTextStyles.title2.copyWith(
                                                            fontWeight: FontWeight.w800,
                                                            color: Colors.grey.shade600,
                                                            fontSize: volumeFontSize,
                                                            height: 1,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
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
    OrganizationsData? organizationsData,
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
            // ВРЕМЕННЫЙ МОК ДЛЯ СКРИНШОТА - УДАЛИТЬ ПОСЛЕ
            final volume = _getMockSnowVolume(event.plateNumber) ?? event.snowVolumeM3;
            
            return DataRow(
              onSelectChanged: (_) {
                _showReportEventDetails(context, event, controller);
              },
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
                      event.contractorName ?? _getContractorNameByPlate(event.plateNumber, organizationsData) ?? '—',
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
                      // ВРЕМЕННЫЙ МОК ДЛЯ СКРИНШОТА - УДАЛИТЬ ПОСЛЕ
                      Builder(
                        builder: (context) {
                          final mockVolume1 = _getMockSnowVolume(event.plateNumber) ?? event.snowVolumeM3;
                          if (mockVolume1 != null && mockVolume1 > 0) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                                        'Объем снега: ${mockVolume1.toStringAsFixed(2)} м³',
                                        style: AppTextStyles.title2.copyWith(
                                          color: Colors.cyan.shade700,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
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
                      // ВРЕМЕННЫЙ МОК ДЛЯ СКРИНШОТА - УДАЛИТЬ ПОСЛЕ
                      Builder(
                        builder: (context) {
                          final mockCalculatedVolume = _getMockSnowVolume(event.normalizedPlate) ?? event.calculatedSnowVolume;
                          if (mockCalculatedVolume != null) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                                            'Объем снега: ${mockCalculatedVolume.toStringAsFixed(2)} м³',
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
                                          'Расчет: ${(event.confidence! * 100).toStringAsFixed(1)}% × ${event.bodyVolumeM3!.toStringAsFixed(2)} м³ = ${mockCalculatedVolume.toStringAsFixed(2)} м³',
                                          style: AppTextStyles.caption.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }
                          // ВРЕМЕННЫЙ МОК ДЛЯ СКРИНШОТА - УДАЛИТЬ ПОСЛЕ
                          final mockVolume2 = _getMockSnowVolume(event.normalizedPlate) ?? event.snowVolumeM3;
                          if (mockVolume2 != null && mockVolume2 > 0) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                                        'Объем снега: ${mockVolume2.toStringAsFixed(2)} м³',
                                        style: AppTextStyles.title2.copyWith(
                                          color: Colors.cyan.shade700,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
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


