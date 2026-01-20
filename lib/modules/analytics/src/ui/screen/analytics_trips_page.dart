import 'package:akimat_project/core/locale/locale_provider.dart';
import 'package:akimat_project/core/navbar/drawer_mobile.dart';
import 'package:akimat_project/core/navbar/header_navbar.dart';
import 'package:akimat_project/core/navbar/navbar_widgets_provider.dart';
import 'package:akimat_project/core/platform/platform_utils.dart';
import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/core/ui/app_textstyle.dart';
import 'package:akimat_project/core/ui/widgets/safe_dropdown_button.dart';
import 'package:akimat_project/core/ui/widgets/date_range_picker.dart';
import 'package:akimat_project/l10n/l10n.dart';
import 'package:akimat_project/modules/analytics/src/controller/analytics_controller.dart';
import 'package:akimat_project/modules/analytics/src/controller/analytics_providers.dart';
import 'package:akimat_project/modules/analytics/src/ui/widgets/animated_section.dart';
import 'package:akimat_project/modules/analytics/src/ui/widgets/shimmer_loading.dart';
import 'package:akimat_project/modules/analytics/src/ui/widgets/time_series_chart.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_data_table.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_empty_state.dart';
import 'package:akimat_project/modules/dashboard/src/controller/organizations_controller.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/organization_type.dart';
import 'package:akimat_project/services/analytics/model/analytics_response.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class AnalyticsTripsPage extends ConsumerStatefulWidget {
  const AnalyticsTripsPage({
    super.key,
    required this.scaffoldKey,
    this.webNavbarWidgets,
    this.mobileNavbarWidgets,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;
  final List<Widget>? webNavbarWidgets;
  final List<Widget>? mobileNavbarWidgets;

  @override
  ConsumerState<AnalyticsTripsPage> createState() => _AnalyticsTripsPageState();
}

class _AnalyticsTripsPageState extends ConsumerState<AnalyticsTripsPage> {
  DateTime? _dateFrom;
  DateTime? _dateTo;
  String? _selectedGroupBy = 'day';
  String? _selectedContractorId;
  String? _selectedDriverId;

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
    ref.read(analyticsControllerProvider.notifier).loadTripsAnalytics(
      from: _dateFrom,
      to: _dateTo,
      groupBy: _selectedGroupBy,
      contractorId: _selectedContractorId,
      driverId: _selectedDriverId,
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
        title: const Text('Аналитика рейсов'),
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
            child: state.tripsAnalytics?.when(
              data: (data) => _buildContent(data, controller, config),
              loading: () => _buildLoadingState(config),
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
    TripsAnalyticsResponse data,
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
          
          // График количества рейсов
          if (data.data.series.isNotEmpty)
            AnimatedSection(
              title: 'Количество рейсов по датам',
              icon: Icons.show_chart,
              child: TimeSeriesChart(
                series: data.data.series,
                title: '',
                height: 250,
              ),
            ),
          
          const SizedBox(height: AppPadding.large),
          
          // График объёма
          if (data.data.volumeSeries.isNotEmpty)
            AnimatedSection(
              title: 'Объём по датам (м³)',
              icon: Icons.inventory,
              child: TimeSeriesChart(
                series: data.data.volumeSeries.map((v) => TimeSeriesPoint(
                  bucket: v.bucket,
                  count: v.value.toInt(),
                )).toList(),
                title: '',
                height: 250,
              ),
            ),
          
          const SizedBox(height: AppPadding.large),
          
          // Статистика
          if (data.data.durationStats != null || data.data.volumeStats != null)
            AnimatedSection(
              title: 'Статистика',
              icon: Icons.analytics,
              child: _buildStatsSection(data.data),
            ),
          
          const SizedBox(height: AppPadding.large),
          
          // TOP водители
          if (data.data.topDrivers.isNotEmpty)
            AnimatedSection(
              title: 'TOP водители',
              icon: Icons.person,
              child: _buildTopDriversSection(data.data.topDrivers),
            ),
          
          const SizedBox(height: AppPadding.large),
          
          // TOP подрядчики
          if (data.data.topContractors.isNotEmpty)
            AnimatedSection(
              title: 'TOP подрядчики',
              icon: Icons.business,
              child: _buildTopContractorsSection(data.data.topContractors),
            ),
        ],
      ),
    );
  }

  Widget _buildFilters(AnalyticsController controller) {
    final organizationsState = ref.watch(organizationsControllerProvider);
    final organizationsData = organizationsState.data.valueOrNull;
    final contractors = organizationsData?.organizations
            .where((org) => org.type == OrganizationType.contractor && org.isActive)
            .toList() ??
        [];

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
              // Период
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
              // Группировка
              SizedBox(
                width: kIsWeb ? 200 : double.infinity,
                child: SafeDropdownButtonFormField<String>(
                  value: _selectedGroupBy,
                  decoration: InputDecoration(
                    labelText: 'Группировка',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSize.smallRadius),
                    ),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'day', child: Text('По дням')),
                    DropdownMenuItem(value: 'week', child: Text('По неделям')),
                    DropdownMenuItem(value: 'month', child: Text('По месяцам')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedGroupBy = value;
                    });
                    _loadData();
                  },
                ),
              ),
              // Фильтр по подрядчикам
              if (contractors.isNotEmpty)
                SizedBox(
                  width: kIsWeb ? 250 : double.infinity,
                  child: SafeDropdownButtonFormField<String?>(
                    value: _selectedContractorId,
                    decoration: InputDecoration(
                      labelText: 'Подрядчик',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSize.smallRadius),
                      ),
                      isDense: true,
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
                        _selectedContractorId = value;
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

  Widget _buildLoadingState(PlatformConfig config) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(config.padding),
      child: Column(
        children: [
          ShimmerCard(height: 300),
          const SizedBox(height: AppPadding.large),
          ShimmerCard(height: 300),
        ],
      ),
    );
  }

  Widget _buildStatsSection(TripsAnalyticsData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          Row(
            children: [
              if (data.durationStats != null) ...[
                Expanded(
                  child: _buildStatCard(
                    'Среднее время рейса',
                    '${data.durationStats!.avgMinutes ?? 0} мин',
                    Icons.access_time,
                  ),
                ),
                const SizedBox(width: AppPadding.normal),
                Expanded(
                  child: _buildStatCard(
                    'P90 время рейса',
                    '${data.durationStats!.p90Minutes ?? 0} мин',
                    Icons.timer,
                  ),
                ),
              ],
              if (data.volumeStats != null) ...[
                if (data.durationStats != null) const SizedBox(width: AppPadding.normal),
                Expanded(
                  child: _buildStatCard(
                    'Средний объём',
                    '${(data.volumeStats!.avgM3 ?? 0).toStringAsFixed(1)} м³',
                    Icons.inventory,
                  ),
                ),
                const SizedBox(width: AppPadding.normal),
                Expanded(
                  child: _buildStatCard(
                    'P90 объём',
                    '${(data.volumeStats!.p90M3 ?? 0).toStringAsFixed(1)} м³',
                    Icons.inventory_2,
                  ),
                ),
              ],
            ],
          ),
        ],
        
      );
    
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
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
              Icon(icon, size: 20, color: AppColors.textSecondary),
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
            style: AppTextStyles.title.copyWith(fontSize: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildTopDriversSection(List<TopDriver> drivers) {
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
          Text('TOP водители по количеству рейсов', style: AppTextStyles.title2),
          const SizedBox(height: AppPadding.normal),
          OrganizationsDataTable(
            columns: const [
              DataColumn(label: Text('Место')),
              DataColumn(label: Text('Водитель')),
              DataColumn(label: Text('Количество рейсов')),
            ],
            rows: drivers.asMap().entries.map((e) {
              final index = e.key;
              final driver = e.value;
              return DataRow(
                cells: [
                  DataCell(Text('${index + 1}')),
                  DataCell(Text(driver.name)),
                  DataCell(Text(driver.count.toString())),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopContractorsSection(List<TopContractor> contractors) {
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
          Text('TOP подрядчики по активности', style: AppTextStyles.title2),
          const SizedBox(height: AppPadding.normal),
          OrganizationsDataTable(
            columns: const [
              DataColumn(label: Text('Место')),
              DataColumn(label: Text('Подрядчик')),
              DataColumn(label: Text('Количество рейсов')),
            ],
            rows: contractors.asMap().entries.map((e) {
              final index = e.key;
              final contractor = e.value;
              return DataRow(
                cells: [
                  DataCell(Text('${index + 1}')),
                  DataCell(Text(contractor.name)),
                  DataCell(Text(contractor.count.toString())),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
