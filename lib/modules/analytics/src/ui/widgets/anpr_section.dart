import 'dart:math';

import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/core/ui/app_textstyle.dart';
import 'package:akimat_project/core/ui/widgets/date_range_picker.dart';
import 'package:akimat_project/core/ui/widgets/safe_dropdown_button.dart';
import 'package:akimat_project/modules/analytics/src/controller/analytics_providers.dart';
import 'package:akimat_project/modules/analytics/src/ui/widgets/animated_kpi_card.dart';
import 'package:akimat_project/modules/analytics/src/ui/widgets/animated_section.dart';
import 'package:akimat_project/modules/dashboard/src/controller/organizations_controller.dart';
import 'package:akimat_project/modules/dashboard/src/controller/organizations_state.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/organization_type.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/vehicle.dart';
import 'package:akimat_project/services/anpr/model/anpr_report.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:akimat_project/l10n/l10n.dart';
import 'package:intl/intl.dart';

const String _polygonShahovskoe = 'Шаховское';
const String _polygonYakor = 'Якорь';
const String _polygonSolnechniy = 'Солнечный';

const List<String> _availablePolygonNames = [
  _polygonShahovskoe,
  _polygonYakor,
  _polygonSolnechniy,
];

const Map<String, String> _polygonAliases = {
  'shahovskoye': _polygonShahovskoe,
  'shahovskoe': _polygonShahovskoe,
  'camera-001': _polygonShahovskoe,
  'camera001': _polygonShahovskoe,
  'шаховское': _polygonShahovskoe,
  'yakor': _polygonYakor,
  'camera-002': _polygonYakor,
  'camera002': _polygonYakor,
  'якорь': _polygonYakor,
  'solnechniy': _polygonSolnechniy,
  'solnechny': _polygonSolnechniy,
  'camera-003': _polygonSolnechniy,
  'camera003': _polygonSolnechniy,
  'солнечный': _polygonSolnechniy,
};

String _normalizePolygonAlias(String? value) {
  final normalized = value?.trim().toLowerCase() ?? '';
  if (normalized.isEmpty) return '';
  return normalized.replaceAll('_', '-').replaceAll(' ', '');
}

String? _resolvePolygonFilterValue(String? value) {
  final normalized = _normalizePolygonAlias(value);
  if (normalized.isEmpty) return null;

  final alias = _polygonAliases[normalized];
  if (alias != null) {
    return alias;
  }

  for (final polygonName in _availablePolygonNames) {
    if (_normalizePolygonAlias(polygonName) == normalized) {
      return polygonName;
    }
  }

  return null;
}

String _normalizePlate(String value) => value.replaceAll(' ', '').toUpperCase();

String _polygonName({
  required String? cameraId,
  String? polygonId,
}) {
  final fromCamera = _resolvePolygonFilterValue(cameraId);
  if (fromCamera != null) {
    return fromCamera;
  }

  final fromPolygonId = _resolvePolygonFilterValue(polygonId);
  if (fromPolygonId != null) {
    return fromPolygonId;
  }

  return '—';
}

class AnprSection extends ConsumerStatefulWidget {
  const AnprSection({
    super.key,
    this.dateFrom,
    this.dateTo,
    this.contractorId,
    this.polygonId,
    this.vehicleId,
    this.plate,
  });

  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? contractorId;
  final String? polygonId;
  final String? vehicleId;
  final String? plate;

  @override
  ConsumerState<AnprSection> createState() => _AnprSectionState();
}

class _AnprSectionState extends ConsumerState<AnprSection> {
  DateTime? _dateFrom;
  DateTime? _dateTo;
  String? _selectedContractorId;
  String? _selectedPolygonName;
  int _currentPage = 1;

  static const int _rowsPerPage = 20;

  @override
  void initState() {
    super.initState();
    _dateFrom = widget.dateFrom;
    _dateTo = widget.dateTo;
    _selectedContractorId = widget.contractorId;
    _selectedPolygonName = _resolvePolygonFilterValue(widget.polygonId);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadReports();
    });
  }

  @override
  void didUpdateWidget(covariant AnprSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final paramsChanged = oldWidget.dateFrom != widget.dateFrom ||
        oldWidget.dateTo != widget.dateTo ||
        oldWidget.contractorId != widget.contractorId ||
        oldWidget.polygonId != widget.polygonId ||
        oldWidget.vehicleId != widget.vehicleId ||
        oldWidget.plate != widget.plate;

    if (!paramsChanged) return;

    _dateFrom = widget.dateFrom;
    _dateTo = widget.dateTo;
    _selectedContractorId = widget.contractorId;
    _selectedPolygonName = _resolvePolygonFilterValue(widget.polygonId);
    _currentPage = 1;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadReports();
    });
  }

  DateTime get _effectiveFrom =>
      _dateFrom ?? DateTime.now().subtract(const Duration(hours: 24));
  DateTime get _effectiveTo => _dateTo ?? DateTime.now();

  void _loadReports() {
    ref.read(anprControllerProvider.notifier).loadReports(
          from: _effectiveFrom,
          to: _effectiveTo,
          contractorId: _selectedContractorId,
          // Для camera_id фильтруем на клиенте (полигон в отчетах приходит как camera_id)
          polygonId: null,
          vehicleId: widget.vehicleId,
          plate: widget.plate,
          minVolume: 0.01,
          limit: 1000,
        );
  }

  void _resetFilters() {
    setState(() {
      _dateFrom = widget.dateFrom;
      _dateTo = widget.dateTo;
      _selectedContractorId = widget.contractorId;
      _selectedPolygonName = _resolvePolygonFilterValue(widget.polygonId);
      _currentPage = 1;
    });
    _loadReports();
  }

  Future<void> _handleDownloadExcel() async {
    final s = S.of(context)!;
    final controller = ref.read(anprControllerProvider.notifier);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Text(s.loading),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );

    try {
      await controller.downloadExcelReport(
        from: _effectiveFrom,
        to: _effectiveTo,
        contractorId: _selectedContractorId,
        polygonId: null, // Имя полигона не UUID
        vehicleId: widget.vehicleId,
        plate: widget.plate,
        minVolume: 0.01, // Фильтруем записи без объема
      );

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Отчет успешно скачан'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при скачивании отчета: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final anprState = ref.watch(anprControllerProvider);
    final organizationsState = ref.watch(organizationsControllerProvider);
    final organizationsData = organizationsState.data.valueOrNull;
    final reportsData = anprState.reports?.valueOrNull;

    final contractors = organizationsData?.organizations
            .where(
              (org) => org.type == OrganizationType.contractor && org.isActive,
            )
            .toList() ??
        [];

    final availablePolygonNames = _availablePolygonNames;

    final selectedContractorId = contractors.any(
      (contractor) => contractor.id == _selectedContractorId,
    )
        ? _selectedContractorId
        : null;
    final selectedPolygonName = availablePolygonNames.contains(
      _selectedPolygonName,
    )
        ? _selectedPolygonName
        : null;

    final hasActiveFilters = selectedContractorId != null ||
        selectedPolygonName != null ||
        _dateFrom != widget.dateFrom ||
        _dateTo != widget.dateTo;

    return AnimatedSection(
      title: 'Отчеты по объему снега и поездкам',
      icon: Icons.assessment,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppPadding.normal),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(AppSize.cardRadius),
              border: Border.all(color: AppColors.divider, width: 0.6),
            ),
            child: Wrap(
              spacing: AppPadding.normal,
              runSpacing: AppPadding.small,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: kIsWeb ? 420 : double.infinity,
                  child: CustomDateRangePicker(
                    key: ValueKey(
                      'reports_period_${_dateFrom?.millisecondsSinceEpoch}_${_dateTo?.millisecondsSinceEpoch}',
                    ),
                    label: 'Период аналитики',
                    initialStartDate: _dateFrom,
                    initialEndDate: _dateTo,
                    onDateRangeSelected: (start, end) {
                      setState(() {
                        _dateFrom = start;
                        _dateTo = end;
                        _currentPage = 1;
                      });
                      _loadReports();
                    },
                  ),
                ),
                SizedBox(
                  width: kIsWeb ? 320 : double.infinity,
                  child: SafeDropdownButtonFormField<String?>(
                    value: selectedContractorId,
                    decoration: InputDecoration(
                      labelText: 'Подрядчик',
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSize.smallRadius),
                      ),
                      isDense: true,
                      prefixIcon: const Icon(Icons.business),
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
                        _currentPage = 1;
                      });
                      _loadReports();
                    },
                  ),
                ),
                SizedBox(
                  width: kIsWeb ? 280 : double.infinity,
                  child: SafeDropdownButtonFormField<String?>(
                    value: selectedPolygonName,
                    decoration: InputDecoration(
                      labelText: 'Полигон',
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSize.smallRadius),
                      ),
                      isDense: true,
                      prefixIcon: const Icon(Icons.location_on),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Все полигоны'),
                      ),
                      ...availablePolygonNames.map((polygonName) {
                        return DropdownMenuItem<String?>(
                          value: polygonName,
                          child: Text(polygonName),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedPolygonName = value;
                        _currentPage = 1;
                      });
                    },
                  ),
                ),
                IconButton(
                  onPressed: _loadReports,
                  tooltip: 'Обновить',
                  icon: const Icon(Icons.refresh),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSize.smallRadius),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.file_download_outlined,
                        color: AppColors.primary),
                    tooltip: S.of(context)!.download_excel,
                    onPressed: _handleDownloadExcel,
                  ),
                ),
                if (hasActiveFilters)
                  OutlinedButton.icon(
                    onPressed: _resetFilters,
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('Сбросить'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppPadding.large),
          if (anprState.reports?.isLoading ?? false)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppPadding.large),
                child: CircularProgressIndicator(),
              ),
            )
          else if (anprState.reports?.hasError ?? false)
            _buildErrorState(
              anprState.reports?.error?.toString() ??
                  'Ошибка загрузки данных отчетов',
            )
          else if (reportsData == null)
            _buildEmptyState('Нет данных отчетов за выбранный период')
          else
            _buildReportsBody(
              reportsData,
              organizationsData,
              selectedContractorId: selectedContractorId,
              selectedPolygonName: selectedPolygonName,
            ),
        ],
      ),
    );
  }

  Widget _buildReportsBody(
    AnprReportData reportData,
    OrganizationsData? organizationsData, {
    required String? selectedContractorId,
    required String? selectedPolygonName,
  }) {
    var filteredEvents = reportData.events;

    if (selectedContractorId != null) {
      filteredEvents = filteredEvents.where((event) {
        return _resolveContractorId(event, organizationsData) ==
            selectedContractorId;
      }).toList();
    }

    if (selectedPolygonName != null) {
      filteredEvents = filteredEvents.where((event) {
        return _polygonName(
              cameraId: event.cameraId,
              polygonId: event.polygonId,
            ) ==
            selectedPolygonName;
      }).toList();
    }

    final totalTrips = filteredEvents.length;
    final totalVolume = filteredEvents.fold<double>(
      0,
      (sum, event) => sum + max(0, event.snowVolumeM3 ?? 0),
    );

    final totalPages = filteredEvents.isEmpty
        ? 1
        : (filteredEvents.length / _rowsPerPage).ceil();
    final safePage = _currentPage.clamp(1, totalPages).toInt();

    if (safePage != _currentPage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _currentPage = safePage;
        });
      });
    }

    final startIndex =
        filteredEvents.isEmpty ? 0 : (safePage - 1) * _rowsPerPage;
    final endIndex = filteredEvents.isEmpty
        ? 0
        : min(startIndex + _rowsPerPage, filteredEvents.length);
    final pagedEvents = filteredEvents.isEmpty
        ? <AnprReportEvent>[]
        : filteredEvents.sublist(startIndex, endIndex);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: AnimatedKPICard(
                title: 'Всего поездок',
                value: totalTrips.toString(),
                icon: Icons.directions_car,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppPadding.normal),
            Expanded(
              child: AnimatedKPICard(
                title: 'Общий объем снега',
                value: '${totalVolume.toStringAsFixed(1)} м³',
                icon: Icons.snowing,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppPadding.large),
        if (filteredEvents.isEmpty)
          _buildEmptyState('Нет событий с объемом снега за выбранный период')
        else ...[
          _buildReportsTable(
            events: pagedEvents,
            organizationsData: organizationsData,
            rowStartIndex: startIndex,
          ),
          const SizedBox(height: AppPadding.normal),
          _buildPagination(
            currentPage: safePage,
            totalPages: totalPages,
            startIndex: startIndex,
            endIndex: endIndex,
            totalCount: filteredEvents.length,
          ),
        ],
      ],
    );
  }

  Widget _buildReportsTable({
    required List<AnprReportEvent> events,
    required OrganizationsData? organizationsData,
    required int rowStartIndex,
  }) {
    final dateOnlyFormat = DateFormat('dd.MM.yyyy');
    final timeOnlyFormat = DateFormat('HH:mm');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSize.cardRadius),
        border: Border.all(color: AppColors.divider, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSize.cardRadius),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
              dataTableTheme: DataTableThemeData(
                headingRowColor: WidgetStateProperty.all(
                  AppColors.primary.withOpacity(0.08),
                ),
                headingTextStyle: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
                dataTextStyle: AppTextStyles.body.copyWith(
                  color: AppColors.textPrimary,
                ),
                headingRowHeight: 56,
                dataRowMinHeight: 64,
                dataRowMaxHeight: 72,
              ),
            ),
            child: DataTable(
              horizontalMargin: 16,
              columnSpacing: 18,
              columns: [
                DataColumn(label: _buildReportsHeader('№', Icons.tag_rounded)),
                DataColumn(
                    label:
                        _buildReportsHeader('Время', Icons.schedule_rounded)),
                DataColumn(
                    label: _buildReportsHeader(
                        'Полигон', Icons.location_on_rounded)),
                DataColumn(
                    label: _buildReportsHeader('Номер', Icons.pin_outlined)),
                DataColumn(
                    label: _buildReportsHeader(
                        'Транспорт', Icons.local_shipping_rounded)),
                DataColumn(
                    label: _buildReportsHeader(
                        'Подрядчик', Icons.business_rounded)),
                DataColumn(
                    label:
                        _buildReportsHeader('Объем снега (м³)', Icons.snowing)),
                DataColumn(
                    label: _buildReportsHeader(
                        'Детали', Icons.visibility_rounded)),
              ],
              rows: events.asMap().entries.map((entry) {
                final index = rowStartIndex + entry.key + 1;
                final event = entry.value;
                final rowColor = entry.key.isEven
                    ? AppColors.cardBackground
                    : AppColors.secondaryBackground.withOpacity(0.35);
                final contractorName =
                    _resolveContractorName(event, organizationsData);
                final vehicleName =
                    _resolveVehicleName(event, organizationsData);
                final polygonName = _polygonName(
                  cameraId: event.cameraId,
                  polygonId: event.polygonId,
                );

                return DataRow(
                  color: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.hovered)) {
                      return AppColors.primary.withOpacity(0.05);
                    }
                    return rowColor;
                  }),
                  cells: [
                    DataCell(_buildIndexBadge(index)),
                    DataCell(
                      _buildTimeCell(
                        date: dateOnlyFormat.format(event.eventTime.toLocal()),
                        time: timeOnlyFormat.format(event.eventTime.toLocal()),
                      ),
                    ),
                    DataCell(
                      _buildTagChip(
                        text: polygonName,
                        icon: Icons.location_on_rounded,
                        color: _colorFromKey(polygonName),
                      ),
                    ),
                    DataCell(
                      _buildTagChip(
                        text: event.plateNumber,
                        icon: Icons.pin_outlined,
                        color: AppColors.primaryDark,
                        maxWidth: 150,
                        letterSpacing: 0.8,
                      ),
                    ),
                    DataCell(
                      _buildTagChip(
                        text: vehicleName,
                        icon: Icons.local_shipping_rounded,
                        color: AppColors.info,
                      ),
                    ),
                    DataCell(
                      _buildTagChip(
                        text: contractorName,
                        icon: Icons.business_rounded,
                        color: AppColors.secondary,
                      ),
                    ),
                    DataCell(_buildVolumeBadge(event.snowVolumeM3)),
                    DataCell(
                      _buildDetailsButton(
                        tripNumber: index,
                        event: event,
                        polygonName: polygonName,
                        contractorName: contractorName,
                        vehicleName: vehicleName,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportsHeader(String label, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildIndexBadge(int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primary.withOpacity(0.25)),
      ),
      child: Text(
        '$index',
        style: AppTextStyles.caption.copyWith(
          color: AppColors.primaryDark,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildTimeCell({
    required String date,
    required String time,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          date,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          time,
          style: AppTextStyles.body.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildTagChip({
    required String text,
    required Color color,
    IconData? icon,
    double maxWidth = 230,
    double letterSpacing = 0,
  }) {
    final label = text.trim().isEmpty ? '—' : text.trim();
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.11),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withOpacity(0.3), width: 0.9),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                  letterSpacing: letterSpacing,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVolumeBadge(double? volumeM3) {
    if (volumeM3 == null) {
      return _buildTagChip(
        text: '—',
        color: AppColors.textTertiary,
        icon: Icons.remove,
        maxWidth: 84,
      );
    }

    final safeVolume = max(0, volumeM3);
    final baseColor = AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            baseColor.withOpacity(0.95),
            baseColor.withOpacity(0.78),
          ],
        ),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: baseColor.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.snowing, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            '${safeVolume.toStringAsFixed(1)} м³',
            style: AppTextStyles.caption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsButton({
    required int tripNumber,
    required AnprReportEvent event,
    required String polygonName,
    required String contractorName,
    required String vehicleName,
  }) {
    final hasPhotos = (event.platePhotoUrl?.trim().isNotEmpty ?? false) ||
        (event.bodyPhotoUrl?.trim().isNotEmpty ?? false);

    return Tooltip(
      message: hasPhotos
          ? 'Открыть детали рейса'
          : 'Открыть детали рейса (без фото)',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => _showTripDetailsDialog(
            tripNumber: tripNumber,
            event: event,
            polygonName: polygonName,
            contractorName: contractorName,
            vehicleName: vehicleName,
          ),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.11),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.28),
                width: 0.9,
              ),
            ),
            child: Icon(
              Icons.visibility_rounded,
              size: 16,
              color: AppColors.primaryDark,
            ),
          ),
        ),
      ),
    );
  }

  void _showTripDetailsDialog({
    required int tripNumber,
    required AnprReportEvent event,
    required String polygonName,
    required String contractorName,
    required String vehicleName,
  }) {
    final formattedTime =
        DateFormat('dd.MM.yyyy HH:mm:ss').format(event.eventTime.toLocal());
    final platePhotoUrl = event.platePhotoUrl?.trim();
    final bodyPhotoUrl = event.bodyPhotoUrl?.trim();

    showDialog<void>(
      context: context,
      builder: (context) {
        final width = MediaQuery.of(context).size.width;
        final dialogWidth = width > 1100 ? 980.0 : width - 28;

        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSize.cardRadius),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
          contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.25),
                  ),
                ),
                child: const Icon(
                  Icons.visibility_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Рейс №$tripNumber',
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.title2.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: dialogWidth,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: AppPadding.normal,
                    runSpacing: AppPadding.small,
                    children: [
                      _buildTripInfoItem(
                        icon: Icons.schedule_rounded,
                        label: 'Время',
                        value: formattedTime,
                      ),
                      _buildTripInfoItem(
                        icon: Icons.location_on_rounded,
                        label: 'Полигон',
                        value: polygonName,
                      ),
                      _buildTripInfoItem(
                        icon: Icons.pin_outlined,
                        label: 'Номер',
                        value: event.plateNumber,
                      ),
                      _buildTripInfoItem(
                        icon: Icons.local_shipping_rounded,
                        label: 'Транспорт',
                        value: vehicleName,
                      ),
                      _buildTripInfoItem(
                        icon: Icons.business_rounded,
                        label: 'Подрядчик',
                        value: contractorName,
                      ),
                      _buildTripInfoItem(
                        icon: Icons.snowing,
                        label: 'Объем снега',
                        value: event.snowVolumeM3 == null
                            ? '—'
                            : '${event.snowVolumeM3!.toStringAsFixed(1)} м³',
                      ),
                      if (event.cameraId != null &&
                          event.cameraId!.trim().isNotEmpty)
                        _buildTripInfoItem(
                          icon: Icons.videocam_rounded,
                          label: 'Камера',
                          value: _polygonName(
                            cameraId: event.cameraId,
                            polygonId: event.polygonId,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppPadding.large),
                  Text(
                    'Фотографии',
                    style: AppTextStyles.title3.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppPadding.small),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final useRow = constraints.maxWidth >= 760;
                      final plateCard = _buildPhotoCard(
                        title: 'Фото номера',
                        imageUrl: platePhotoUrl,
                      );
                      final bodyCard = _buildPhotoCard(
                        title: 'Фото кузова',
                        imageUrl: bodyPhotoUrl,
                      );

                      if (useRow) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: plateCard),
                            const SizedBox(width: AppPadding.normal),
                            Expanded(child: bodyCard),
                          ],
                        );
                      }

                      return Column(
                        children: [
                          plateCard,
                          const SizedBox(height: AppPadding.normal),
                          bodyCard,
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded, size: 16),
              label: const Text('Закрыть'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTripInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final safeValue = value.trim().isEmpty ? '—' : value.trim();
    return Container(
      constraints: const BoxConstraints(
        minWidth: 190,
        maxWidth: 320,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground.withOpacity(0.6),
        borderRadius: BorderRadius.circular(AppSize.smallRadius),
        border: Border.all(color: AppColors.divider, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  safeValue,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoCard({
    required String title,
    required String? imageUrl,
  }) {
    final safeImageUrl = imageUrl?.trim() ?? '';
    final hasImage = safeImageUrl.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSize.smallRadius),
        border: Border.all(color: AppColors.divider, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              children: [
                Icon(
                  Icons.photo_camera_back_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          AspectRatio(
            aspectRatio: 16 / 10,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(AppSize.smallRadius),
                bottomRight: Radius.circular(AppSize.smallRadius),
              ),
              child: hasImage
                  ? Material(
                      color: Colors.black,
                      child: InkWell(
                        onTap: () => _openFullscreenPhoto(
                          imageUrl: safeImageUrl,
                          title: title,
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              safeImageUrl,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: AppColors.secondaryBackground,
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    size: 30,
                                    color: AppColors.textSecondary,
                                  ),
                                );
                              },
                            ),
                            Positioned(
                              right: 8,
                              bottom: 8,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.55),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Icon(
                                  Icons.open_in_full_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Container(
                      color: AppColors.secondaryBackground,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.hide_image_outlined,
                            color: AppColors.textSecondary,
                            size: 30,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Фото отсутствует',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _openFullscreenPhoto({
    required String imageUrl,
    required String title,
  }) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.92),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: InteractiveViewer(
                      minScale: 1,
                      maxScale: 5,
                      child: Center(
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(
                                  color: Colors.white),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(
                                    Icons.broken_image_outlined,
                                    color: Colors.white70,
                                    size: 42,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Не удалось загрузить фото',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    title,
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  tooltip: 'Закрыть',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _colorFromKey(String value) {
    const palette = <Color>[
      Color(0xFF2563EB),
      Color(0xFF7C3AED),
      Color(0xFF0891B2),
      Color(0xFF0F766E),
      Color(0xFFEA580C),
    ];
    final hash = value.runes.fold<int>(0, (acc, rune) => acc + rune);
    return palette[hash % palette.length];
  }

  Widget _buildPagination({
    required int currentPage,
    required int totalPages,
    required int startIndex,
    required int endIndex,
    required int totalCount,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppPadding.normal,
        vertical: AppPadding.small,
      ),
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground.withOpacity(0.35),
        borderRadius: BorderRadius.circular(AppSize.smallRadius),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Wrap(
        spacing: AppPadding.normal,
        runSpacing: AppPadding.small,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'Показано ${totalCount == 0 ? 0 : startIndex + 1}-$endIndex из $totalCount',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Первая страница',
                onPressed: currentPage > 1
                    ? () => setState(() {
                          _currentPage = 1;
                        })
                    : null,
                icon: const Icon(Icons.first_page),
              ),
              IconButton(
                tooltip: 'Предыдущая страница',
                onPressed: currentPage > 1
                    ? () => setState(() {
                          _currentPage = currentPage - 1;
                        })
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                '$currentPage / $totalPages',
                style: AppTextStyles.title3.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                tooltip: 'Следующая страница',
                onPressed: currentPage < totalPages
                    ? () => setState(() {
                          _currentPage = currentPage + 1;
                        })
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
              IconButton(
                tooltip: 'Последняя страница',
                onPressed: currentPage < totalPages
                    ? () => setState(() {
                          _currentPage = totalPages;
                        })
                    : null,
                icon: const Icon(Icons.last_page),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppPadding.large),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSize.cardRadius),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Column(
        children: [
          Icon(Icons.event_busy, size: 52, color: AppColors.textSecondary),
          const SizedBox(height: AppPadding.normal),
          Text(
            message,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppPadding.large),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.06),
        borderRadius: BorderRadius.circular(AppSize.cardRadius),
        border: Border.all(color: AppColors.error.withOpacity(0.25), width: 1),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 52, color: AppColors.error),
          const SizedBox(height: AppPadding.normal),
          Text(
            'Ошибка загрузки отчетов',
            style: AppTextStyles.title2.copyWith(color: AppColors.error),
          ),
          const SizedBox(height: AppPadding.small),
          Text(
            message,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _resolveContractorId(
    AnprReportEvent event,
    OrganizationsData? organizationsData,
  ) {
    if (event.contractorId != null && event.contractorId!.isNotEmpty) {
      return event.contractorId!;
    }
    final vehicle = _findVehicleByPlate(event.plateNumber, organizationsData);
    return vehicle?.contractorId ?? '';
  }

  String _resolveContractorName(
    AnprReportEvent event,
    OrganizationsData? organizationsData,
  ) {
    if (event.contractorName != null &&
        event.contractorName!.trim().isNotEmpty) {
      return event.contractorName!.trim();
    }

    final vehicle = _findVehicleByPlate(event.plateNumber, organizationsData);
    if (vehicle == null || organizationsData == null) {
      return '—';
    }

    for (final org in organizationsData.organizations) {
      if (org.id == vehicle.contractorId) {
        return org.name;
      }
    }
    return '—';
  }

  String _resolveVehicleName(
    AnprReportEvent event,
    OrganizationsData? organizationsData,
  ) {
    final eventVehicleName =
        '${event.vehicleBrand ?? ''} ${event.vehicleModel ?? ''}'.trim();
    if (eventVehicleName.isNotEmpty) {
      return eventVehicleName;
    }

    final vehicle = _findVehicleByPlate(event.plateNumber, organizationsData);
    if (vehicle == null) return '—';

    final fullName = '${vehicle.brand} ${vehicle.model}'.trim();
    return fullName.isEmpty ? '—' : fullName;
  }

  Vehicle? _findVehicleByPlate(
    String plateNumber,
    OrganizationsData? organizationsData,
  ) {
    if (organizationsData == null) return null;
    final normalizedPlate = _normalizePlate(plateNumber);

    for (final vehicle in organizationsData.vehicles) {
      if (_normalizePlate(vehicle.plateNumber) == normalizedPlate) {
        return vehicle;
      }
    }
    return null;
  }
}
