import 'package:akimat_project/core/locale/locale_provider.dart';
import 'package:akimat_project/core/navbar/drawer_mobile.dart';
import 'package:akimat_project/core/navbar/header_navbar.dart';
import 'package:akimat_project/core/navbar/navbar_widgets_provider.dart';
import 'package:akimat_project/core/platform/platform_utils.dart';
import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/core/ui/app_textstyle.dart';
import 'package:akimat_project/l10n/l10n.dart';
import 'package:akimat_project/modules/analytics/src/controller/analytics_controller.dart';
import 'package:akimat_project/modules/analytics/src/controller/analytics_providers.dart';
import 'package:akimat_project/services/analytics/model/analytics_response.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AnalyticsDashboardPage extends ConsumerStatefulWidget {
  const AnalyticsDashboardPage({
    super.key,
    required this.scaffoldKey,
    this.webNavbarWidgets,
    this.mobileNavbarWidgets,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;
  final List<Widget>? webNavbarWidgets;
  final List<Widget>? mobileNavbarWidgets;

  @override
  ConsumerState<AnalyticsDashboardPage> createState() => _AnalyticsDashboardPageState();
}

class _AnalyticsDashboardPageState extends ConsumerState<AnalyticsDashboardPage> {
  DateTime? _dateFrom;
  DateTime? _dateTo;

  @override
  void initState() {
    super.initState();
    // Устанавливаем диапазон по умолчанию (последние 7 дней)
    final now = DateTime.now();
    _dateTo = now;
    _dateFrom = now.subtract(const Duration(days: 7));
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsControllerProvider.notifier).loadDashboard(
        from: _dateFrom,
        to: _dateTo,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch locale to ensure rebuild when language changes
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
              title: Text(s.analytics),
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
            child: state.dashboard?.when(
              data: (data) => _buildDashboardContent(data, controller),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Ошибка загрузки данных: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => controller.loadDashboard(
                        from: _dateFrom,
                        to: _dateTo,
                      ),
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

  Widget _buildDashboardContent(DashboardResponse dashboardData, AnalyticsController controller) {
    final stats = dashboardData.data.stats;
    final contractors = dashboardData.data.contractors;
    final contracts = dashboardData.data.contracts;
    final cameras = dashboardData.data.cameras;
    final config = PlatformConfig.instance;

    return SingleChildScrollView(
      padding: EdgeInsets.all(config.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Кнопки управления (дата и обновление) - только для веба или вверху контента
          if (kIsWeb)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.date_range),
                  tooltip: 'Выбрать период',
                  onPressed: () => _showDateRangePicker(context, controller),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Обновить',
                  onPressed: () => controller.loadDashboard(
                    from: _dateFrom,
                    to: _dateTo,
                  ),
                ),
              ],
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: AppPadding.normal),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.date_range),
                    tooltip: 'Выбрать период',
                    onPressed: () => _showDateRangePicker(context, controller),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Обновить',
                    onPressed: () => controller.loadDashboard(
                      from: _dateFrom,
                      to: _dateTo,
                    ),
                  ),
                ],
              ),
            ),
          // KPI Cards
          Row(
            children: [
              Expanded(
                child: _buildKPICard(
                  'Активные рейсы',
                  stats.activeTrips.toString(),
                  Icons.directions_car,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: AppPadding.normal),
              Expanded(
                child: _buildKPICard(
                  'Завершено рейсов',
                  stats.completedTrips.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppPadding.normal),
          Row(
            children: [
              Expanded(
                child: _buildKPICard(
                  'Нарушения',
                  stats.violations.toString(),
                  Icons.warning,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: AppPadding.normal),
              Expanded(
                child: _buildKPICard(
                  'Тикеты в работе',
                  stats.ticketsInProgress.toString(),
                  Icons.assignment,
                  Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppPadding.large),
          
          // Подрядчики
          _buildSection(
            'Подрядчики',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (contractors.active.isNotEmpty) ...[
                  const Text('В работе:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...contractors.active.map((c) => _buildContractorCard(c, true)),
                ],
                if (contractors.idle.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('Без работы:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...contractors.idle.map((c) => _buildContractorCard(c, false)),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: AppPadding.large),
          
          // Контракты
          _buildSection(
            'Контракты',
            contracts.isEmpty
                ? const Text('Нет данных')
                : Column(
                    children: contracts.map((c) => _buildContractCard(c)).toList(),
                  ),
          ),
          
          const SizedBox(height: AppPadding.large),
          
          // Камеры
          _buildSection(
            'Камеры',
            cameras.isEmpty
                ? const Text('Нет данных')
                : Column(
                    children: cameras.map((c) => _buildCameraCard(c)).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildKPICard(String title, String value, IconData icon, Color color) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTextStyles.body),
              Icon(icon, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: AppTextStyles.title.copyWith(fontSize: 24)),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
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
          Text(title, style: AppTextStyles.title),
          const SizedBox(height: AppPadding.normal),
          content,
        ],
      ),
    );
  }

  Widget _buildContractorCard(DashboardContractor contractor, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(AppPadding.normal),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(contractor.name, style: AppTextStyles.body),
          if (contractor.count != null)
            Text('${contractor.count} рейсов', style: AppTextStyles.caption),
        ],
      ),
    );
  }

  Widget _buildContractCard(DashboardContract contract) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(AppPadding.normal),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Контракт: ${contract.contractId.substring(0, 8)}...', 
            style: AppTextStyles.body),
          if (contract.budgetProgress != null)
            Text('Бюджет: ${(contract.budgetProgress! * 100).toStringAsFixed(1)}%',
              style: AppTextStyles.caption),
          if (contract.volumeProgress != null)
            Text('Объём: ${(contract.volumeProgress! * 100).toStringAsFixed(1)}%',
              style: AppTextStyles.caption),
        ],
      ),
    );
  }

  Widget _buildCameraCard(DashboardCamera camera) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(AppPadding.normal),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Камера: ${camera.cameraId.substring(0, 8)}...', 
            style: AppTextStyles.body),
          if (camera.lprEvents != null)
            Text('LPR: ${camera.lprEvents}', style: AppTextStyles.caption),
        ],
      ),
    );
  }

  Future<void> _showDateRangePicker(
    BuildContext context,
    AnalyticsController controller,
  ) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateFrom != null && _dateTo != null
          ? DateTimeRange(start: _dateFrom!, end: _dateTo!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _dateFrom = picked.start;
        _dateTo = picked.end;
      });
      
      controller.updateDateRange(_dateFrom, _dateTo);
      controller.loadDashboard(from: _dateFrom, to: _dateTo);
    }
  }
}

