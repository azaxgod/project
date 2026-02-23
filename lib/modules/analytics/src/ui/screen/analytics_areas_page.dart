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
import 'package:akimat_project/core/ui/widgets/safe_dropdown_button.dart';
import 'package:akimat_project/l10n/l10n.dart';
import 'package:akimat_project/modules/analytics/src/controller/analytics_controller.dart';
import 'package:akimat_project/modules/analytics/src/controller/analytics_providers.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_data_table.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_empty_state.dart';
import 'package:akimat_project/services/analytics/model/analytics_response.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class AnalyticsAreasPage extends ConsumerStatefulWidget {
  const AnalyticsAreasPage({
    super.key,
    required this.scaffoldKey,
    this.webNavbarWidgets,
    this.mobileNavbarWidgets,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;
  final List<Widget>? webNavbarWidgets;
  final List<Widget>? mobileNavbarWidgets;

  @override
  ConsumerState<AnalyticsAreasPage> createState() => _AnalyticsAreasPageState();
}

class _AnalyticsAreasPageState extends ConsumerState<AnalyticsAreasPage> {
  DateTime? _dateFrom;
  DateTime? _dateTo;
  String? _selectedContractorId;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateTo = now;
    _dateFrom = now.subtract(const Duration(days: 30));
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    ref.read(analyticsControllerProvider.notifier).loadAreasAnalytics(
      from: _dateFrom,
      to: _dateTo,
      contractorId: _selectedContractorId,
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
              title: const Text('Аналитика участков'),
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
            child: state.areasAnalytics?.when(
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
    AreasAnalyticsResponse data,
    AnalyticsController controller,
    PlatformConfig config,
  ) {
    if (data.data.areas.isEmpty) {
      return const OrganizationsEmptyState(
        title: 'Нет данных',
        message: 'Нет данных об участках за выбранный период',
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(config.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Фильтры
          _buildFilters(controller),
          const SizedBox(height: AppPadding.large),
          
          // Карта участков
          if (data.data.areas.any((a) => a.geometryGeojson != null))
            _buildAreasMap(data.data.areas),
          
          if (data.data.areas.any((a) => a.geometryGeojson != null))
            const SizedBox(height: AppPadding.large),
          
          // Таблица участков
          _buildAreasTable(data.data.areas),
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

  Widget _buildAreasMap(List<AreaAnalytics> areas) {
    // Находим центр карты (можно использовать первый участок или фиксированные координаты)
    final center = LatLng(51.1694, 71.4491); // Алматы
    
    return Container(
      height: 400,
      padding: const EdgeInsets.all(AppPadding.normal),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSize.cardRadius),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Карта участков', style: AppTextStyles.title2),
          const SizedBox(height: AppPadding.normal),
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: 11.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.akimat_project',
                ),
                PolygonLayer(
                  polygons: areas.where((a) => a.geometryGeojson != null).map((area) {
                    // TODO: Парсить GeoJSON и конвертировать в Polygon
                    // Пока используем заглушку
                    final color = _getAreaColor(area);
                    return Polygon(
                      points: [
                        center,
                        LatLng(center.latitude + 0.01, center.longitude),
                        LatLng(center.latitude + 0.01, center.longitude + 0.01),
                        LatLng(center.latitude, center.longitude + 0.01),
                      ],
                      color: color.withOpacity(0.3),
                      borderColor: color,
                      borderStrokeWidth: 2,
                      // isFilled: true,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getAreaColor(AreaAnalytics area) {
    if (area.violationCount > 0) {
      return Colors.red;
    } else if (area.tripCount > 0) {
      return Colors.green;
    } else {
      return Colors.grey;
    }
  }

  Widget _buildAreasTable(List<AreaAnalytics> areas) {
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
          Text('Участки', style: AppTextStyles.title2),
          const SizedBox(height: AppPadding.normal),
          OrganizationsDataTable(
            columns: const [
              DataColumn(label: Text('Участок')),
              DataColumn(label: Text('Рейсов')),
              DataColumn(label: Text('Объём (м³)')),
              DataColumn(label: Text('Нарушений')),
              DataColumn(label: Text('Средний интервал (ч)')),
              DataColumn(label: Text('Простой (ч)')),
            ],
            rows: areas.map((area) {
              return DataRow(
                cells: [
                  DataCell(Text(area.areaName ?? area.areaId.substring(0, 8))),
                  DataCell(Text(area.tripCount.toString())),
                  DataCell(
                    Text(
                      area.volumeM3 != null
                          ? area.volumeM3!.toStringAsFixed(1)
                          : '—',
                    ),
                  ),
                  DataCell(
                    Text(
                      area.violationCount.toString(),
                      style: TextStyle(
                        color: area.violationCount > 0 ? Colors.red : null,
                        fontWeight: area.violationCount > 0 ? FontWeight.bold : null,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      area.avgIntervalHours != null
                          ? area.avgIntervalHours!.toStringAsFixed(1)
                          : '—',
                    ),
                  ),
                  DataCell(
                    Text(
                      area.idleHours != null
                          ? area.idleHours!.toStringAsFixed(1)
                          : '—',
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
