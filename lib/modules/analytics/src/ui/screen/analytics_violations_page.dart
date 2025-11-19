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
import 'package:akimat_project/modules/analytics/src/ui/widgets/bar_chart_widget.dart';
import 'package:akimat_project/modules/analytics/src/ui/widgets/pie_chart_widget.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_data_table.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_empty_state.dart';
import 'package:akimat_project/services/analytics/model/analytics_response.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AnalyticsViolationsPage extends ConsumerStatefulWidget {
  const AnalyticsViolationsPage({
    super.key,
    required this.scaffoldKey,
    this.webNavbarWidgets,
    this.mobileNavbarWidgets,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;
  final List<Widget>? webNavbarWidgets;
  final List<Widget>? mobileNavbarWidgets;

  @override
  ConsumerState<AnalyticsViolationsPage> createState() => _AnalyticsViolationsPageState();
}

class _AnalyticsViolationsPageState extends ConsumerState<AnalyticsViolationsPage> {
  DateTime? _dateFrom;
  DateTime? _dateTo;
  String? _selectedGroupBy = 'day';
  String? _selectedContractorId;
  String? _selectedDriverId;
  String? _selectedViolationType;

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
    ref.read(analyticsControllerProvider.notifier).loadViolationsAnalytics(
      from: _dateFrom,
      to: _dateTo,
      groupBy: _selectedGroupBy,
      contractorId: _selectedContractorId,
      driverId: _selectedDriverId,
      violationType: _selectedViolationType,
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
              title: const Text('Аналитика нарушений'),
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
            child: state.violationsAnalytics?.when(
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
    ViolationsAnalyticsResponse data,
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
          
          // График нарушений по дням
          if (data.data.series.isNotEmpty)
            BarChartWidget(
              series: data.data.series,
              title: 'Нарушения по дням',
            ),
          
          const SizedBox(height: AppPadding.large),
          
          // Распределение по типам
          if (data.data.breakdown.isNotEmpty)
            PieChartWidget(
              breakdown: data.data.breakdown,
              title: 'Распределение нарушений по типам',
            ),
          
          const SizedBox(height: AppPadding.large),
          
          // TOP проблемные подрядчики
          if (data.data.topContractors.isNotEmpty)
            _buildTopContractorsSection(data.data.topContractors),
          
          const SizedBox(height: AppPadding.large),
          
          // TOP проблемные водители
          if (data.data.topDrivers.isNotEmpty)
            _buildTopDriversSection(data.data.topDrivers),
          
          const SizedBox(height: AppPadding.large),
          
          // TOP проблемные камеры
          if (data.data.topCameras.isNotEmpty)
            _buildTopCamerasSection(data.data.topCameras),
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
            ],
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
          Text('TOP проблемные подрядчики', style: AppTextStyles.title2),
          const SizedBox(height: AppPadding.normal),
          OrganizationsDataTable(
            columns: const [
              DataColumn(label: Text('Место')),
              DataColumn(label: Text('Подрядчик')),
              DataColumn(label: Text('Количество нарушений')),
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
          Text('TOP проблемные водители', style: AppTextStyles.title2),
          const SizedBox(height: AppPadding.normal),
          OrganizationsDataTable(
            columns: const [
              DataColumn(label: Text('Место')),
              DataColumn(label: Text('Водитель')),
              DataColumn(label: Text('Количество нарушений')),
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

  Widget _buildTopCamerasSection(List<TopCamera> cameras) {
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
          Text('TOP проблемные камеры', style: AppTextStyles.title2),
          const SizedBox(height: AppPadding.normal),
          OrganizationsDataTable(
            columns: const [
              DataColumn(label: Text('Место')),
              DataColumn(label: Text('Камера')),
              DataColumn(label: Text('Ошибок')),
            ],
            rows: cameras.asMap().entries.map((e) {
              final index = e.key;
              final camera = e.value;
              return DataRow(
                cells: [
                  DataCell(Text('${index + 1}')),
                  DataCell(Text(camera.cameraName ?? camera.cameraId.substring(0, 8))),
                  DataCell(Text(camera.errorEvents.toString())),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
