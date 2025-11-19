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

class AnalyticsPerformancePage extends ConsumerStatefulWidget {
  const AnalyticsPerformancePage({
    super.key,
    required this.scaffoldKey,
    this.webNavbarWidgets,
    this.mobileNavbarWidgets,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;
  final List<Widget>? webNavbarWidgets;
  final List<Widget>? mobileNavbarWidgets;

  @override
  ConsumerState<AnalyticsPerformancePage> createState() => _AnalyticsPerformancePageState();
}

class _AnalyticsPerformancePageState extends ConsumerState<AnalyticsPerformancePage> {
  DateTime? _dateFrom;
  DateTime? _dateTo;
  String? _selectedGroupBy = 'day';

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
    ref.read(analyticsControllerProvider.notifier).loadPerformanceAnalytics(
      from: _dateFrom,
      to: _dateTo,
      groupBy: _selectedGroupBy,
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
              title: const Text('Аналитика эффективности'),
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
            child: state.performanceAnalytics?.when(
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
    PerformanceAnalyticsResponse data,
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
          
          // Подрядчики
          if (data.data.contractors.isNotEmpty)
            _buildContractorsTable(data.data.contractors),
          
          const SizedBox(height: AppPadding.large),
          
          // Водители
          if (data.data.drivers.isNotEmpty)
            _buildDriversTable(data.data.drivers),
          
          const SizedBox(height: AppPadding.large),
          
          // Транспорт
          if (data.data.vehicles.isNotEmpty)
            _buildVehiclesTable(data.data.vehicles),
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

  Widget _buildContractorsTable(List<ContractorPerformance> contractors) {
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
          Text('Эффективность подрядчиков', style: AppTextStyles.title2),
          const SizedBox(height: AppPadding.normal),
          OrganizationsDataTable(
            columns: const [
              DataColumn(label: Text('Подрядчик')),
              DataColumn(label: Text('Рейсов')),
              DataColumn(label: Text('% нарушений')),
              DataColumn(label: Text('Среднее время (мин)')),
              DataColumn(label: Text('Средний объём (м³)')),
              DataColumn(label: Text('% чистых рейсов')),
              DataColumn(label: Text('Выполнение объёма')),
            ],
            rows: contractors.map((contractor) {
              return DataRow(
                cells: [
                  DataCell(Text(contractor.name)),
                  DataCell(Text(contractor.tripCount.toString())),
                  DataCell(
                    Text(
                      '${(contractor.violationRate * 100).toStringAsFixed(1)}%',
                    ),
                  ),
                  DataCell(
                    Text(
                      contractor.avgDurationMinutes != null
                          ? contractor.avgDurationMinutes!.toStringAsFixed(1)
                          : '—',
                    ),
                  ),
                  DataCell(
                    Text(
                      contractor.avgVolumeM3 != null
                          ? contractor.avgVolumeM3!.toStringAsFixed(1)
                          : '—',
                    ),
                  ),
                  DataCell(
                    Text(
                      contractor.cleanTripRate != null
                          ? '${(contractor.cleanTripRate! * 100).toStringAsFixed(1)}%'
                          : '—',
                    ),
                  ),
                  DataCell(
                    Text(
                      contractor.volumeProgress != null
                          ? '${(contractor.volumeProgress! * 100).toStringAsFixed(1)}%'
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

  Widget _buildDriversTable(List<DriverPerformance> drivers) {
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
          Text('Эффективность водителей', style: AppTextStyles.title2),
          const SizedBox(height: AppPadding.normal),
          OrganizationsDataTable(
            columns: const [
              DataColumn(label: Text('Водитель')),
              DataColumn(label: Text('Рейсов')),
              DataColumn(label: Text('Средний объём (м³)')),
              DataColumn(label: Text('Нарушений')),
              DataColumn(label: Text('% нарушений')),
              DataColumn(label: Text('Средняя скорость (км/ч)')),
            ],
            rows: drivers.map((driver) {
              return DataRow(
                cells: [
                  DataCell(Text(driver.name)),
                  DataCell(Text(driver.tripCount.toString())),
                  DataCell(
                    Text(
                      driver.avgVolumeM3 != null
                          ? driver.avgVolumeM3!.toStringAsFixed(1)
                          : '—',
                    ),
                  ),
                  DataCell(Text(driver.violationCount.toString())),
                  DataCell(
                    Text(
                      driver.violationRate != null
                          ? '${(driver.violationRate! * 100).toStringAsFixed(1)}%'
                          : '—',
                    ),
                  ),
                  DataCell(
                    Text(
                      driver.avgSpeedKmh != null
                          ? driver.avgSpeedKmh!.toStringAsFixed(1)
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

  Widget _buildVehiclesTable(List<VehiclePerformance> vehicles) {
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
          Text('Эффективность транспорта', style: AppTextStyles.title2),
          const SizedBox(height: AppPadding.normal),
          OrganizationsDataTable(
            columns: const [
              DataColumn(label: Text('Транспорт')),
              DataColumn(label: Text('Средняя загрузка')),
              DataColumn(label: Text('Рейсов/день')),
              DataColumn(label: Text('Ошибок LPR')),
              DataColumn(label: Text('Пробег (км)')),
              DataColumn(label: Text('Простой (ч)')),
            ],
            rows: vehicles.map((vehicle) {
              return DataRow(
                cells: [
                  DataCell(Text(vehicle.name ?? vehicle.id.substring(0, 8))),
                  DataCell(
                    Text(
                      vehicle.avgFillRate != null
                          ? '${(vehicle.avgFillRate! * 100).toStringAsFixed(1)}%'
                          : '—',
                    ),
                  ),
                  DataCell(
                    Text(
                      vehicle.tripsPerDay != null
                          ? vehicle.tripsPerDay!.toStringAsFixed(1)
                          : '—',
                    ),
                  ),
                  DataCell(
                    Text(
                      vehicle.lprErrorCount != null
                          ? vehicle.lprErrorCount!.toString()
                          : '—',
                    ),
                  ),
                  DataCell(
                    Text(
                      vehicle.totalDistanceKm != null
                          ? vehicle.totalDistanceKm!.toStringAsFixed(1)
                          : '—',
                    ),
                  ),
                  DataCell(
                    Text(
                      vehicle.idleHours != null
                          ? vehicle.idleHours!.toStringAsFixed(1)
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
