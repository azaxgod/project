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
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Виджет для отображения секции ANPR данных
class AnprSection extends ConsumerWidget {
  const AnprSection({
    super.key,
    this.dateFrom,
    this.dateTo,
  });

  final DateTime? dateFrom;
  final DateTime? dateTo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final anprState = ref.watch(anprControllerProvider);
    final anprController = ref.read(anprControllerProvider.notifier);

    // Загружаем данные при первой загрузке
    if (anprState.statistics == null && dateFrom != null && dateTo != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        anprController.loadStatistics(from: dateFrom, to: dateTo);
        anprController.loadEvents(from: dateFrom, to: dateTo);
        anprController.loadReports(from: dateFrom, to: dateTo);
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
        AnimatedSection(
          title: 'Отчеты по объему снега',
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
            Expanded(
              child: AnimatedKPICard(
                title: 'Въездов',
                value: stats.enterEvents.toString(),
                icon: Icons.arrow_downward,
                color: Colors.orange,
              ),
            ),
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
        const SizedBox(height: AppPadding.normal),
        AnimatedKPICard(
          title: 'Средняя уверенность',
          value: '${(stats.avgConfidence * 100).toStringAsFixed(1)}%',
          icon: Icons.verified,
          color: stats.avgConfidence > 0.8 ? Colors.green : Colors.orange,
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
            
            // Если вычисленный объем отсутствует, пытаемся найти из отчетов
            if (volume == null && reportsData != null) {
              try {
                final reportEvent = reportsData.events.firstWhere(
                  (e) => e.id == event.id,
                );
                volume = reportEvent.snowVolumeM3;
              } catch (e) {
                volume = null;
              }
            }
            
            // Если все еще нет объема, но есть готовый snow_volume_m3, используем его
            if (volume == null && event.snowVolumeM3 != null && event.snowVolumeM3! > 0) {
              volume = event.snowVolumeM3;
            }
            
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
              ),
            ),
            const SizedBox(width: AppPadding.normal),
            Expanded(
              child: AnimatedKPICard(
                title: 'Общий объем снега',
                value: '${reportData.totalVolume.toStringAsFixed(1)} м³',
                icon: Icons.snowing,
                color: Colors.cyan,
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
          SingleChildScrollView(
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
                          event.snowVolumeM3 != null
                              ? '${event.snowVolumeM3!.toStringAsFixed(2)} м³'
                              : '—',
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.cyan,
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
          ),
      ],
    );
  }

  void _showReportEventDetails(
    BuildContext context,
    AnprReportEvent event,
    AnprController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Детали события'),
        content: SingleChildScrollView(
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
              if (event.contractorName != null)
                _buildDetailRow('Подрядчик', event.contractorName!),
              if (event.snowVolumeM3 != null)
                _buildDetailRow(
                  'Объем снега',
                  '${event.snowVolumeM3!.toStringAsFixed(2)} м³',
                ),
              if (event.platePhotoUrl != null) ...[
                const SizedBox(height: AppPadding.normal),
                Text(
                  'Фото номера:',
                  style: AppTextStyles.title2,
                ),
                const SizedBox(height: AppPadding.small),
                Image.network(
                  event.platePhotoUrl!,
                  errorBuilder: (context, error, stackTrace) => Text(
                    'Ошибка загрузки изображения',
                    style: AppTextStyles.caption,
                  ),
                ),
              ],
              if (event.bodyPhotoUrl != null) ...[
                const SizedBox(height: AppPadding.normal),
                Text(
                  'Фото кузова:',
                  style: AppTextStyles.title2,
                ),
                const SizedBox(height: AppPadding.small),
                Image.network(
                  event.bodyPhotoUrl!,
                  errorBuilder: (context, error, stackTrace) => Text(
                    'Ошибка загрузки изображения',
                    style: AppTextStyles.caption,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
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
      builder: (context) => AlertDialog(
        title: const Text('Детали события ANPR'),
        content: SingleChildScrollView(
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
                Text(
                  'Информация о ТС:',
                  style: AppTextStyles.title2,
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
              if (event.bodyVolumeM3 != null)
                _buildDetailRow(
                  'Объем кузова',
                  '${event.bodyVolumeM3!.toStringAsFixed(2)} м³',
                ),
              if (event.calculatedSnowVolume != null) ...[
                _buildDetailRow(
                  'Объем снега',
                  '${event.calculatedSnowVolume!.toStringAsFixed(2)} м³',
                ),
                if (event.confidence != null && event.bodyVolumeM3 != null)
                  _buildDetailRow(
                    'Расчет',
                    '${(event.confidence! * 100).toStringAsFixed(1)}% × ${event.bodyVolumeM3!.toStringAsFixed(2)} м³ = ${event.calculatedSnowVolume!.toStringAsFixed(2)} м³',
                  ),
              ] else if (event.snowVolumeM3 != null)
                _buildDetailRow(
                  'Объем снега',
                  '${event.snowVolumeM3!.toStringAsFixed(2)} м³',
                ),
              if (event.photos.isNotEmpty) ...[
                const SizedBox(height: AppPadding.normal),
                Text(
                  'Фотографии:',
                  style: AppTextStyles.title2,
                ),
                const SizedBox(height: AppPadding.small),
                ...event.photos.map((photoUrl) => Padding(
                      padding: const EdgeInsets.only(bottom: AppPadding.small),
                      child: Image.network(
                        photoUrl,
                        errorBuilder: (context, error, stackTrace) => Text(
                          'Ошибка загрузки изображения',
                          style: AppTextStyles.caption,
                        ),
                      ),
                    )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
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
