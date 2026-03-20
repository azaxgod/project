import 'package:akimat_project/core/locale/locale_provider.dart';
import 'package:akimat_project/modules/dashboard/src/model/trip.dart';
import 'package:akimat_project/core/navbar/drawer_mobile.dart';
import 'package:akimat_project/core/navbar/navbar_widgets_provider.dart';
import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/core/ui/app_textstyle.dart';
import 'package:akimat_project/l10n/l10n.dart';
import 'package:akimat_project/modules/dashboard/src/controller/dashboard_controller.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/akimat_dashboard/widgets/kpi_card.dart';

import 'package:akimat_project/modules/dashboard/src/ui/screen/akimat_dashboard/widgets/trip_table_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:akimat_project/core/platform/platform_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:akimat_project/services/anpr/module.dart';
import 'package:fl_chart/fl_chart.dart';

class AkimatHome extends ConsumerStatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final List<Widget>? webNavbarWidgets;
  final List<Widget>? mobileNavbarWidgets;

  const AkimatHome({
    super.key,
    required this.scaffoldKey,
    this.webNavbarWidgets,
    this.mobileNavbarWidgets,
  });

  @override
  _AkimatHomeState createState() => _AkimatHomeState();
}

enum _SnowChartRange {
  week,
  month,
}

class _SnowVolumePoint {
  final DateTime day;
  final double volumeM3;

  const _SnowVolumePoint({
    required this.day,
    required this.volumeM3,
  });
}

class _AkimatHomeState extends ConsumerState<AkimatHome> {

  _SnowChartRange _snowChartRange = _SnowChartRange.week;
  Future<List<_SnowVolumePoint>>? _snowVolumeFuture;

  @override
  void initState() {
    super.initState();
    _snowVolumeFuture = _loadSnowVolumeSeries();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch locale to ensure rebuild when language changes
    ref.watch(localeProvider);
    final s = S.of(context)!;
    final config = PlatformConfig.instance;

    final state = ref.watch(akimatHomeControllerProvider);

    return Scaffold(
      key: widget.scaffoldKey,
      drawer: !kIsWeb ? const DrawerMobile() : null,
      appBar: kIsWeb
          ? null
          : AppBar(
              title: Text(s.main),
              leading: Builder(
                builder: (context) {
                  return IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  );
                },
              ),
              actions: NavbarWidgetsProvider.combineMobileWidgets(
                context,
                widget.mobileNavbarWidgets,
              ),
            ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (kIsWeb) const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.read(akimatHomeControllerProvider.notifier).refreshData();
                setState(() {
                  _snowVolumeFuture = _loadSnowVolumeSeries();
                });
              },
              child: SingleChildScrollView(
                padding: EdgeInsets.all(config.padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (config.topOffset > 0)
                      SizedBox(height: config.topOffset),
                    
                    // Заголовок панели
                    Container(
                      padding: const EdgeInsets.all(AppPadding.large),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(AppSize.cardRadius),
                        border: Border.all(
                          color: AppColors.divider,
                          width: 0.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: AppSize.shadowBlur,
                            offset: const Offset(0, 2),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppPadding.normal),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
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
                                  s.main_panel,
                                  style: AppTextStyles.title1,
                                ),
                                const SizedBox(height: AppPadding.xs),
                                Text(
                                  'SnowOps Control System',
                                  style: AppTextStyles.footnote,
                                ),
                              ],
                            ),
                          ),
                          if (state.isLoading)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppPadding.normal),

                    // Важная информация
                    _buildImportantInfoSection(state, ref),

                    const SizedBox(height: AppPadding.large),

                    // ---------------- KPI карточки ----------------
                    // if (state.error != null)
                    //   _buildErrorWidget(state.error!, ref)
                    // else ...[
                    //   SizedBox(
                    //     height: 140,
                    //     child: ListView.builder(
                    //       scrollDirection: Axis.horizontal,
                    //       itemCount: state.kpiCards.length,
                    //       itemBuilder: (context, index) {
                    //         final kpi = state.kpiCards[index];
                    //         return KpiCardWidget(
                    //           data: kpi,
                    //           onTap: kpi.clickable
                    //               ? () {
                    //                   // Обработка кликов на KPI карточки
                    //                   if (kpi.title.contains('участки')) {
                    //                     context.go('/areas');
                    //                   } else if (kpi.title.contains('тикеты')) {
                    //                     context.go('/tickets');
                    //                   } else if (kpi.title.contains('Нарушения')) {
                    //                     context.go('/violations');
                    //                   }
                    //                 }
                    //               : null,
                    //         );
                    //       },
                    //     ),
                    //   ),
                    //   const SizedBox(height: 16),


                      // ---------------- Последние рейсы ----------------
                      Container(
                        padding: const EdgeInsets.all(AppPadding.large),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(AppSize.cardRadius),
                          border: Border.all(
                            color: AppColors.divider,
                            width: 0.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: AppSize.shadowBlur,
                              offset: const Offset(0, 2),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Заголовок с статистикой
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(AppPadding.small),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(AppSize.smallRadius),
                                  ),
                                  child: Icon(
                                    Icons.directions_car,
                                    color: AppColors.primary,
                                    size: AppSize.iconSize,
                                  ),
                                ),
                                const SizedBox(width: AppPadding.normal),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        s.last_trips,
                                        style: AppTextStyles.title2,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Последние операции подрядчиков',
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              ],
                            ),
                            
                            // Статистическая информация о рейсах
                            if (state.lastTrips.isNotEmpty) ...[
                              const SizedBox(height: AppPadding.normal),
                              Container(
                                padding: const EdgeInsets.all(AppPadding.normal),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(AppSize.smallRadius),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _buildTripStatsItem(
                                        icon: Icons.business,
                                        label: 'Подрядчики',
                                        value: '${state.lastTrips.map((t) => t.contractor).toSet().length}',
                                        color: Colors.blue,
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildTripStatsItem(
                                        icon: Icons.local_shipping,
                                        label: 'Объем',
                                        value: '${state.lastTrips.fold<double>(0, (sum, t) => sum + t.volume).toStringAsFixed(1)} м³',
                                        color: Colors.green,
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildTripStatsItem(
                                        icon: Icons.check_circle,
                                        label: 'Выполнено',
                                        value: '${state.lastTrips.where((t) => t.status == 'MEASURED').length}',
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            
                            const SizedBox(height: AppPadding.normal),
                            if (state.lastTrips.isNotEmpty)
                              Column(
                                children: [
                                  // Таблица рейсов
                                  TripTableWidget(
                                    trips: state.lastTrips
                                        .map((t) => TripData(
                                              date: t.date,
                                              time: t.time,
                                              contractor: t.contractor,
                                              plate: t.plate,
                                              area: t.area,
                                              polygon: t.polygon,
                                              volume: t.volume,
                                              status: t.status,
                                            ))
                                        .toList(),
                                  ),
                                  
                                  // Дополнительная информация о подрядчиках
                                  const SizedBox(height: AppPadding.normal),
                                  Container(
                                    padding: const EdgeInsets.all(AppPadding.normal),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(AppSize.smallRadius),
                                      border: Border.all(
                                        color: Colors.green.withValues(alpha: 0.2),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          size: 16,
                                          color: Colors.green,
                                        ),
                                        const SizedBox(width: AppPadding.xs),
                                        Expanded(
                                          child: Text(
                                            'Активные подрядчики: ${_getActiveContractors(state.lastTrips)} • Общий объем: ${state.lastTrips.fold<double>(0, (sum, t) => sum + t.volume).toStringAsFixed(1)} м³',
                                            style: AppTextStyles.caption.copyWith(
                                              color: Colors.green.withValues(alpha: 0.8),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            else
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.inbox_outlined,
                                        size: 64,
                                        color: AppColors.textSecondary.withValues(alpha: 0.3),
                                      ),
                                      const SizedBox(height: AppPadding.normal),
                                      Text(
                                        state.isLoading ? 'Загрузка...' : 'Нет данных о рейсах',
                                        style: AppTextStyles.body.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      if (!state.isLoading) ...[
                                        const SizedBox(height: AppPadding.small),
                                        Text(
                                          'Рейсы подрядчиков появятся здесь после начала работы',
                                          style: AppTextStyles.caption.copyWith(
                                            color: AppColors.textSecondary.withValues(alpha: 0.7),
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
                      _buildLastUpdatedInfo(state),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<List<_SnowVolumePoint>> _loadSnowVolumeSeries() async {
    final anprCollection = ref.read(anprCollectionProvider);
    final now = DateTime.now();

    DateTime from;
    if (_snowChartRange == _SnowChartRange.week) {
      final today = DateTime(now.year, now.month, now.day);
      from = today.subtract(const Duration(days: 6));
    } else {
      from = DateTime(now.year, now.month, 1);
    }

    final reports = await anprCollection.getReports(
      from: from,
      to: now,
      minVolume: 0.01,
      limit: 1000,
      offset: 0,
    );

    final events = reports.data.events;
    final Map<DateTime, double> volumeByDay = {};
    for (final e in events) {
      final t = e.eventTime.toLocal();
      final bucket = DateTime(t.year, t.month, t.day);
      final v = e.snowVolumeM3 ?? 0.0;
      volumeByDay[bucket] = (volumeByDay[bucket] ?? 0.0) + v;
    }

    final startDay = DateTime(from.year, from.month, from.day);
    final endDay = DateTime(now.year, now.month, now.day);

    final List<_SnowVolumePoint> points = [];
    for (DateTime d = startDay; !d.isAfter(endDay); d = d.add(const Duration(days: 1))) {
      points.add(_SnowVolumePoint(
        day: d,
        volumeM3: volumeByDay[d] ?? 0.0,
      ));
    }

    return points;
  }

  Widget _buildSnowVolumeChart() {
    final future = _snowVolumeFuture;
    if (future == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(AppPadding.normal),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSize.smallRadius),
        border: Border.all(
          color: AppColors.divider,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Объем снега по дням',
                  style: AppTextStyles.title3,
                ),
              ),
              ToggleButtons(
                isSelected: [
                  _snowChartRange == _SnowChartRange.week,
                  _snowChartRange == _SnowChartRange.month,
                ],
                onPressed: (index) {
                  final range = index == 0 ? _SnowChartRange.week : _SnowChartRange.month;
                  if (range == _snowChartRange) return;
                  setState(() {
                    _snowChartRange = range;
                    _snowVolumeFuture = _loadSnowVolumeSeries();
                  });
                },
                constraints: const BoxConstraints(minHeight: 32, minWidth: 72),
                children: const [
                  Text('Неделя'),
                  Text('Месяц'),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppPadding.normal),
          SizedBox(
            height: 200,
            child: FutureBuilder<List<_SnowVolumePoint>>(
              future: future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Ошибка загрузки графика',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                    ),
                  );
                }

                final data = snapshot.data ?? const [];
                if (data.isEmpty) {
                  return Center(
                    child: Text(
                      'Нет данных',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                    ),
                  );
                }

                final maxY = data.map((e) => e.volumeM3).fold<double>(0, (a, b) => a > b ? a : b);
                final safeMaxY = maxY <= 0 ? 10.0 : (maxY * 1.35).ceilToDouble();

                return BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: safeMaxY,
                    barTouchData: BarTouchData(enabled: true),
                    titlesData: FlTitlesData(
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 44,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toStringAsFixed(0),
                              style: AppTextStyles.caption,
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          interval: data.length > 10 ? (data.length / 5).ceil().toDouble() : 1,
                          getTitlesWidget: (value, meta) {
                            final i = value.toInt();
                            if (i < 0 || i >= data.length) return const SizedBox.shrink();
                            final d = data[i].day;
                            final label = '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(label, style: AppTextStyles.caption),
                            );
                          },
                        ),
                      ),
                    ),
                    gridData: FlGridData(show: true, drawVerticalLine: false),
                    borderData: FlBorderData(show: true, border: Border.all(color: AppColors.divider, width: 1)),
                    barGroups: data.asMap().entries.map((e) {
                      return BarChartGroupData(
                        x: e.key,
                        barRods: [
                          BarChartRodData(
                            toY: e.value.volumeM3,
                            width: 10,
                            color: AppColors.primary,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppPadding.large),
          // Cumulative volume line chart
          Text(
            'Накопительный объем',
            style: AppTextStyles.title3,
          ),
          const SizedBox(height: AppPadding.normal),
          SizedBox(
            height: 200,
            child: FutureBuilder<List<_SnowVolumePoint>>(
              future: future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }

                final data = snapshot.data ?? const [];
                if (data.isEmpty) {
                  return const SizedBox.shrink();
                }

                // Build cumulative series
                double cumulative = 0;
                final spots = <FlSpot>[];
                for (int i = 0; i < data.length; i++) {
                  cumulative += data[i].volumeM3;
                  spots.add(FlSpot(i.toDouble(), cumulative));
                }
                final cumMaxY = cumulative <= 0 ? 10.0 : (cumulative * 1.2).ceilToDouble();

                return LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: cumMaxY,
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        curveSmoothness: 0.3,
                        color: Colors.teal,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, bar, index) {
                            return FlDotCirclePainter(
                              radius: 3,
                              color: Colors.teal,
                              strokeWidth: 1.5,
                              strokeColor: Colors.white,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.teal.withValues(alpha: 0.12),
                        ),
                      ),
                    ],
                    titlesData: FlTitlesData(
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 44,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toStringAsFixed(0),
                              style: AppTextStyles.caption,
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          interval: data.length > 10 ? (data.length / 5).ceil().toDouble() : 1,
                          getTitlesWidget: (value, meta) {
                            final i = value.toInt();
                            if (i < 0 || i >= data.length) return const SizedBox.shrink();
                            final d = data[i].day;
                            final label = '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(label, style: AppTextStyles.caption),
                            );
                          },
                        ),
                      ),
                    ),
                    gridData: FlGridData(show: true, drawVerticalLine: false),
                    borderData: FlBorderData(show: true, border: Border.all(color: AppColors.divider, width: 1)),
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            return LineTooltipItem(
                              '${spot.y.toStringAsFixed(1)} м³',
                              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            );
                          }).toList();
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectSummary(AkimatHomeState state) {
    final hasError = state.error != null;
    final statusText = state.isLoading
        ? 'Загрузка данных'
        : (hasError ? 'Ошибка загрузки данных' : 'Данные актуальны');

    final statusColor = state.isLoading
        ? Colors.orange
        : (hasError ? Colors.red : Colors.green);

    return Container(
      padding: const EdgeInsets.all(AppPadding.large),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSize.cardRadius),
        border: Border.all(
          color: AppColors.divider,
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: AppSize.shadowBlur,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppPadding.small),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSize.smallRadius),
                ),
                child: Icon(
                  hasError
                      ? Icons.error_outline
                      : (state.isLoading ? Icons.sync : Icons.verified_outlined),
                  color: statusColor,
                  size: AppSize.iconSize,
                ),
              ),
              const SizedBox(width: AppPadding.normal),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Сводка по системе',
                      style: AppTextStyles.title2,
                    ),
                    const SizedBox(height: AppPadding.xs),
                    Text(
                      statusText,
                      style: AppTextStyles.caption.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppPadding.normal),
          Row(
            children: [
              Expanded(
                child: _buildSummaryTile(
                  title: 'Участки',
                  value: state.polygons.length.toString(),
                  icon: Icons.place_outlined,
                ),
              ),
              const SizedBox(width: AppPadding.small),
              Expanded(
                child: _buildSummaryTile(
                  title: 'Последние рейсы',
                  value: state.lastTrips.length.toString(),
                  icon: Icons.directions_car_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppPadding.small),
          Row(
            children: [
              Expanded(
                child: _buildSummaryTile(
                  title: 'KPI карточки',
                  value: state.kpiCards.length.toString(),
                  icon: Icons.dashboard_outlined,
                ),
              ),
              const SizedBox(width: AppPadding.small),
              Expanded(
                child: _buildSummaryTile(
                  title: kIsWeb ? 'Платформа' : 'Платформа',
                  value: kIsWeb ? 'WEB' : 'MOBILE',
                  icon: kIsWeb ? Icons.web : Icons.phone_android,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTile({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppPadding.normal),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSize.smallRadius),
        border: Border.all(
          color: AppColors.divider,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: AppPadding.small),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppPadding.large),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSize.cardRadius),
        border: Border.all(
          color: AppColors.divider,
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: AppSize.shadowBlur,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppPadding.small),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSize.smallRadius),
                ),
                child: Icon(
                  Icons.flash_on,
                  color: AppColors.primary,
                  size: AppSize.iconSize,
                ),
              ),
              const SizedBox(width: AppPadding.normal),
              Text(
                'Быстрые действия',
                style: AppTextStyles.title2,
              ),
            ],
          ),
          const SizedBox(height: AppPadding.normal),
          Wrap(
            spacing: AppPadding.small,
            runSpacing: AppPadding.small,
            children: [
              OutlinedButton.icon(
                onPressed: () => context.go('/monitoring'),
                icon: const Icon(Icons.map, size: 18),
                label: const Text('Мониторинг'),
              ),
              OutlinedButton.icon(
                onPressed: () => context.go('/tickets'),
                icon: const Icon(Icons.confirmation_number_outlined, size: 18),
                label: const Text('Тикеты'),
              ),
              OutlinedButton.icon(
                onPressed: () => context.go('/violations'),
                icon: const Icon(Icons.gavel_outlined, size: 18),
                label: const Text('Нарушения'),
              ),
              OutlinedButton.icon(
                onPressed: () => context.go('/analytics'),
                icon: const Icon(Icons.analytics_outlined, size: 18),
                label: const Text('Аналитика'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLastUpdatedInfo(AkimatHomeState state) {
    final lastUpdated = state.lastUpdated;
    if (lastUpdated == null) {
      return const SizedBox.shrink();
    }

    final value =
        '${lastUpdated.day.toString().padLeft(2, '0')}.${lastUpdated.month.toString().padLeft(2, '0')}.${lastUpdated.year} '
        '${lastUpdated.hour.toString().padLeft(2, '0')}:${lastUpdated.minute.toString().padLeft(2, '0')}';

    return Row(
      children: [
        Icon(
          Icons.update,
          size: 16,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: AppPadding.small),
        Text(
          'Обновлено: ',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildImportantInfoSection(AkimatHomeState state, WidgetRef ref) {
    final now = DateTime.now();
    final isWorkingHours = now.hour >= 8 && now.hour <= 18;
    
    // Получаем данные из KPI для отображения
    final activeAreasCount = state.kpiCards.where((kpi) => kpi.title == 'Активные участки').firstOrNull?.value ?? '0';
    final activePolygonsCount = state.kpiCards.where((kpi) => kpi.title == 'Активные полигоны').firstOrNull?.value ?? '0';
    final violationsCount = state.kpiCards.where((kpi) => kpi.title == 'Нарушения').firstOrNull?.value ?? '0';
    final tripsCount = state.kpiCards.where((kpi) => kpi.title == 'Рейсы сегодня').firstOrNull?.value ?? '0';
    
    return Container(
      padding: const EdgeInsets.all(AppPadding.large),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSize.cardRadius),
        border: Border.all(
          color: AppColors.divider,
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: AppSize.shadowBlur,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок секции
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppPadding.small),
                decoration: BoxDecoration(
                  color: isWorkingHours ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSize.smallRadius),
                ),
                child: Icon(
                  isWorkingHours ? Icons.work : Icons.access_time,
                  color: isWorkingHours ? Colors.green : Colors.orange,
                  size: AppSize.iconSize,
                ),
              ),
              const SizedBox(width: AppPadding.normal),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Информация!',
                      style: AppTextStyles.title2,
                    ),
                    const SizedBox(height: AppPadding.xs),
                    Text(
                      isWorkingHours ? 'Рабочее время • Подрядчики активны' : 'Мониторинг подрядчиков',
                      style: AppTextStyles.caption.copyWith(
                        color: isWorkingHours ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppPadding.normal, vertical: AppPadding.xs),
                decoration: BoxDecoration(
                  color: state.error != null ? Colors.red.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSize.smallRadius),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      state.error != null ? Icons.error_outline : Icons.check_circle_outline,
                      size: 14,
                      color: state.error != null ? Colors.red : Colors.green,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      state.error != null ? 'Ошибка' : 'Активно',
                      style: AppTextStyles.caption.copyWith(
                        color: state.error != null ? Colors.red : Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppPadding.normal),

          _buildSnowVolumeChart(),

          const SizedBox(height: AppPadding.large),
          
          // Основная информация в сетке
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.calendar_today,
                  title: 'Дата',
                  value: '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}',
                  subtitle: _getWeekday(now.weekday),
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: AppPadding.normal),
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.access_time,
                  title: 'Время',
                  value: '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
                  subtitle: isWorkingHours ? 'Рабочие часы' : 'Внерабочие часы',
                  color: isWorkingHours ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppPadding.normal),
          
          // Информация об активности
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.business,
                  title: 'Активные участки',
                  value: activeAreasCount,
                  subtitle: 'Зоны уборки',
                  color: Colors.purple,
                ),
              ),
              const SizedBox(width: AppPadding.normal),
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.location_on,
                  title: 'Полигоны',
                  value: activePolygonsCount,
                  subtitle: 'Объекты мониторинга',
                  color: Colors.teal,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppPadding.normal),
          
          // Статистика операций
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.warning_amber,
                  title: 'Нарушения',
                  value: violationsCount,
                  subtitle: 'Требуют внимания',
                  color: violationsCount != '--' && int.tryParse(violationsCount)! > 0 ? Colors.red : Colors.grey,
                ),
              ),
              const SizedBox(width: AppPadding.normal),
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.local_shipping,
                  title: 'Рейсы сегодня',
                  value: tripsCount,
                  subtitle: 'Выполнено операций',
                  color: Colors.indigo,
                ),
              ),
            ],
          ),
          
          if (state.lastUpdated != null) ...[
            const SizedBox(height: AppPadding.normal),
            Container(
              padding: const EdgeInsets.all(AppPadding.normal),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppSize.smallRadius),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.update,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppPadding.xs),
                  Text(
                    'Обновлено: ${_formatDateTime(state.lastUpdated!)}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
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

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppPadding.normal),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSize.smallRadius),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: color,
                ),
              ),
              const SizedBox(width: AppPadding.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary.withValues(alpha: 0.7),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppPadding.xs),
          Text(
            value,
            style: AppTextStyles.title1.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }

  String _getWeekday(int weekday) {
    switch (weekday) {
      case 1:
        return 'Понедельник';
      case 2:
        return 'Вторник';
      case 3:
        return 'Среда';
      case 4:
        return 'Четверг';
      case 5:
        return 'Пятница';
      case 6:
        return 'Суббота';
      case 7:
        return 'Воскресенье';
      default:
        return '';
    }
  }

  Widget _buildTripStatsItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: color,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.title3.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  String _getActiveContractors(List<TripModel> trips) {
    final contractors = trips.map((t) => t.contractor).where((c) => c != 'Неизвестно').toSet().toList();
    if (contractors.isEmpty) return '0';
    if (contractors.length <= 2) {
      return contractors.join(', ');
    }
    return '${contractors.length} подрядчиков';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }




  Widget _buildErrorWidget(String error, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppPadding.normal),
      padding: const EdgeInsets.all(AppPadding.normal),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSize.cardRadius),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.red, size: 20),
          const SizedBox(width: AppPadding.small),
          Expanded(
            child: Text(
              'Ошибка загрузки данных: $error',
              style: AppTextStyles.caption.copyWith(color: Colors.red),
            ),
          ),
          TextButton(
            onPressed: () => ref.read(akimatHomeControllerProvider.notifier).refreshData(),
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }
}
