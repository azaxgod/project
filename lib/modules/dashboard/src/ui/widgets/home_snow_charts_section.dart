import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/core/ui/app_textstyle.dart';
import 'package:akimat_project/modules/analytics/src/ui/widgets/bar_chart_widget.dart';
import 'package:akimat_project/services/analytics/model/analytics_response.dart';
import 'package:akimat_project/services/anpr/module.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class HomeSnowChartsSection extends ConsumerStatefulWidget {
  const HomeSnowChartsSection({
    super.key,
    this.days = 7,
    this.eventsLimitPerDay = 10000,
  });

  final int days;
  final int eventsLimitPerDay;

  @override
  ConsumerState<HomeSnowChartsSection> createState() =>
      _HomeSnowChartsSectionState();
}

class _HomeSnowChartsSectionState extends ConsumerState<HomeSnowChartsSection> {
  AsyncValue<_ChartsData> _data = const AsyncLoading();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  Future<void> _load() async {
    setState(() {
      _data = const AsyncLoading();
    });

    try {
      final anpr = ref.read(anprCollectionProvider);

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);

      final volume = <_DoubleSeriesPoint>[];
      final trips = <TimeSeriesPoint>[];
      final events = <TimeSeriesPoint>[];

      for (int i = widget.days - 1; i >= 0; i--) {
        final dayStart = todayStart.subtract(Duration(days: i));
        final dayEnd = dayStart.add(const Duration(days: 1));

        double totalVolume = 0;
        int tripCount = 0;
        int eventsCount = 0;

        try {
          final report = await anpr.getReports(
            from: dayStart,
            to: dayEnd,
            limit: 1,
            offset: 0,
          );
          totalVolume = report.data.totalVolume;
          tripCount = report.data.tripCount;
        } catch (_) {
          totalVolume = 0;
          tripCount = 0;
        }

        try {
          final eventsResp = await anpr.getEvents(
            from: dayStart,
            to: dayEnd,
            limit: widget.eventsLimitPerDay,
            offset: 0,
          );
          eventsCount = eventsResp.data.length;
        } catch (_) {
          eventsCount = 0;
        }

        volume.add(_DoubleSeriesPoint(bucket: dayStart, value: totalVolume));
        trips.add(TimeSeriesPoint(bucket: dayStart, count: tripCount));
        events.add(TimeSeriesPoint(bucket: dayStart, count: eventsCount));
      }

      setState(() {
        _data = AsyncValue.data(
          _ChartsData(
            volume: volume,
            trips: trips,
            events: events,
          ),
        );
      });
    } catch (e, st) {
      setState(() {
        _data = AsyncValue.error(e, st);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _data.when(
      data: (data) => Container(
        padding: const EdgeInsets.all(AppPadding.large),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.indigo.shade50,
              Colors.cyan.shade50,
            ],
          ),
          borderRadius: BorderRadius.circular(AppSize.cardRadius),
          border: Border.all(
            color: Colors.indigo.shade200.withAlpha(90),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.indigo.withAlpha(14),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.indigo.shade400,
                        Colors.indigo.shade600,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.indigo.withAlpha(40),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.show_chart_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppPadding.normal),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Графики',
                        style: AppTextStyles.title1.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.indigo.shade900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(180),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.indigo.shade200.withAlpha(90),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'За ${widget.days} дней',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.indigo.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _load,
                  tooltip: 'Обновить',
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(180),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.indigo.shade200.withAlpha(90),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.refresh_rounded,
                      color: Colors.indigo.shade700,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppPadding.large),
            _VolumeLineChartCard(
              title: 'Объём снега (м³)',
              series: data.volume,
              height: 220,
            ),
            const SizedBox(height: AppPadding.large),
            BarChartWidget(
              title: 'Рейсы',
              series: data.trips,
              height: 220,
            ),
            const SizedBox(height: AppPadding.large),
            BarChartWidget(
              title: 'События',
              series: data.events,
              height: 220,
            ),
          ],
        ),
      ),
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(AppPadding.large),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => Container(
        padding: const EdgeInsets.all(AppPadding.large),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.indigo.shade50,
              Colors.cyan.shade50,
            ],
          ),
          borderRadius: BorderRadius.circular(AppSize.cardRadius),
          border: Border.all(
            color: Colors.indigo.shade200.withAlpha(90),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                e.toString(),
                style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              ),
            ),
            IconButton(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartsData {
  const _ChartsData({
    required this.volume,
    required this.trips,
    required this.events,
  });

  final List<_DoubleSeriesPoint> volume;
  final List<TimeSeriesPoint> trips;
  final List<TimeSeriesPoint> events;
}

class _DoubleSeriesPoint {
  const _DoubleSeriesPoint({
    required this.bucket,
    required this.value,
  });

  final DateTime bucket;
  final double value;
}

class _VolumeLineChartCard extends StatelessWidget {
  const _VolumeLineChartCard({
    required this.title,
    required this.series,
    this.height = 200,
  });

  final String title;
  final List<_DoubleSeriesPoint> series;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty) {
      return Container(
        height: height,
        padding: const EdgeInsets.all(AppPadding.large),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(200),
          borderRadius: BorderRadius.circular(AppSize.cardRadius),
          border: Border.all(
            color: Colors.indigo.shade200.withAlpha(90),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            'Нет данных',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final maxValue = series
        .map((e) => e.value)
        .fold<double>(0.0, (prev, v) => v > prev ? v : prev);

    return Container(
      height: height,
      padding: const EdgeInsets.all(AppPadding.normal),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(200),
        borderRadius: BorderRadius.circular(AppSize.cardRadius),
        border: Border.all(
          color: Colors.indigo.shade200.withAlpha(90),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.title2.copyWith(
              fontWeight: FontWeight.w800,
              color: Colors.indigo.shade900,
            ),
          ),
          const SizedBox(height: AppPadding.normal),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxValue > 0 ? maxValue / 5 : 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppColors.divider,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: series.length > 10
                          ? (series.length / 5).ceil().toDouble()
                          : 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < series.length) {
                          final date = series[index].bucket;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              DateFormat('dd.MM').format(date),
                              style: AppTextStyles.caption,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      interval: maxValue > 0 ? maxValue / 5 : 1,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(0),
                          style: AppTextStyles.caption,
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: AppColors.divider, width: 1),
                ),
                minX: 0,
                maxX: (series.length - 1).toDouble(),
                minY: 0,
                maxY: maxValue * 1.1,
                lineBarsData: [
                  LineChartBarData(
                    spots: series.asMap().entries.map((e) {
                      return FlSpot(
                        e.key.toDouble(),
                        e.value.value,
                      );
                    }).toList(),
                    isCurved: true,
                    color: Colors.indigo.shade500,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.indigo.withAlpha(20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
