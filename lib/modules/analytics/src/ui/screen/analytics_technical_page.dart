import 'package:akimat_project/core/locale/locale_provider.dart';
import 'package:akimat_project/core/navbar/drawer_mobile.dart';
import 'package:akimat_project/core/navbar/header_navbar.dart';
import 'package:akimat_project/core/navbar/navbar_widgets_provider.dart';
import 'package:akimat_project/core/platform/platform_utils.dart';
import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/core/ui/app_textstyle.dart';
import 'package:akimat_project/core/ui/widgets/date_range_picker.dart';
import 'package:akimat_project/l10n/l10n.dart';
import 'package:akimat_project/modules/analytics/src/controller/analytics_controller.dart';
import 'package:akimat_project/modules/analytics/src/controller/analytics_providers.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_data_table.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_empty_state.dart';
import 'package:akimat_project/services/analytics/model/analytics_response.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class AnalyticsTechnicalPage extends ConsumerStatefulWidget {
  const AnalyticsTechnicalPage({
    super.key,
    required this.scaffoldKey,
    this.webNavbarWidgets,
    this.mobileNavbarWidgets,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;
  final List<Widget>? webNavbarWidgets;
  final List<Widget>? mobileNavbarWidgets;

  @override
  ConsumerState<AnalyticsTechnicalPage> createState() => _AnalyticsTechnicalPageState();
}

class _AnalyticsTechnicalPageState extends ConsumerState<AnalyticsTechnicalPage> {
  DateTime? _dateFrom;
  DateTime? _dateTo;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateTo = now;
    _dateFrom = now.subtract(const Duration(days: 7));
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    ref.read(analyticsControllerProvider.notifier).loadTechnicalAnalytics(
      from: _dateFrom,
      to: _dateTo,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final s = S.of(context)!;
    final state = ref.watch(analyticsControllerProvider);
    final controller = ref.read(analyticsControllerProvider.notifier);
    final config = PlatformConfig.instance;

    return Scaffold(
      key: widget.scaffoldKey,
      drawer: !kIsWeb ? const DrawerMobile() : null,
      appBar: kIsWeb
          ? null
          : AppBar(
              title: const Text('Техническая аналитика'),
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              actions: NavbarWidgetsProvider.combineMobileWidgets(
                context,
                widget.mobileNavbarWidgets,
              ),
            ),
      body: Column(
        children: [
          if (kIsWeb)
            HeaderNavbar(
              webWidgets: widget.webNavbarWidgets,
            ),
          Expanded(
            child: state.technicalAnalytics?.when(
              data: (data) => _buildContent(data, controller, config),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Ошибка загрузки данных: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadData,
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              ),
            ) ?? const Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    TechnicalAnalyticsResponse data,
    AnalyticsController controller,
    PlatformConfig config,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(config.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Фильтры
          _buildFilters(controller),
          const SizedBox(height: AppPadding.large),
          
          // Общая статистика
          if (data.data.errorRate != null || data.data.eventFrequency != null)
            _buildOverallStats(data.data),
          
          const SizedBox(height: AppPadding.large),
          
          // Камеры
          if (data.data.cameras.isNotEmpty)
            _buildCamerasTable(data.data.cameras),
          
          const SizedBox(height: AppPadding.large),
          
          // Полигоны
          if (data.data.polygons.isNotEmpty)
            _buildPolygonsTable(data.data.polygons),
        ],
      ),
    );
  }

  Widget _buildFilters(AnalyticsController controller) {
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
          Text('Фильтры', style: AppTextStyles.title2),
          const SizedBox(height: AppPadding.normal),
          Wrap(
            spacing: AppPadding.normal,
            runSpacing: AppPadding.small,
            children: [
              SizedBox(
                width: kIsWeb ? 300 : double.infinity,
                child: CustomDateRangePicker(
                  label: 'Период',
                  initialStartDate: _dateFrom,
                  initialEndDate: _dateTo,
                  onDateRangeSelected: (start, end) {
                    setState(() {
                      _dateFrom = start;
                      _dateTo = end;
                    });
                    _loadData();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverallStats(TechnicalAnalyticsData data) {
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
          Text('Общая статистика', style: AppTextStyles.title2),
          const SizedBox(height: AppPadding.normal),
          Row(
            children: [
              if (data.errorRate != null)
                Expanded(
                  child: _buildStatCard(
                    'Доля ошибок',
                    '${(data.errorRate! * 100).toStringAsFixed(2)}%',
                    Icons.error_outline,
                    data.errorRate! > 0.05 ? Colors.red : Colors.green,
                  ),
                ),
              if (data.eventFrequency != null) ...[
                if (data.errorRate != null) const SizedBox(width: AppPadding.normal),
                Expanded(
                  child: _buildStatCard(
                    'Частота событий',
                    '${data.eventFrequency!.toStringAsFixed(1)}/час',
                    Icons.event,
                    Colors.blue,
                  ),
                ),
              ],
              if (data.lastEventAt != null) ...[
                if (data.errorRate != null || data.eventFrequency != null)
                  const SizedBox(width: AppPadding.normal),
                Expanded(
                  child: _buildStatCard(
                    'Последнее событие',
                    DateFormat('dd.MM.yyyy HH:mm').format(data.lastEventAt!),
                    Icons.access_time,
                    Colors.grey,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppPadding.normal),
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.caption,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.title.copyWith(fontSize: 20, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildCamerasTable(List<TechnicalCamera> cameras) {
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
          Text('Камеры', style: AppTextStyles.title2),
          const SizedBox(height: AppPadding.normal),
          OrganizationsDataTable(
            columns: const [
              DataColumn(label: Text('Камера')),
              DataColumn(label: Text('LPR событий')),
              DataColumn(label: Text('Volume событий')),
              DataColumn(label: Text('Ошибок')),
              DataColumn(label: Text('Доля ошибок')),
            ],
            rows: cameras.map((camera) {
              final totalEvents = camera.lprEvents + camera.volumeEvents;
              final errorRate = totalEvents > 0
                  ? (camera.errorEvents / totalEvents)
                  : 0.0;
              
              return DataRow(
                cells: [
                  DataCell(Text(camera.cameraName ?? camera.cameraId.substring(0, 8))),
                  DataCell(Text(camera.lprEvents.toString())),
                  DataCell(Text(camera.volumeEvents.toString())),
                  DataCell(
                    Text(
                      camera.errorEvents.toString(),
                      style: TextStyle(
                        color: camera.errorEvents > 0 ? Colors.red : null,
                        fontWeight: camera.errorEvents > 0 ? FontWeight.bold : null,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      '${(errorRate * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: errorRate > 0.05 ? Colors.red : null,
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPolygonsTable(List<TechnicalPolygon> polygons) {
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
          Text('Полигоны', style: AppTextStyles.title2),
          const SizedBox(height: AppPadding.normal),
          OrganizationsDataTable(
            columns: const [
              DataColumn(label: Text('Полигон')),
              DataColumn(label: Text('Рейсов')),
              DataColumn(label: Text('Объём (м³)')),
              DataColumn(label: Text('Ошибок')),
            ],
            rows: polygons.map((polygon) {
              return DataRow(
                cells: [
                  DataCell(Text(polygon.polygonName ?? polygon.polygonId.substring(0, 8))),
                  DataCell(Text(polygon.tripCount.toString())),
                  DataCell(
                    Text(
                      polygon.volume != null
                          ? polygon.volume!.toStringAsFixed(1)
                          : '—',
                    ),
                  ),
                  DataCell(
                    Text(
                      polygon.errors != null
                          ? polygon.errors!.toString()
                          : '—',
                      style: TextStyle(
                        color: (polygon.errors ?? 0) > 0 ? Colors.red : null,
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
