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
import 'package:akimat_project/core/utils/file_downloader.dart';
import 'package:akimat_project/l10n/l10n.dart';
import 'package:akimat_project/modules/analytics/src/controller/analytics_controller.dart';
import 'package:akimat_project/modules/analytics/src/controller/analytics_providers.dart';
import 'package:akimat_project/modules/analytics/src/controller/analytics_state.dart';
import 'package:akimat_project/modules/analytics/src/ui/widgets/animated_kpi_card.dart';
import 'package:akimat_project/modules/analytics/src/ui/widgets/animated_section.dart';
import 'package:akimat_project/modules/analytics/src/ui/widgets/shimmer_loading.dart';
import 'package:akimat_project/modules/analytics/src/ui/widgets/anpr_section.dart';
import 'package:akimat_project/modules/analytics/src/controller/anpr_controller.dart';
import 'package:akimat_project/modules/auth/src/controller/auth_notifier.dart';
import 'package:akimat_project/modules/auth/src/storage/token_storage.dart';
import 'package:akimat_project/modules/dashboard/src/controller/areas_controller.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/user_role.dart';
import 'package:akimat_project/modules/dashboard/src/controller/contracts_controller.dart';
import 'package:akimat_project/modules/dashboard/src/model/contracts/contract.dart';
import 'package:akimat_project/modules/dashboard/src/repository/operations_repository.dart';
import 'package:akimat_project/modules/dashboard/src/repository/operations_repository_impl.dart';
import 'package:akimat_project/services/acts/module.dart';
import 'package:akimat_project/services/analytics/model/analytics_response.dart';
import 'dart:convert';
import 'dart:io' show Platform, Directory, File;
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

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
  ConsumerState<AnalyticsDashboardPage> createState() =>
      _AnalyticsDashboardPageState();
}

class _AnalyticsDashboardPageState
    extends ConsumerState<AnalyticsDashboardPage> {
  DateTime? _dateFrom;
  DateTime? _dateTo;
  String? _selectedContractId;
  String? _selectedContractorId;
  AsyncValue<Map<String, dynamic>>? _landfillJournalData;
  bool _hasInitialLoad = false;
  bool _isLoadingInitialData = false;

  @override
  void initState() {
    super.initState();
    // Устанавливаем диапазон по умолчанию (текущий месяц)
    // Используем текущий месяц вместо последних 7 дней, чтобы избежать проблем
    // с контрактами, которые начались недавно
    final now = DateTime.now();
    _dateTo = now;
    _dateFrom = DateTime(now.year, now.month, 1); // Первый день текущего месяца
  }

  void _loadInitialData() {
    if (!mounted || _isLoadingInitialData) return;

    _isLoadingInitialData = true;

    final controller = ref.read(analyticsControllerProvider.notifier);
    final state = ref.read(analyticsControllerProvider);

    // Проверяем роль пользователя
    final authState = ref.read(authNotifierProvider);
    if (authState.user == null) {
      _isLoadingInitialData = false;
      return;
    }

    final userRole = userRoleFromString(authState.user?.role);
    final isLandfillAdmin = userRole == UserRole.landfillAdmin;

    // Упрощенная логика: загружаем если данных нет или есть ошибка
    if (isLandfillAdmin) {
      // Для LANDFILL_ADMIN загружаем техническую аналитику
      if (state.technicalAnalytics == null ||
          (!state.technicalAnalytics!.isLoading &&
              !state.technicalAnalytics!.hasValue) ||
          (state.technicalAnalytics!.hasError &&
              !state.technicalAnalytics!.isLoading)) {
        controller.loadTechnicalAnalytics(
          from: _dateFrom,
          to: _dateTo,
        );
      }
      _hasInitialLoad = true;
    } else {
      // Для других ролей загружаем обычный дашборд
      if (state.dashboard == null ||
          (!state.dashboard!.isLoading && !state.dashboard!.hasValue) ||
          (state.dashboard!.hasError && !state.dashboard!.isLoading)) {
        controller.loadDashboard(
          from: _dateFrom,
          to: _dateTo,
        );
      }
      _hasInitialLoad = true;

      // Также загружаем отфильтрованные контракты при инициализации
      if (_dateFrom != null && _dateTo != null) {
        if (state.contractsAnalytics == null ||
            (!state.contractsAnalytics!.isLoading &&
                !state.contractsAnalytics!.hasValue) ||
            (state.contractsAnalytics!.hasError &&
                !state.contractsAnalytics!.isLoading)) {
          // Загружаем контракты асинхронно, не блокируя основной UI
          Future.microtask(() {
            if (mounted) {
              controller.loadContractsAnalytics(from: _dateFrom, to: _dateTo);
            }
          });
        }
      }
    }

    _isLoadingInitialData = false;
  }

  Future<void> _loadLandfillJournal() async {
    final authState = ref.read(authNotifierProvider);
    final userRole = userRoleFromString(authState.user?.role);

    if (userRole != UserRole.landfillAdmin) {
      return;
    }

    setState(() {
      _landfillJournalData = const AsyncLoading();
    });

    try {
      final operationsRepo = ref.read(operationsRepositoryProvider);
      final result = await operationsRepo.getLandfillReceptionJournal(
        dateFrom: _dateFrom,
        dateTo: _dateTo,
      );
      setState(() {
        _landfillJournalData = AsyncValue.data(result);
      });
    } catch (e, stack) {
      setState(() {
        _landfillJournalData = AsyncValue.error(e, stack);
      });
    }
  }

  /// Проверяет, может ли пользователь генерировать акты
  bool _canGenerateActs(UserRole role) {
    return role == UserRole.akimatAdmin ||
        role == UserRole.kguZkhAdmin ||
        role == UserRole.contractorAdmin;
  }

  @override
  Widget build(BuildContext context) {
    // Watch locale to ensure rebuild when language changes
    ref.watch(localeProvider);
    final s = S.of(context)!;
    final state = ref.watch(analyticsControllerProvider);
    final controller = ref.read(analyticsControllerProvider.notifier);

    // Проверяем роль пользователя
    final authState = ref.watch(authNotifierProvider);
    final userRole = userRoleFromString(authState.user?.role);
    final isLandfillAdmin = userRole == UserRole.landfillAdmin;

    // Загружаем данные при первой загрузке
    // Используем addPostFrameCallback для гарантированной загрузки после построения виджета
    if (authState.user != null && _dateFrom != null && _dateTo != null) {
      if (!_hasInitialLoad && !_isLoadingInitialData) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_hasInitialLoad) {
            _loadInitialData();
          }
        });
      }
    }

    return Scaffold(
      key: widget.scaffoldKey,
      drawer: !kIsWeb ? const DrawerMobile() : null,
      appBar: kIsWeb
          ? null
          : AppBar(
              title:
                  Text(isLandfillAdmin ? 'Техническая аналитика' : s.analytics),
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
            child: isLandfillAdmin
                ? _buildTechnicalAnalytics(state, controller)
                : state.dashboard == null
                    ? _buildLoadingState()
                    : state.dashboard!.when(
                        data: (data) =>
                            _buildDashboardContent(data, controller),
                        loading: () => _buildLoadingState(),
                        error: (error, stack) => Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(AppPadding.large),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: Colors.red,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Ошибка загрузки данных',
                                  style: AppTextStyles.title.copyWith(
                                    color: Colors.red,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding:
                                      const EdgeInsets.all(AppPadding.normal),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondaryBackground,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    error.toString(),
                                    style: AppTextStyles.body,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        // Для LANDFILL_ADMIN загружаем техническую аналитику
                                        final authState =
                                            ref.read(authNotifierProvider);
                                        final userRole = userRoleFromString(
                                            authState.user?.role);
                                        final isLandfillAdmin =
                                            userRole == UserRole.landfillAdmin;

                                        if (isLandfillAdmin) {
                                          controller.loadTechnicalAnalytics(
                                              from: _dateFrom, to: _dateTo);
                                        } else {
                                          controller.loadDashboard(
                                              from: _dateFrom, to: _dateTo);
                                        }
                                      },
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('Повторить'),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton.icon(
                                      onPressed: () {
                                        // Показать детали ошибки
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Детали ошибки'),
                                            content: SingleChildScrollView(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text('Ошибка:',
                                                      style:
                                                          AppTextStyles.title2),
                                                  const SizedBox(height: 4),
                                                  Text(error.toString()),
                                                  if (stack != null) ...[
                                                    const SizedBox(height: 16),
                                                    Text('Stack trace:',
                                                        style: AppTextStyles
                                                            .title2),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      stack.toString(),
                                                      style:
                                                          AppTextStyles.caption,
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.of(context).pop(),
                                                child: const Text('Закрыть'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.info_outline),
                                      label: const Text('Детали'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  /// Построить техническую аналитику для LANDFILL роли
  Widget _buildTechnicalAnalytics(
    AnalyticsState state,
    AnalyticsController controller,
  ) {
    if (state.technicalAnalytics == null) {
      return _buildLoadingState();
    }

    return state.technicalAnalytics!.when(
      data: (data) => _buildTechnicalContent(data, controller),
      loading: () => _buildLoadingState(),
      error: (error, stack) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppPadding.large),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Ошибка загрузки технической аналитики',
                style: AppTextStyles.title.copyWith(
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(AppPadding.normal),
                decoration: BoxDecoration(
                  color: AppColors.secondaryBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  error.toString(),
                  style: AppTextStyles.body,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => controller.loadTechnicalAnalytics(
                  from: _dateFrom,
                  to: _dateTo,
                ),
                icon: const Icon(Icons.refresh),
                label: const Text('Повторить'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Построить контент технической аналитики
  Widget _buildTechnicalContent(
    TechnicalAnalyticsResponse data,
    AnalyticsController controller,
  ) {
    final config = PlatformConfig.instance;

    return SingleChildScrollView(
      padding: EdgeInsets.all(config.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Фильтры
          Container(
            margin: const EdgeInsets.only(bottom: AppPadding.large),
            padding: const EdgeInsets.all(AppPadding.normal),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(AppSize.cardRadius),
              border: Border.all(color: AppColors.divider, width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.divider.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Фильтры', style: AppTextStyles.title2),
                const SizedBox(height: AppPadding.normal),
                Row(
                  children: [
                    Expanded(
                      child: CustomDateRangePicker(
                        label: 'Период аналитики',
                        initialStartDate: _dateFrom,
                        initialEndDate: _dateTo,
                        onDateRangeSelected: (start, end) {
                          if (start == null || end == null) return;

                          setState(() {
                            _dateFrom = start;
                            _dateTo = end;
                            // Сбрасываем флаг начальной загрузки, чтобы данные загрузились заново
                            _hasInitialLoad = false;
                          });

                          // Обновляем диапазон дат в контроллере
                          controller.updateDateRange(start, end);
                          // Загружаем техническую аналитику
                          controller.loadTechnicalAnalytics(
                              from: start, to: end);
                        },
                      ),
                      
                    ),
                    
                    const SizedBox(width: AppPadding.normal),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(AppSize.smallRadius),
                      ),
                      child: IconButton(
                        icon:
                            const Icon(Icons.refresh, color: AppColors.primary),
                        tooltip: 'Обновить данные',
                        onPressed: () {
                          controller.loadTechnicalAnalytics(
                              from: _dateFrom, to: _dateTo);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Общая статистика
          if (data.data.errorRate != null ||
              data.data.eventFrequency != null ||
              data.data.lastEventAt != null)
            _buildTechnicalOverallStats(data.data),

          const SizedBox(height: AppPadding.large),

          // Камеры
          if (data.data.cameras.isNotEmpty)
            _buildTechnicalCamerasTable(data.data.cameras),

          const SizedBox(height: AppPadding.large),

          // Полигоны
          if (data.data.polygons.isNotEmpty)
            _buildTechnicalPolygonsTable(data.data.polygons),
        ],
      ),
    );
  }

  /// Построить общую статистику технической аналитики
  Widget _buildTechnicalOverallStats(TechnicalAnalyticsData data) {
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
                  child: AnimatedKPICard(
                    title: 'Доля ошибок',
                    value: '${(data.errorRate! * 100).toStringAsFixed(2)}%',
                    icon: Icons.error_outline,
                    color: (data.errorRate ?? 0) > 0.05
                        ? Colors.red
                        : Colors.green,
                  ),
                ),
              if (data.eventFrequency != null) ...[
                if (data.errorRate != null)
                  const SizedBox(width: AppPadding.normal),
                Expanded(
                  child: AnimatedKPICard(
                    title: 'Частота событий',
                    value: '${data.eventFrequency!.toStringAsFixed(1)}/час',
                    icon: Icons.event,
                    color: Colors.blue,
                  ),
                ),
              ],
              if (data.lastEventAt != null) ...[
                if (data.errorRate != null || data.eventFrequency != null)
                  const SizedBox(width: AppPadding.normal),
                Expanded(
                  child: AnimatedKPICard(
                    title: 'Последнее событие',
                    value: DateFormat('dd.MM.yyyy\nHH:mm')
                        .format(data.lastEventAt!),
                    icon: Icons.access_time,
                    color: Colors.grey,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// Построить таблицу камер для технической аналитики
  Widget _buildTechnicalCamerasTable(List<TechnicalCamera> cameras) {
    return AnimatedSection(
      title: 'Камеры',
      icon: Icons.videocam,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Камера')),
            DataColumn(label: Text('LPR событий')),
            DataColumn(label: Text('Volume событий')),
            DataColumn(label: Text('Ошибок')),
            DataColumn(label: Text('Доля ошибок')),
          ],
          rows: cameras.map((camera) {
            final totalEvents = camera.lprEvents + camera.volumeEvents;
            final errorRate =
                totalEvents > 0 ? (camera.errorEvents / totalEvents) : 0.0;

            return DataRow(
              cells: [
                DataCell(
                    Text(camera.cameraName ?? camera.cameraId.substring(0, 8))),
                DataCell(Text(camera.lprEvents.toString())),
                DataCell(Text(camera.volumeEvents.toString())),
                DataCell(
                  Text(
                    camera.errorEvents.toString(),
                    style: TextStyle(
                      color: camera.errorEvents > 0 ? Colors.red : null,
                      fontWeight:
                          camera.errorEvents > 0 ? FontWeight.bold : null,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    '${(errorRate * 100).toStringAsFixed(2)}%',
                    style: TextStyle(
                      color: errorRate > 0.05 ? Colors.red : Colors.green,
                      fontWeight: errorRate > 0.05 ? FontWeight.bold : null,
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Построить таблицу полигонов для технической аналитики
  Widget _buildTechnicalPolygonsTable(List<TechnicalPolygon> polygons) {
    return AnimatedSection(
      title: 'Полигоны',
      icon: Icons.map,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Полигон')),
            DataColumn(label: Text('Рейсов')),
            DataColumn(label: Text('Объём (м³)')),
            DataColumn(label: Text('Ошибок')),
          ],
          rows: polygons.map((polygon) {
            final volume = polygon.volume ?? 0.0;
            final errors = polygon.errors ?? 0;
            return DataRow(
              cells: [
                DataCell(Text(
                    polygon.polygonName ?? polygon.polygonId.substring(0, 8))),
                DataCell(Text(polygon.tripCount.toString())),
                DataCell(Text(volume.toStringAsFixed(2))),
                DataCell(
                  Text(
                    errors.toString(),
                    style: TextStyle(
                      color: errors > 0 ? Colors.red : null,
                      fontWeight: errors > 0 ? FontWeight.bold : null,
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDashboardContent(
      DashboardResponse dashboardData, AnalyticsController controller) {
    final stats = dashboardData.data.stats;
    final contractors = dashboardData.data.contractors;
    final dashboardContracts = dashboardData.data.contracts;
    final cameras = dashboardData.data.cameras;
    final config = PlatformConfig.instance;

    // Проверяем роль пользователя
    final authState = ref.watch(authNotifierProvider);
    final userRole = userRoleFromString(authState.user?.role);
    final isLandfillAdmin = userRole == UserRole.landfillAdmin;
    final isContractorAdmin = userRole == UserRole.contractorAdmin;

    // Получаем отфильтрованные контракты из contractsAnalytics (если доступны)
    final state = ref.watch(analyticsControllerProvider);
    final contractsAnalyticsData = state.contractsAnalytics?.valueOrNull;

    // Используем отфильтрованные контракты из /analytics/contracts, если они доступны
    // Иначе используем контракты из дашборда
    List<DashboardContract> contractsToUse;
    if (contractsAnalyticsData != null &&
        _dateFrom != null &&
        _dateTo != null) {
      // Преобразуем ContractSummary в DashboardContract для отображения
      final filteredContractIds =
          contractsAnalyticsData.data.summary.map((c) => c.contractId).toSet();

      // Также добавляем контракты из других списков (topBudget, atRisk, budgetIssues)
      filteredContractIds.addAll(
          contractsAnalyticsData.data.topBudget.map((c) => c.contractId));
      filteredContractIds
          .addAll(contractsAnalyticsData.data.atRisk.map((c) => c.contractId));
      filteredContractIds.addAll(
          contractsAnalyticsData.data.budgetIssues.map((c) => c.contractId));

      // Фильтруем контракты из дашборда по ID из contractsAnalytics
      contractsToUse = dashboardContracts.where((contract) {
        return filteredContractIds.contains(contract.contractId);
      }).toList();
    } else {
      // Если contractsAnalytics не загружены, используем контракты из дашборда
      contractsToUse = dashboardContracts;
    }

    // Дополнительная фильтрация по выбранному подрядчику и контракту
    List<DashboardContract> filteredContracts = contractsToUse;

    // Фильтрация по подрядчику (если выбран)
    if (_selectedContractorId != null) {
      final contractsState = ref.watch(contractsControllerProvider);
      final contractsData = contractsState.data.valueOrNull;
      final allContracts = contractsData?.contracts ?? <Contract>[];

      // Получаем ID контрактов выбранного подрядчика
      final contractorContractIds = allContracts
          .where((contract) => contract.contractorId == _selectedContractorId)
          .map((contract) => contract.id)
          .toSet();

      // Фильтруем контракты дашборда по ID контрактов подрядчика
      filteredContracts = contractsToUse
          .where((contract) => contractorContractIds.contains(contract.contractId))
          .toList();
    }

    // Фильтрация по выбранному контракту (если выбран)
    if (_selectedContractId != null) {
      filteredContracts = filteredContracts
          .where((contract) => contract.contractId == _selectedContractId)
          .toList();
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(config.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Красивый виджет выбора даты и кнопка обновления
          Container(
            margin: const EdgeInsets.only(bottom: AppPadding.large),
            padding: const EdgeInsets.all(AppPadding.normal),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(AppSize.cardRadius),
              border: Border.all(color: AppColors.divider, width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.divider.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Выбор даты
                Row(
                  children: [
                    Expanded(
                      child: CustomDateRangePicker(
                        label: 'Период аналитики',
                        initialStartDate: _dateFrom,
                        initialEndDate: _dateTo,
                        onDateRangeSelected: (start, end) {
                          if (start == null || end == null) return;

                          setState(() {
                            _dateFrom = start;
                            _dateTo = end;
                            // При изменении даты сбрасываем выбранный контракт, чтобы показать все контракты в новом периоде
                            _selectedContractId = null;
                            // Сбрасываем флаг начальной загрузки, чтобы данные загрузились заново
                            _hasInitialLoad = false;
                          });

                          // Обновляем диапазон дат в контроллере
                          controller.updateDateRange(start, end);

                          // Для LANDFILL_ADMIN загружаем техническую аналитику
                          if (isLandfillAdmin) {
                            controller.loadTechnicalAnalytics(
                                from: start, to: end);
                          } else {
                            controller.loadDashboard(from: start, to: end);
                            // Перезагружаем контракты с фильтром по дате
                            controller.loadContractsAnalytics(
                                from: start, to: end);
                            // Перезагружаем данные журнала приёма снега
                            _loadLandfillJournal();
                          }
                        },
                      ),
                    ),

                    const SizedBox(width: AppPadding.normal),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(AppSize.smallRadius),
                      ),
                      child: IconButton(
                        icon:
                            const Icon(Icons.refresh, color: AppColors.primary),
                        tooltip: 'Обновить данные',
                        onPressed: () {
                          // Для LANDFILL_ADMIN загружаем техническую аналитику
                          if (isLandfillAdmin) {
                            controller.loadTechnicalAnalytics(
                                from: _dateFrom, to: _dateTo);
                          } else {
                            controller.loadDashboard(
                                from: _dateFrom, to: _dateTo);
                            // Всегда загружаем отфильтрованные контракты при обновлении
                            if (_dateFrom != null && _dateTo != null) {
                              controller.loadContractsAnalytics(
                                  from: _dateFrom, to: _dateTo);
                              // Перезагружаем данные журнала приёма снега
                              _loadLandfillJournal();
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
                // Фильтр по подрядчикам (скрыт для LANDFILL_ADMIN и CONTRACTOR_ADMIN)
                if (!isLandfillAdmin && !isContractorAdmin) ...[
                  const SizedBox(height: AppPadding.normal),
                  Builder(
                    builder: (context) {
                      // Получаем список всех подрядчиков из данных дашборда
                      final allContractors = [
                        ...contractors.active,
                        ...contractors.idle,
                      ];

                      if (allContractors.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Выберите подрядчика',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppPadding.small),
                          SizedBox(
                            width: double.infinity,
                            child: DropdownButtonFormField<String>(
                              value: _selectedContractorId,
                              decoration: InputDecoration(
                                labelText: 'Подрядчик',
                                hintText: 'Все подрядчики',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppSize.smallRadius),
                                ),
                                prefixIcon: const Icon(Icons.business),
                                isDense: true,
                              ),
                              items: [
                                const DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('Все подрядчики'),
                                ),
                                ...allContractors.map((contractor) {
                                  return DropdownMenuItem<String>(
                                    value: contractor.id,
                                    child: Text(contractor.name),
                                  );
                                }),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedContractorId = value;
                                  // При изменении подрядчика сбрасываем выбранный контракт
                                  _selectedContractId = null;
                                });
                                // Перезагружаем данные ANPR при изменении фильтра подрядчика
                                // Это произойдет автоматически через didUpdateWidget в AnprSection
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
                // Выбор контракта из созданных контрактов (скрыт для LANDFILL_ADMIN и CONTRACTOR_ADMIN)
                if (!isLandfillAdmin && !isContractorAdmin) ...[
                  const SizedBox(height: AppPadding.normal),
                  Builder(
                    builder: (context) {
                      final contractsState =
                          ref.watch(contractsControllerProvider);
                      final contractsData = contractsState.data.valueOrNull;
                      final allContracts =
                          contractsData?.contracts ?? <Contract>[];

                      // Фильтруем контракты по выбранной дате и подрядчику
                      List<Contract> contractsToShow = allContracts;

                      // Фильтр по подрядчику
                      if (_selectedContractorId != null) {
                        contractsToShow = contractsToShow.where((contract) {
                          return contract.contractorId == _selectedContractorId;
                        }).toList();
                      }

                      // Фильтр по выбранной дате (если дата выбрана)
                      if (_dateFrom != null && _dateTo != null) {
                        contractsToShow = contractsToShow.where((contract) {
                          final contractStart = DateTime(contract.startAt.year,
                              contract.startAt.month, contract.startAt.day);
                          final contractEnd = DateTime(contract.endAt.year,
                              contract.endAt.month, contract.endAt.day);
                          final selectedFrom = DateTime(_dateFrom!.year,
                              _dateFrom!.month, _dateFrom!.day);
                          final selectedTo = DateTime(
                              _dateTo!.year, _dateTo!.month, _dateTo!.day);

                          // Показываем контракты, которые активны в выбранный период
                          return contractStart.isBefore(
                                  selectedTo.add(const Duration(days: 1))) &&
                              contractEnd.isAfter(selectedFrom
                                  .subtract(const Duration(days: 1)));
                        }).toList();
                      }

                      if (contractsToShow.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Выберите контракт',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppPadding.small),
                          SizedBox(
                            width: double.infinity,
                            child: DropdownButtonFormField<String>(
                              value: _selectedContractId,
                              decoration: InputDecoration(
                                labelText: 'Контракт',
                                hintText: 'Все контракты',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppSize.smallRadius),
                                ),
                                prefixIcon: const Icon(Icons.description),
                                isDense: true,
                              ),
                              items: [
                                const DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('Все контракты'),
                                ),
                                ...contractsToShow.map((contract) {
                                  return DropdownMenuItem<String>(
                                    value: contract.id,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          contract.name,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          '${DateFormat('dd.MM.yyyy').format(contract.startAt)} - ${DateFormat('dd.MM.yyyy').format(contract.endAt)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedContractId = value;

                                  // Если выбран контракт, устанавливаем его период как выбранную дату
                                  if (value != null) {
                                    final selectedContract = contractsToShow
                                        .firstWhere((c) => c.id == value);
                                    _dateFrom = selectedContract.startAt;
                                    _dateTo = selectedContract.endAt;

                                    // Обновляем данные аналитики
                                    final analyticsController = ref.read(
                                        analyticsControllerProvider.notifier);
                                    analyticsController.loadDashboard(
                                        from: _dateFrom, to: _dateTo);
                                    analyticsController.loadContractsAnalytics(
                                        from: _dateFrom, to: _dateTo);
                                  }
                                });
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
                
                // Информация о выбранном контракте (скрыта для LANDFILL_ADMIN и CONTRACTOR_ADMIN)
                if (!isLandfillAdmin &&
                    !isContractorAdmin &&
                    _selectedContractId != null) ...[
                  const SizedBox(height: AppPadding.normal),
                  Container(
                    padding: const EdgeInsets.all(AppPadding.small),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSize.smallRadius),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Builder(
                      builder: (context) {
                        final contractsState =
                            ref.watch(contractsControllerProvider);
                        final contractsData = contractsState.data.valueOrNull;
                        final allCreatedContracts =
                            contractsData?.contracts ?? <Contract>[];
                        final selectedCreatedContract =
                            _selectedContractId != null
                                ? allCreatedContracts
                                    .where((c) => c.id == _selectedContractId)
                                    .firstOrNull
                                : null;

                        if (selectedCreatedContract == null) {
                          return Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: AppPadding.small),
                              Expanded(
                                child: Text(
                                  'Выбран контракт: ${_selectedContractId!.substring(0, 12)}...\n'
                                  'При скачивании акта будет использован период действия контракта',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: AppPadding.small),
                                Expanded(
                                  child: Text(
                                    'Выбран контракт: ${selectedCreatedContract.name}',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Период: ${DateFormat('dd.MM.yyyy').format(selectedCreatedContract.startAt)} - ${DateFormat('dd.MM.yyyy').format(selectedCreatedContract.endAt)}',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'При скачивании акта будет использован период действия контракта',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.primary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),

          Builder(
            builder: (context) {
              final authState = ref.watch(authNotifierProvider);
              final userRole = userRoleFromString(authState.user?.role);

              if (userRole != UserRole.kguZkhAdmin &&
                  userRole != UserRole.akimatAdmin &&
                  userRole != UserRole.contractorAdmin) {
                return const SizedBox.shrink();
              }

              final anprDateTo = _dateTo ?? DateTime.now();
              final anprDateFrom =
                  _dateFrom ?? anprDateTo.subtract(const Duration(hours: 24));

              final contractorId = userRole == UserRole.contractorAdmin
                  ? authState.user?.organizationId
                  : _selectedContractorId;

              return Column(
                children: [
                  AnprSection(
                    dateFrom: anprDateFrom,
                    dateTo: anprDateTo,
                    contractorId: contractorId,
                    showReports: true,
                    showStatistics: false,
                    showEvents: false,
                  ),
                  const SizedBox(height: AppPadding.large),
                ],
              );
            },
          ),

          // KPI Cards (скрыты для LANDFILL_ADMIN, но показываются для CONTRACTOR_ADMIN)
          if (!isLandfillAdmin) ...[
            Row(
              children: [
                // Expanded(
                //   child: AnimatedKPICard(
                //     title: 'Активные рейсы',
                //     value: stats.activeTrips.toString(),
                //     icon: Icons.directions_car,
                //     color: Colors.blue,
                //   ),
                // ),
                const SizedBox(width: AppPadding.normal),
                // Expanded(
                //   child: AnimatedKPICard(
                //     title: 'Завершено рейсов',
                //     value: stats.completedTrips.toString(),
                //     icon: Icons.check_circle,
                //     color: Colors.green,
                //   ),
                // ),
              ],
            ),
            const SizedBox(height: AppPadding.normal),
            // Row(
            //   children: [
            //     Expanded(
            //       child: AnimatedKPICard(
            //         title: 'Нарушения',
            //         value: stats.violations.toString(),
            //         icon: Icons.warning,
            //         color: Colors.orange,
            //       ),
            //     ),
            //     const SizedBox(width: AppPadding.normal),
            //     Expanded(
            //       child: AnimatedKPICard(
            //         title: 'Тикеты в работе',
            //         value: stats.ticketsInProgress.toString(),
            //         icon: Icons.assignment,
            //         color: Colors.purple,
            //       ),
            //     ),
            //   ],
            // ),
            const SizedBox(height: AppPadding.large),
          ],

          // Карта (скрыта для LANDFILL_ADMIN и CONTRACTOR_ADMIN)
          if (!isLandfillAdmin &&
              !isContractorAdmin &&
              (dashboardData.data.map.areas.isNotEmpty ||
                  dashboardData.data.map.polygons.isNotEmpty))
            AnimatedSection(
              title: 'Карта города',
              icon: Icons.map,
              child: _buildMapSection(dashboardData.data.map),
            ),

          if (!isLandfillAdmin &&
              !isContractorAdmin &&
              (dashboardData.data.map.areas.isNotEmpty ||
                  dashboardData.data.map.polygons.isNotEmpty))
            const SizedBox(height: AppPadding.large),

          // Подрядчики (скрыты для LANDFILL_ADMIN и CONTRACTOR_ADMIN)
          if (!isLandfillAdmin && !isContractorAdmin)
            // AnimatedSection(
            //   title: 'Подрядчики',
            //   icon: Icons.business,
            //   child: Column(
            //     crossAxisAlignment: CrossAxisAlignment.start,
            //     children: [
            //       if (contractors.active.isNotEmpty) ...[
            //         Text(
            //           'В работе:',
            //           style: AppTextStyles.headline.copyWith(
            //             color: AppColors.textSecondary,
            //           ),
            //         ),
            //         const SizedBox(height: 12),
            //         ...contractors.active.asMap().entries.map((entry) {
            //           return _buildAnimatedContractorCard(
            //             entry.value,
            //             true,
            //             entry.key,
            //           );
            //         }),
            //       ],
            //       if (contractors.idle.isNotEmpty) ...[
            //         const SizedBox(height: 20),
            //         Text(
            //           'Без работы:',
            //           style: AppTextStyles.headline.copyWith(
            //             color: AppColors.textSecondary,
            //           ),
            //         ),
            //         const SizedBox(height: 12),
            //         ...contractors.idle.asMap().entries.map((entry) {
            //           return _buildAnimatedContractorCard(
            //             entry.value,
            //             false,
            //             contractors.active.length + entry.key,
            //           );
            //         }),
            //       ],
            //     ],
            //   ),
            // ),
         
          if (!isLandfillAdmin && !isContractorAdmin)
            const SizedBox(height: AppPadding.large),

          // Контракты (скрыты для LANDFILL_ADMIN и CONTRACTOR_ADMIN)
          if (!isLandfillAdmin && !isContractorAdmin)
            //   AnimatedSection(
            //     title: 'Контракты${_dateFrom != null && _dateTo != null ? ' (Акт выполненных работ)' : ''}',
            //     icon: Icons.description,
            //     child: filteredContracts.isEmpty
            //         ? Center(
            //             child: Text(
            //               _selectedContractId != null
            //                   ? 'Контракт не найден в выбранном периоде'
            //                   : 'Нет данных',
            //               style: AppTextStyles.body.copyWith(
            //                 color: AppColors.textSecondary,
            //               ),
            //             ),
            //           )
            //         : Column(
            //             children: filteredContracts.asMap().entries.map((entry) {
            //               return _buildAnimatedContractCard(entry.value, entry.key);
            //             }).toList(),
            //           ),
            //   ),

            // if (!isLandfillAdmin && !isContractorAdmin)
            // const SizedBox(height: AppPadding.large),

            // // Камеры (скрыты для LANDFILL_ADMIN и CONTRACTOR_ADMIN)
            // if (!isLandfillAdmin && !isContractorAdmin)
            //   AnimatedSection(
            //     title: 'Камеры',
            //     icon: Icons.videocam,
            //     child: cameras.isEmpty
            //         ? Center(
            //             child: Text(
            //               'Нет данных',
            //               style: AppTextStyles.body.copyWith(
            //                 color: AppColors.textSecondary,
            //               ),
            //             ),
            //           )
            //         : Column(
            //             children: cameras.asMap().entries.map((entry) {
            //               return _buildAnimatedCameraCard(entry.value, entry.key);
            //             }).toList(),
            //           ),
            //   ),

            // Акт работ (только для LANDFILL_ADMIN)
            Builder(
              builder: (context) {
                final authState = ref.watch(authNotifierProvider);
                final userRole = userRoleFromString(authState.user?.role);

                if (userRole != UserRole.landfillAdmin) {
                  return const SizedBox.shrink();
                }

                return _buildLandfillActSection();
              },
            ),

          // Секция ANPR (для KGU_ZKH_ADMIN, AKIMAT_ADMIN и CONTRACTOR_ADMIN)
          // Builder(
          //   builder: (context) {
          //     final authState = ref.watch(authNotifierProvider);
          //     final userRole = userRoleFromString(authState.user?.role);
          //
          //     if (userRole != UserRole.kguZkhAdmin &&
          //         userRole != UserRole.akimatAdmin &&
          //         userRole != UserRole.contractorAdmin) {
          //       return const SizedBox.shrink();
          //     }
          //
          //     return const SizedBox(height: AppPadding.large);
          //   },
          // ),
          // Builder(
          //   builder: (context) {
          //     final authState = ref.watch(authNotifierProvider);
          //     final userRole = userRoleFromString(authState.user?.role);
          //
          //     if (userRole != UserRole.kguZkhAdmin &&
          //         userRole != UserRole.akimatAdmin &&
          //         userRole != UserRole.contractorAdmin) {
          //       return const SizedBox.shrink();
          //     }
          //
          //     // Согласно документации: период по умолчанию для ANPR - последние 24 часа
          //     final anprDateTo = _dateTo ?? DateTime.now();
          //     final anprDateFrom =
          //         _dateFrom ?? anprDateTo.subtract(const Duration(hours: 24));
          //
          //     // Для CONTRACTOR_ADMIN передаем contractorId (organizationId пользователя)
          //     // Для contractorAdmin всегда берем организацию пользователя.
          //     // Для остальных ролей используем выбранного подрядчика (если выбран).
          //     final contractorId = userRole == UserRole.contractorAdmin
          //         ? authState.user?.organizationId
          //         : _selectedContractorId;
          //
          //     return AnprSection(
          //       dateFrom: anprDateFrom,
          //       dateTo: anprDateTo,
          //       contractorId: contractorId,
          //     );
          //   },
          // ),
        ],
      ),
    );
  }

  Widget _buildLandfillActSection() {
    return AnimatedSection(
      title: 'Объём привезённого снега',
      icon: Icons.snowing,
      child: _landfillJournalData?.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text(
                'Ошибка загрузки данных: $error',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.error,
                ),
              ),
            ),
            data: (data) {
              final tripsData = data['data'] as Map<String, dynamic>?;
              final totalVolumeM3 =
                  (tripsData?['total_volume_m3'] as num?)?.toDouble() ?? 0.0;
              final totalTrips = (tripsData?['total_trips'] as int?) ?? 0;

              return Container(
                padding: const EdgeInsets.all(AppPadding.large),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue.withOpacity(0.15),
                      Colors.blue.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.snowing,
                            size: 28,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Общий объём привезённого снега',
                                style: AppTextStyles.title2.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Всеми подрядчиками на полигоны организации',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(
                              '${totalVolumeM3.toStringAsFixed(2)}',
                              style: AppTextStyles.headline.copyWith(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'м³',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Объём снега',
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                        Container(
                          width: 1,
                          height: 60,
                          color: AppColors.divider,
                        ),
                        Column(
                          children: [
                            Text(
                              '$totalTrips',
                              style: AppTextStyles.headline.copyWith(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'рейсов',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Всего рейсов',
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (_dateFrom != null && _dateTo != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(AppPadding.small),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Период: ${DateFormat('dd.MM.yyyy').format(_dateFrom!)} - ${DateFormat('dd.MM.yyyy').format(_dateTo!)}',
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ) ??
          const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildLoadingState() {
    final config = PlatformConfig.instance;
    return SingleChildScrollView(
      padding: EdgeInsets.all(config.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: ShimmerCard()),
              const SizedBox(width: AppPadding.normal),
              Expanded(child: ShimmerCard()),
            ],
          ),
          const SizedBox(height: AppPadding.normal),
          Row(
            children: [
              Expanded(child: ShimmerCard()),
              const SizedBox(width: AppPadding.normal),
              Expanded(child: ShimmerCard()),
            ],
          ),
          const SizedBox(height: AppPadding.large),
          ShimmerCard(height: 200),
        ],
      ),
    );
  }

  Widget _buildAnimatedContractorCard(
    DashboardContractor contractor,
    bool isActive,
    int index,
  ) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: _buildContractorCard(contractor, isActive),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedContractCard(DashboardContract contract, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: _buildContractCard(contract),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedCameraCard(DashboardCamera camera, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: _buildCameraCard(camera),
          ),
        );
      },
    );
  }

  Widget _buildContractorCard(DashboardContractor contractor, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(AppPadding.normal),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isActive
              ? [
                  Colors.green.withOpacity(0.15),
                  Colors.green.withOpacity(0.05),
                ]
              : [
                  Colors.grey.withOpacity(0.1),
                  Colors.grey.withOpacity(0.05),
                ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? Colors.green.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive ? Colors.green : Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                contractor.name,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (contractor.count != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.green.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${contractor.count} рейсов',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  color:
                      isActive ? Colors.green.shade700 : Colors.grey.shade700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContractCard(DashboardContract contract) {
    final budgetProgress = contract.budgetProgress ?? 0.0;
    final volumeProgress = contract.volumeProgress ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(AppPadding.normal),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.withOpacity(0.15),
            Colors.blue.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.description,
                size: 16,
                color: Colors.blue,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Контракт: ${contract.contractId.substring(0, 12)}...',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (contract.startAt != null && contract.endAt != null)
                      Text(
                        'Период: ${DateFormat('dd.MM.yyyy').format(contract.startAt!)} - ${DateFormat('dd.MM.yyyy').format(contract.endAt!)}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (contract.budgetProgress != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Бюджет',
                  style: AppTextStyles.caption,
                ),
                Text(
                  '${(budgetProgress * 100).toStringAsFixed(1)}%',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: budgetProgress.clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: Colors.blue.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  budgetProgress > 1.0
                      ? Colors.red
                      : (budgetProgress > 0.8 ? Colors.orange : Colors.blue),
                ),
              ),
            ),
          ],
          if (contract.volumeProgress != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Объём',
                  style: AppTextStyles.caption,
                ),
                Text(
                  '${(volumeProgress * 100).toStringAsFixed(1)}%',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: volumeProgress.clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: Colors.green.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  volumeProgress > 1.0
                      ? Colors.green.shade700
                      : (volumeProgress > 0.8
                          ? Colors.green
                          : Colors.green.shade400),
                ),
              ),
            ),
          ],
          // Кнопка скачать акт (PDF)
          Builder(
            builder: (context) {
              final authState = ref.watch(authNotifierProvider);
              final userRole = userRoleFromString(authState.user?.role);
              final canGenerateActs = _canGenerateActs(userRole);

              if (!canGenerateActs) {
                return const SizedBox.shrink();
              }

              return Column(
                children: [
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            // Используем ID контракта из карточки или выбранный контракт из виджета
                            final contractIdToUse =
                                _selectedContractId ?? contract.contractId;

                            // Если период не выбран, бэкенд использует период действия контракта
                            if (_dateFrom == null || _dateTo == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Период не выбран. Будет использован период действия контракта (ID: ${contractIdToUse.substring(0, 12)}...)'),
                                  backgroundColor: Colors.blue,
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                              // Передаем null, бэкенд использует период контракта (start_at, end_at)
                              _downloadActWithPeriod(
                                contractIdToUse,
                                null, // Бэкенд возьмет start_at контракта
                                null, // Бэкенд возьмет end_at контракта
                              );
                            } else {
                              // Период выбран пользователем - проверяем и корректируем его
                              _downloadActWithValidation(contractIdToUse, contract);
                            }
                          },
                          icon: const Icon(Icons.download, size: 18),
                          label: const Text('Скачать акт (PDF)',
                              style: TextStyle(fontSize: 12)),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _downloadExcelAct(context),
                          icon: const Icon(Icons.table_chart, size: 18),
                          label: const Text('Скачать Excel-акт',
                              style: TextStyle(fontSize: 12)),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _downloadAct(String contractId) async {
    // Используем выбранный пользователем период, если он есть
    await _downloadActWithPeriod(
      contractId,
      _dateFrom,
      _dateTo,
    );
  }

  Future<void> _downloadExcelAct(BuildContext context) async {
    if (_selectedContractId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Выберите контракт для выгрузки Excel-акта'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Показываем индикатор загрузки
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final authState = ref.read(authNotifierProvider);
      final token = await TokenStorage.getAccessToken();
      final userRole = userRoleFromString(authState.user?.role);
      
      // Определяем mode в зависимости от роли пользователя
      final mode = userRole == UserRole.contractorAdmin ? 'contractor' : 'landfill';
      
      final response = await http.post(
        Uri.parse('https://snowops-acts-service.onrender.com/acts/export'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'mode': mode,
          'target_id': _selectedContractId!,
          'period_start': _dateFrom != null 
              ? '${_dateFrom!.year.toString().padLeft(4, '0')}-${_dateFrom!.month.toString().padLeft(2, '0')}-${_dateFrom!.day.toString().padLeft(2, '0')}'
              : null,
          'period_end': _dateTo != null
              ? '${_dateTo!.year.toString().padLeft(4, '0')}-${_dateTo!.month.toString().padLeft(2, '0')}-${_dateTo!.day.toString().padLeft(2, '0')}'
              : null,
        }),
      );

      // Закрываем индикатор загрузки
      Navigator.of(context).pop();

      if (response.statusCode == 200) {
        // Для Web используем blob и download
        if (kIsWeb) {
          final bytes = response.bodyBytes;
          final filename = 'acts_${_selectedContractId}_${DateFormat('dd.MM.yyyy').format(DateTime.now())}.xlsx';
          
          // Создаем blob и скачиваем через браузер
          final blob = html.Blob([bytes]);
          final url = html.Url.createObjectUrl(blob);
          final anchor = html.AnchorElement(href: url)
            ..setAttribute('download', filename)
            ..click();
          html.Url.revokeObjectUrl(url);
        } else {
          // Для мобильных платформ сохраняем файл
          final bytes = response.bodyBytes;
          final filename = 'acts_${_selectedContractId}_${DateFormat('dd.MM.yyyy').format(DateTime.now())}.xlsx';
          await FileDownloader.downloadFile(
            bytes: bytes,
            filename: filename,
            extension: 'xlsx',
          );
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Excel-акт успешно загружен'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      // Закрываем индикатор загрузки если открыт
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при выгрузке Excel-акта: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Скачивание акта с валидацией периода относительно контракта
  Future<void> _downloadActWithValidation(
      String contractId, DashboardContract contract) async {
    if (_dateFrom == null || _dateTo == null) {
      // Если период не выбран, используем период контракта
      await _downloadActWithPeriod(contractId, null, null);
      return;
    }

    DateTime? validatedStart = _dateFrom;
    DateTime? validatedEnd = _dateTo;
    bool periodAdjusted = false;
    String? adjustmentMessage;

    // Если у контракта есть даты, проверяем и корректируем период
    if (contract.startAt != null && contract.endAt != null) {
      final contractStart = contract.startAt!;
      final contractEnd = contract.endAt!;

      // Нормализуем даты (убираем время)
      final contractStartDate =
          DateTime(contractStart.year, contractStart.month, contractStart.day);
      final contractEndDate =
          DateTime(contractEnd.year, contractEnd.month, contractEnd.day);
      final selectedStartDate =
          DateTime(_dateFrom!.year, _dateFrom!.month, _dateFrom!.day);
      final selectedEndDate =
          DateTime(_dateTo!.year, _dateTo!.month, _dateTo!.day);

      // Проверяем начало периода
      if (selectedStartDate.isBefore(contractStartDate)) {
        validatedStart = contractStartDate;
        periodAdjusted = true;
        adjustmentMessage =
            'Начало периода скорректировано до даты начала контракта (${DateFormat('dd.MM.yyyy').format(contractStartDate)})';
      }

      // Проверяем конец периода
      if (selectedEndDate.isAfter(contractEndDate)) {
        validatedEnd = contractEndDate;
        periodAdjusted = true;
        if (adjustmentMessage != null) {
          adjustmentMessage =
              'Период скорректирован до периода действия контракта (${DateFormat('dd.MM.yyyy').format(contractStartDate)} - ${DateFormat('dd.MM.yyyy').format(contractEndDate)})';
        } else {
          adjustmentMessage =
              'Конец периода скорректирован до даты окончания контракта (${DateFormat('dd.MM.yyyy').format(contractEndDate)})';
        }
      }

      // Если период полностью вне контракта, используем период контракта
      if (selectedEndDate.isBefore(contractStartDate) ||
          selectedStartDate.isAfter(contractEndDate)) {
        validatedStart = null; // Бэкенд использует start_at контракта
        validatedEnd = null; // Бэкенд использует end_at контракта
        periodAdjusted = true;
        adjustmentMessage =
            'Выбранный период полностью вне действия контракта. Будет использован период действия контракта (${DateFormat('dd.MM.yyyy').format(contractStartDate)} - ${DateFormat('dd.MM.yyyy').format(contractEndDate)})';
      }
    }

    // Показываем сообщение, если период был скорректирован
    if (periodAdjusted && adjustmentMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(adjustmentMessage),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 5),
        ),
      );
    }

    // Скачиваем акт с валидированным периодом
    await _downloadActWithPeriod(contractId, validatedStart, validatedEnd);
  }

  Future<void> _downloadActWithPeriod(
    String contractId,
    DateTime? periodStart,
    DateTime? periodEnd,
  ) async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Text('Генерация акта...'),
              ],
            ),
            duration: Duration(seconds: 30),
          ),
        );
      }

      final actsCollection = ref.read(actsCollectionProvider);
      final pdfBytes = await actsCollection.generateActPdf(
        contractId: contractId,
        periodStart: periodStart,
        periodEnd: periodEnd,
      );

      // Формируем имя файла
      final dateFormat = DateFormat('yyyyMMdd');
      final periodStr = periodStart != null && periodEnd != null
          ? '${dateFormat.format(periodStart)}-${dateFormat.format(periodEnd)}'
          : 'contract-period';
      final filename = 'akt-${contractId.substring(0, 8)}-$periodStr';

      // Скачиваем файл
      await FileDownloader.downloadFile(
        bytes: pdfBytes,
        filename: filename,
        extension: 'pdf',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Акт успешно скачан'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error downloading act: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        // Парсим сообщение об ошибке для более понятного отображения
        String errorMessage = e.toString();
        String userFriendlyMessage = errorMessage;

        // Обработка ошибки 422 - нет рейсов для выбранного периода
        if (errorMessage.contains('no trips') ||
            errorMessage.contains('422') ||
            errorMessage.contains('Unprocessable')) {
          final periodStr = periodStart != null && periodEnd != null
              ? '${DateFormat('dd.MM.yyyy').format(periodStart!)} - ${DateFormat('dd.MM.yyyy').format(periodEnd!)}'
              : 'выбранного периода';

          userFriendlyMessage = 'Нет рейсов для генерации акта\n\n'
              'Для выбранного контракта и периода ($periodStr) не найдено рейсов со статусом "OK".\n\n'
              'Возможные причины:\n'
              '• В выбранном периоде нет выполненных рейсов\n'
              '• Все рейсы имеют статус, отличный от "OK"\n'
              '• Рейсы уже включены в другие акты\n\n'
              'Попробуйте:\n'
              '• Выбрать другой период\n'
              '• Проверить наличие рейсов в разделе "Рейсы"';
        }
        // Проверяем, содержит ли ошибка информацию о датах контракта
        else if (errorMessage.contains('period_start') &&
            errorMessage.contains('contract start date')) {
          // Извлекаем даты из сообщения об ошибке
          final startDateMatch =
              RegExp(r'period_start \(([^)]+)\)').firstMatch(errorMessage);
          final contractStartMatch = RegExp(r'contract start date \(([^)]+)\)')
              .firstMatch(errorMessage);

          if (startDateMatch != null && contractStartMatch != null) {
            userFriendlyMessage =
                'Период начала (${startDateMatch.group(1)}) раньше даты начала контракта (${contractStartMatch.group(1)}).\n\n'
                'Пожалуйста, выберите период в пределах действия контракта.';
          } else {
            userFriendlyMessage =
                'Выбранный период выходит за пределы действия контракта.\n\n'
                'Пожалуйста, выберите период в пределах дат контракта.';
          }
        } else if (errorMessage.contains('period_end') &&
            errorMessage.contains('contract end date')) {
          final endDateMatch =
              RegExp(r'period_end \(([^)]+)\)').firstMatch(errorMessage);
          final contractEndMatch =
              RegExp(r'contract end date \(([^)]+)\)').firstMatch(errorMessage);

          if (endDateMatch != null && contractEndMatch != null) {
            userFriendlyMessage =
                'Период окончания (${endDateMatch.group(1)}) позже даты окончания контракта (${contractEndMatch.group(1)}).\n\n'
                'Пожалуйста, выберите период в пределах действия контракта.';
          } else {
            userFriendlyMessage =
                'Выбранный период выходит за пределы действия контракта.\n\n'
                'Пожалуйста, выберите период в пределах дат контракта.';
          }
        } else if (errorMessage.contains('invalid input') ||
            errorMessage.contains('period')) {
          userFriendlyMessage = 'Некорректный период для генерации акта.\n\n'
              'Убедитесь, что выбранный период находится в пределах действия контракта.';
        }

        // Для ошибки 422 (нет рейсов) показываем AlertDialog с подробным объяснением
        if (errorMessage.contains('no trips') ||
            errorMessage.contains('422') ||
            errorMessage.contains('Unprocessable')) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange, size: 24),
                  const SizedBox(width: 8),
                  const Text('Нет рейсов для генерации акта'),
                ],
              ),
              content: SingleChildScrollView(
                child: Text(userFriendlyMessage),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Понятно'),
                ),
              ],
            ),
          );
        } else {
          // Для других ошибок показываем SnackBar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(userFriendlyMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 8),
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }
      }
    }
  }

  Widget _buildCameraCard(DashboardCamera camera) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(AppPadding.normal),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple.withOpacity(0.15),
            Colors.purple.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.purple.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.videocam,
                size: 16,
                color: Colors.purple,
              ),
              const SizedBox(width: 8),
              Text(
                'Камера: ${camera.cameraId.substring(0, 12)}...',
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (camera.lprEvents != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'LPR: ${camera.lprEvents}',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.purple.shade700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMapSection(DashboardMap mapData) {
    final center = const LatLng(51.1694, 71.4491); // Алматы

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
            opacity: value,
            child: Transform.scale(
              scale: 0.95 + (value * 0.05),
              child: Container(
                height: 400,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSize.cardRadius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08 * value),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSize.cardRadius),
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: center,
                      initialZoom: 11.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.akimat.project',
                      ),
                      // Участки
                      if (mapData.areas.isNotEmpty)
                        PolygonLayer(
                          polygons: mapData.areas.map((area) {
                            final color = area.hasTrips
                                ? (area.intensity != null &&
                                        area.intensity! > 0.5
                                    ? Colors.green
                                    : Colors.blue)
                                : Colors.grey;
                            // TODO: Парсить GeoJSON из area.id или использовать координаты
                            // Пока используем заглушку
                            return Polygon(
                              points: [
                                center,
                                LatLng(
                                    center.latitude + 0.01, center.longitude),
                                LatLng(center.latitude + 0.01,
                                    center.longitude + 0.01),
                                LatLng(
                                    center.latitude, center.longitude + 0.01),
                              ],
                              color: color.withOpacity(0.3),
                              borderColor: color,
                              borderStrokeWidth: 2,
                              // isFilled: true,
                            );
                          }).toList(),
                        ),
                      // Полигоны
                      if (mapData.polygons.isNotEmpty)
                        PolygonLayer(
                          polygons: mapData.polygons.map((polygon) {
                            // TODO: Парсить GeoJSON
                            return Polygon(
                              points: [
                                LatLng(center.latitude + 0.02,
                                    center.longitude + 0.02),
                                LatLng(center.latitude + 0.02,
                                    center.longitude + 0.03),
                                LatLng(center.latitude + 0.03,
                                    center.longitude + 0.03),
                                LatLng(center.latitude + 0.03,
                                    center.longitude + 0.02),
                              ],
                              color: Colors.orange.withOpacity(0.3),
                              borderColor: Colors.orange,
                              borderStrokeWidth: 2,
                              // isFilled: true,
                            );
                          }).toList(),
                        ),
                      // Камеры с ошибками
                      if (mapData.cameras.isNotEmpty)
                        MarkerLayer(
                          markers: mapData.cameras
                              .where((c) => (c.errorEvents ?? 0) > 0)
                              .map((camera) {
                            return Marker(
                              point: LatLng(
                                center.latitude +
                                    (mapData.cameras.indexOf(camera) * 0.005),
                                center.longitude +
                                    (mapData.cameras.indexOf(camera) * 0.005),
                              ),
                              width: 30,
                              height: 30,
                              child: const Icon(
                                Icons.videocam,
                                color: Colors.red,
                                size: 30,
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ),
            ));
      },
    );
  }
}
