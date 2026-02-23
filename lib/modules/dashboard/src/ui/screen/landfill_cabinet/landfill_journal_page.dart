import 'package:akimat_project/core/locale/locale_provider.dart';
import 'package:akimat_project/core/platform/platform_utils.dart';
import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/core/ui/app_textstyle.dart';
import 'package:akimat_project/modules/dashboard/src/controller/landfill_journal_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class LandfillJournalPage extends ConsumerStatefulWidget {
  const LandfillJournalPage({
    super.key,
    required this.scaffoldKey,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;

  @override
  ConsumerState<LandfillJournalPage> createState() => _LandfillJournalPageState();
}

class _LandfillJournalPageState extends ConsumerState<LandfillJournalPage> {
  DateTime? _selectedDateFrom;
  DateTime? _selectedDateTo;
  String? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final config = PlatformConfig.instance;
    final state = ref.watch(landfillJournalControllerProvider);
    final controller = ref.read(landfillJournalControllerProvider.notifier);

    return Container(
      margin: EdgeInsets.all(config.padding),
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
                    Icons.book,
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
                        'Журнал приёма снега',
                        style: AppTextStyles.title1,
                      ),
                      const SizedBox(height: AppPadding.xs),
                      Text(
                        'Операционный журнал - всё, что заехало на полигоны',
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
          // Фильтры
          Container(
            padding: const EdgeInsets.all(AppPadding.normal),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(AppSize.cardRadius),
              border: Border.all(color: AppColors.divider, width: 0.5),
            ),
            child: Row(
              children: [
                // Фильтр по дате от
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDateFrom ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          _selectedDateFrom = date;
                        });
                        controller.setDateRange(_selectedDateFrom, _selectedDateTo);
                      }
                    },
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      _selectedDateFrom != null
                          ? DateFormat('dd.MM.yyyy').format(_selectedDateFrom!)
                          : 'Дата от',
                    ),
                  ),
                ),
                const SizedBox(width: AppPadding.small),
                // Фильтр по дате до
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDateTo ?? DateTime.now(),
                        firstDate: _selectedDateFrom ?? DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          _selectedDateTo = date;
                        });
                        controller.setDateRange(_selectedDateFrom, _selectedDateTo);
                      }
                    },
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      _selectedDateTo != null
                          ? DateFormat('dd.MM.yyyy').format(_selectedDateTo!)
                          : 'Дата до',
                    ),
                  ),
                ),
                const SizedBox(width: AppPadding.small),
                // Фильтр по статусу
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Статус',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppPadding.small,
                        vertical: AppPadding.xs,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Все статусы')),
                      DropdownMenuItem(value: 'OK', child: Text('OK')),
                      DropdownMenuItem(value: 'ROUTE_VIOLATION', child: Text('Нарушение маршрута')),
                      DropdownMenuItem(value: 'FOREIGN_AREA', child: Text('Чужой участок')),
                      DropdownMenuItem(value: 'MISMATCH_PLATE', child: Text('Несоответствие номера')),
                      DropdownMenuItem(value: 'OVER_CAPACITY', child: Text('Превышение объёма')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus = value;
                      });
                      controller.setStatusFilter(value);
                    },
                  ),
                ),
                const SizedBox(width: AppPadding.small),
                // Кнопка сброса фильтров
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _selectedDateFrom = null;
                      _selectedDateTo = null;
                      _selectedStatus = null;
                    });
                    controller.setDateRange(null, null);
                    controller.setStatusFilter(null);
                  },
                  tooltip: 'Сбросить фильтры',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppPadding.normal),
          // Таблица рейсов
          Expanded(
            child: state.data.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
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
              data: (data) {
                if (data.trips.isEmpty) {
                  return Center(
                    child: Text(
                      'Нет данных',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                }
                return Column(
                  children: [
                    // Статистика
                    Container(
                      padding: const EdgeInsets.all(AppPadding.normal),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppSize.smallRadius),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem('Всего рейсов', data.totalTrips.toString()),
                          _buildStatItem(
                            'Общий объём',
                            '${data.totalVolumeM3.toStringAsFixed(2)} м³',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppPadding.normal),
                    // Таблица
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Время въезда')),
                            DataColumn(label: Text('Время выезда')),
                            DataColumn(label: Text('Полигон')),
                            DataColumn(label: Text('Госномер')),
                            DataColumn(label: Text('Подрядчик')),
                            DataColumn(label: Text('Объём (м³)')),
                            DataColumn(label: Text('Статус')),
                          ],
                          rows: data.trips.map((trip) {
                            return DataRow(
                              cells: [
                                DataCell(Text(
                                  DateFormat('dd.MM.yyyy HH:mm').format(trip.entryAt),
                                )),
                                DataCell(Text(
                                  trip.exitAt != null
                                      ? DateFormat('dd.MM.yyyy HH:mm').format(trip.exitAt!)
                                      : '-',
                                )),
                                DataCell(Text(trip.polygonName)),
                                DataCell(Text(trip.vehiclePlateNumber)),
                                DataCell(Text(trip.contractorName)),
                                DataCell(Text(trip.netVolumeM3.toStringAsFixed(2))),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppPadding.small,
                                      vertical: AppPadding.xs,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(trip.status).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(AppSize.smallRadius),
                                    ),
                                    child: Text(
                                      trip.status,
                                      style: AppTextStyles.caption.copyWith(
                                        color: _getStatusColor(trip.status),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
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
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.title2.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppPadding.xs),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'OK':
        return Colors.green;
      case 'ROUTE_VIOLATION':
      case 'FOREIGN_AREA':
      case 'MISMATCH_PLATE':
      case 'OVER_CAPACITY':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
