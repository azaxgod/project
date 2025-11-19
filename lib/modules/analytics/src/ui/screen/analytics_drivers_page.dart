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
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_data_table.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_empty_state.dart';
import 'package:akimat_project/services/analytics/model/analytics_response.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class AnalyticsDriversPage extends ConsumerStatefulWidget {
  const AnalyticsDriversPage({
    super.key,
    required this.scaffoldKey,
    this.webNavbarWidgets,
    this.mobileNavbarWidgets,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;
  final List<Widget>? webNavbarWidgets;
  final List<Widget>? mobileNavbarWidgets;

  @override
  ConsumerState<AnalyticsDriversPage> createState() => _AnalyticsDriversPageState();
}

class _AnalyticsDriversPageState extends ConsumerState<AnalyticsDriversPage> {
  DateTime? _dateFrom;
  DateTime? _dateTo;
  String? _selectedContractorId;
  String? _selectedDriverId;

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
    ref.read(analyticsControllerProvider.notifier).loadDriversAnalytics(
      from: _dateFrom,
      to: _dateTo,
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
              title: const Text('Аналитика водителей'),
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
            child: state.driversAnalytics?.when(
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
    DriversAnalyticsResponse data,
    AnalyticsController controller,
    PlatformConfig config,
  ) {
    if (data.data.drivers.isEmpty) {
      return const OrganizationsEmptyState(
        title: 'Нет данных',
        message: 'Нет данных о водителях за выбранный период',
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
          
          // Таблица водителей
          Container(
            padding: const EdgeInsets.all(AppPadding.large),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(AppSize.cardRadius),
              border: Border.all(color: AppColors.divider, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Водители', style: AppTextStyles.title2),
                const SizedBox(height: AppPadding.normal),
                OrganizationsDataTable(
                  columns: const [
                    DataColumn(label: Text('Водитель')),
                    DataColumn(label: Text('Рейсов')),
                    DataColumn(label: Text('Средний объём (м³)')),
                    DataColumn(label: Text('Нарушений')),
                    DataColumn(label: Text('% нарушений')),
                    DataColumn(label: Text('Средняя скорость (км/ч)')),
                    DataColumn(label: Text('Последний рейс')),
                  ],
                  rows: data.data.drivers.map((driver) {
                    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
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
                        DataCell(
                          Text(
                            driver.lastTripAt != null
                                ? dateFormat.format(driver.lastTripAt!)
                                : '—',
                          ),
                        ),
                      ],
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
}
