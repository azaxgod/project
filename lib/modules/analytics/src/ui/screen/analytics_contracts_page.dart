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
import 'package:akimat_project/modules/auth/src/controller/auth_notifier.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/user_role.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_data_table.dart';
import 'package:akimat_project/services/acts/module.dart';
import 'package:akimat_project/services/analytics/model/analytics_response.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class AnalyticsContractsPage extends ConsumerStatefulWidget {
  const AnalyticsContractsPage({
    super.key,
    required this.scaffoldKey,
    this.webNavbarWidgets,
    this.mobileNavbarWidgets,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;
  final List<Widget>? webNavbarWidgets;
  final List<Widget>? mobileNavbarWidgets;

  @override
  ConsumerState<AnalyticsContractsPage> createState() => _AnalyticsContractsPageState();
}

class _AnalyticsContractsPageState extends ConsumerState<AnalyticsContractsPage> {
  DateTime? _dateFrom;
  DateTime? _dateTo;
  String? _selectedContractId;

  @override
  void initState() {
    super.initState();
    // Устанавливаем диапазон по умолчанию (последний месяц)
    final now = DateTime.now();
    _dateTo = now;
    _dateFrom = DateTime(now.year, now.month, 1); // Первый день текущего месяца
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsControllerProvider.notifier).loadContractsAnalytics(
        from: _dateFrom,
        to: _dateTo,
      );
    });
  }

  /// Проверяет, может ли пользователь генерировать акты
  bool _canGenerateActs(UserRole role) {
    return role == UserRole.akimatAdmin ||
        role == UserRole.kguZkhAdmin ||
        role == UserRole.contractorAdmin;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final state = ref.watch(analyticsControllerProvider);
    final controller = ref.read(analyticsControllerProvider.notifier);
    final config = PlatformConfig.instance;

    return Scaffold(
      key: widget.scaffoldKey,
      drawer: !kIsWeb ? const DrawerMobile() : null,
      appBar: kIsWeb
          ? null
          : AppBar(
              title: const Text('Аналитика контрактов'),
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
            child: state.contractsAnalytics?.when(
              data: (data) => _buildContent(data, controller, config),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Ошибка загрузки данных: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => controller.loadContractsAnalytics(),
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
    ContractsAnalyticsResponse data,
    AnalyticsController controller,
    PlatformConfig config,
  ) {
    final authState = ref.watch(authNotifierProvider);
    final userRole = userRoleFromString(authState.user?.role);
    final canGenerateActs = _canGenerateActs(userRole);

    return SingleChildScrollView(
      padding: EdgeInsets.all(config.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Фильтры
          if (canGenerateActs)
            _buildFilters(),
          
          if (canGenerateActs)
            const SizedBox(height: AppPadding.large),
          
          // Основная таблица контрактов
          if (data.data.summary.isNotEmpty)
            _buildContractsTable(
              data.data.summary,
              'Все контракты',
              canGenerateActs: canGenerateActs,
            ),
          
          const SizedBox(height: AppPadding.large),
          
          // Топ по бюджету
          if (data.data.topBudget.isNotEmpty)
            _buildContractsTable(
              data.data.topBudget,
              'Топ контрактов по освоению бюджета',
              canGenerateActs: canGenerateActs,
            ),
          
          const SizedBox(height: AppPadding.large),
          
          // Контракты с риском
          if (data.data.atRisk.isNotEmpty)
            _buildContractsTable(
              data.data.atRisk,
              'Контракты с риском провала',
              isRisk: true,
              canGenerateActs: canGenerateActs,
            ),
          
          const SizedBox(height: AppPadding.large),
          
          // Контракты с превышением бюджета
          if (data.data.budgetIssues.isNotEmpty)
            _buildContractsTable(
              data.data.budgetIssues,
              'Контракты с превышением бюджета',
              isOverBudget: true,
              canGenerateActs: canGenerateActs,
            ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final state = ref.watch(analyticsControllerProvider);
    final contractsData = state.contractsAnalytics?.valueOrNull;
    
    // Собираем все уникальные контракты из всех таблиц
    final allContracts = <ContractSummary>{};
    if (contractsData != null) {
      allContracts.addAll(contractsData.data.summary);
      allContracts.addAll(contractsData.data.topBudget);
      allContracts.addAll(contractsData.data.atRisk);
      allContracts.addAll(contractsData.data.budgetIssues);
    }
    final uniqueContracts = allContracts.toList();
    
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
          Text('Фильтры для генерации акта', style: AppTextStyles.title2),
          const SizedBox(height: AppPadding.normal),
          Wrap(
            spacing: AppPadding.normal,
            runSpacing: AppPadding.small,
            children: [
              // Выбор контракта
              SizedBox(
                width: kIsWeb ? 300 : double.infinity,
                child: DropdownButtonFormField<String>(
                  value: _selectedContractId,
                  decoration: InputDecoration(
                    labelText: 'Контракт',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSize.smallRadius),
                    ),
                    isDense: true,
                  ),
                  hint: const Text('Выберите контракт'),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Все контракты'),
                    ),
                    ...uniqueContracts.map((contract) {
                      final displayName = contract.contractorName != null
                          ? '${contract.contractId.substring(0, 8)} (${contract.contractorName})'
                          : contract.contractId.substring(0, 8);
                      return DropdownMenuItem<String>(
                        value: contract.contractId,
                        child: Text(displayName),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedContractId = value;
                    });
                  },
                ),
              ),
              // Период работ
              SizedBox(
                width: kIsWeb ? 300 : double.infinity,
                child: CustomDateRangePicker(
                  label: 'Период работ',
                  initialStartDate: _dateFrom,
                  initialEndDate: _dateTo,
                  onDateRangeSelected: (start, end) {
                    setState(() {
                      _dateFrom = start;
                      _dateTo = end;
                    });
                    // Перезагружаем данные при изменении даты
                    if (start != null && end != null) {
                      ref.read(analyticsControllerProvider.notifier).loadContractsAnalytics(
                        from: start,
                        to: end,
                      );
                    }
                  },
                ),
              ),
              // Кнопка скачать акт
              if (kIsWeb)
                SizedBox(
                  width: 200,
                  child: ElevatedButton.icon(
                    onPressed: _selectedContractId != null &&
                            _dateFrom != null &&
                            _dateTo != null
                        ? () => _downloadAct(_selectedContractId!)
                        : null,
                    icon: const Icon(Icons.download, size: 20),
                    label: const Text('Скачать акт (PDF)'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppPadding.normal,
                        vertical: AppPadding.normal,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          // Кнопка для мобильных устройств
          if (!kIsWeb) ...[
            const SizedBox(height: AppPadding.normal),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selectedContractId != null &&
                        _dateFrom != null &&
                        _dateTo != null
                    ? () => _downloadAct(_selectedContractId!)
                    : null,
                icon: const Icon(Icons.download, size: 20),
                label: const Text('Скачать акт (PDF)'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppPadding.normal,
                    vertical: AppPadding.normal,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContractsTable(
    List<ContractSummary> contracts,
    String title, {
    bool isRisk = false,
    bool isOverBudget = false,
    bool canGenerateActs = false,
  }) {
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
          Text(title, style: AppTextStyles.title2),
          const SizedBox(height: AppPadding.normal),
          OrganizationsDataTable(
            columns: [
              const DataColumn(label: Text('Контракт')),
              const DataColumn(label: Text('Подрядчик')),
              const DataColumn(label: Text('Статус')),
              const DataColumn(label: Text('Результат')),
              const DataColumn(label: Text('Бюджет')),
              const DataColumn(label: Text('Объём')),
              const DataColumn(label: Text('Превышен бюджет')),
              if (canGenerateActs)
                const DataColumn(label: Text('Действия')),
            ],
            rows: contracts.map((contract) {
              final budgetProgress = contract.budgetProgress ?? 0.0;
              final volumeProgress = contract.volumeProgress ?? 0.0;
              
              final cells = [
                DataCell(
                  SizedBox(
                    width: 150,
                    child: Text(
                      contract.contractId.substring(0, 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(Text(contract.contractorName ?? '—')),
                DataCell(_buildStatusChip(contract.uiStatus ?? 'NONE')),
                DataCell(_buildResultChip(contract.result ?? 'NONE')),
                DataCell(
                  _buildProgressBar(
                    budgetProgress,
                    '${(budgetProgress * 100).toStringAsFixed(1)}%',
                  ),
                ),
                DataCell(
                  _buildProgressBar(
                    volumeProgress,
                    '${(volumeProgress * 100).toStringAsFixed(1)}%',
                  ),
                ),
                DataCell(
                  contract.isOverBudget == true
                      ? const Icon(Icons.warning, color: Colors.red, size: 20)
                      : const Icon(Icons.check, color: Colors.green, size: 20),
                ),
              ];

              if (canGenerateActs) {
                cells.add(
                  DataCell(
                    _buildDownloadActButton(contract.contractId),
                  ),
                );
              }

              return DataRow(cells: cells);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadActButton(String contractId) {
    final hasPeriod = _dateFrom != null && _dateTo != null;
    return Tooltip(
      message: hasPeriod 
          ? 'Скачать акт (PDF) для этого контракта'
          : 'Выберите период в фильтрах выше для генерации акта',
      child: FilledButton.icon(
        onPressed: hasPeriod
            ? () => _downloadAct(contractId)
            : () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Сначала выберите период работ в фильтрах выше'),
                    backgroundColor: Colors.orange,
                    duration: Duration(seconds: 3),
                  ),
                );
              },
        icon: const Icon(Icons.download, size: 18),
        label: const Text('Акт (PDF)', style: TextStyle(fontSize: 12)),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          minimumSize: const Size(0, 32),
        ),
      ),
    );
  }

  Future<void> _downloadAct(String contractId) async {
    // Если период не выбран, бэкенд использует период действия контракта
    if (_dateFrom == null || _dateTo == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Период не выбран. Будет использован период действия контракта'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }

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
        periodStart: _dateFrom, // Может быть null - бэкенд использует start_at контракта
        periodEnd: _dateTo, // Может быть null - бэкенд использует end_at контракта
      );

      // Формируем имя файла
      final dateFormat = DateFormat('yyyyMMdd');
      final periodStr = _dateFrom != null && _dateTo != null
          ? '${dateFormat.format(_dateFrom!)}-${dateFormat.format(_dateTo!)}'
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
        if (errorMessage.contains('no trips') || errorMessage.contains('422') || errorMessage.contains('Unprocessable')) {
          final periodStr = _dateFrom != null && _dateTo != null
              ? '${DateFormat('dd.MM.yyyy').format(_dateFrom!)} - ${DateFormat('dd.MM.yyyy').format(_dateTo!)}'
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
        else if (errorMessage.contains('period_start') && errorMessage.contains('contract start date')) {
          // Извлекаем даты из сообщения об ошибке
          final startDateMatch = RegExp(r'period_start \(([^)]+)\)').firstMatch(errorMessage);
          final contractStartMatch = RegExp(r'contract start date \(([^)]+)\)').firstMatch(errorMessage);
          
          if (startDateMatch != null && contractStartMatch != null) {
            userFriendlyMessage = 'Период начала (${startDateMatch.group(1)}) раньше даты начала контракта (${contractStartMatch.group(1)}).\n\n'
                'Пожалуйста, выберите период в пределах действия контракта.';
          } else {
            userFriendlyMessage = 'Выбранный период выходит за пределы действия контракта.\n\n'
                'Пожалуйста, выберите период в пределах дат контракта.';
          }
        } else if (errorMessage.contains('period_end') && errorMessage.contains('contract end date')) {
          final endDateMatch = RegExp(r'period_end \(([^)]+)\)').firstMatch(errorMessage);
          final contractEndMatch = RegExp(r'contract end date \(([^)]+)\)').firstMatch(errorMessage);
          
          if (endDateMatch != null && contractEndMatch != null) {
            userFriendlyMessage = 'Период окончания (${endDateMatch.group(1)}) позже даты окончания контракта (${contractEndMatch.group(1)}).\n\n'
                'Пожалуйста, выберите период в пределах действия контракта.';
          } else {
            userFriendlyMessage = 'Выбранный период выходит за пределы действия контракта.\n\n'
                'Пожалуйста, выберите период в пределах дат контракта.';
          }
        } else if (errorMessage.contains('invalid input') || errorMessage.contains('period')) {
          userFriendlyMessage = 'Некорректный период для генерации акта.\n\n'
              'Убедитесь, что выбранный период находится в пределах действия контракта.';
        }
        
        // Для ошибки 422 (нет рейсов) показываем AlertDialog с подробным объяснением
        if (errorMessage.contains('no trips') || errorMessage.contains('422') || errorMessage.contains('Unprocessable')) {
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

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    
    switch (status.toUpperCase()) {
      case 'PLANNED':
        color = Colors.blue;
        label = 'Запланирован';
        break;
      case 'ACTIVE':
        color = Colors.green;
        label = 'Активен';
        break;
      case 'EXPIRED':
        color = Colors.orange;
        label = 'Истёк';
        break;
      case 'ARCHIVED':
        color = Colors.grey;
        label = 'Архив';
        break;
      default:
        color = Colors.grey;
        label = status;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildResultChip(String result) {
    Color color;
    String label;
    
    switch (result.toUpperCase()) {
      case 'SUCCESS':
        color = Colors.green;
        label = 'Успех';
        break;
      case 'FAIL':
        color = Colors.red;
        label = 'Провал';
        break;
      default:
        color = Colors.grey;
        label = '—';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildProgressBar(double progress, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          minHeight: 8,
          backgroundColor: AppColors.secondaryBackground,
          valueColor: AlwaysStoppedAnimation<Color>(
            progress > 1.0 ? Colors.red : (progress > 0.8 ? Colors.orange : Colors.green),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.caption,
        ),
      ],
    );
  }
}
