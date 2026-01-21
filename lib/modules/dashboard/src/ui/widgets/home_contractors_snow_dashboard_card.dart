import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/core/ui/app_textstyle.dart';
import 'package:akimat_project/modules/dashboard/src/controller/organizations_controller.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/organization.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/organization_type.dart';
import 'package:akimat_project/services/anpr/module.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeContractorsSnowDashboardCard extends ConsumerStatefulWidget {
  const HomeContractorsSnowDashboardCard({
    super.key,
    this.hours = 24,
    this.maxItems,
  });

  final int hours;
  final int? maxItems;

  @override
  ConsumerState<HomeContractorsSnowDashboardCard> createState() =>
      _HomeContractorsSnowDashboardCardState();
}

class _HomeContractorsSnowDashboardCardState
    extends ConsumerState<HomeContractorsSnowDashboardCard> {
  AsyncValue<_ContractorsSnowData> _data = const AsyncLoading();
  final Map<String, double> _previousVolumesByContractorId = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  Future<void> _load() async {
    setState(() {
      _data = const AsyncLoading();
    });

    try {
      final orgRepo = ref.read(organizationsRepositoryProvider);
      final anpr = ref.read(anprCollectionProvider);

      final organizations = await orgRepo.loadOrganizations();
      final contractors = organizations
          .where((o) => o.type == OrganizationType.contractor && o.isActive)
          .toList();

      final now = DateTime.now();
      final from = now.subtract(Duration(hours: widget.hours));

      final items = <_ContractorSnowRow>[];

      for (final c in contractors) {
        try {
          final report = await anpr.getReports(
            contractorId: c.id,
            from: from,
            to: now,
            limit: 1,
            offset: 0,
          );

          final previous = _previousVolumesByContractorId[c.id] ?? report.data.totalVolume;
          final delta = report.data.totalVolume - previous;
          items.add(
            _ContractorSnowRow(
              contractor: c,
              totalVolume: report.data.totalVolume,
              deltaVolume: delta,
              tripCount: report.data.tripCount,
            ),
          );
        } catch (_) {
          final previous = _previousVolumesByContractorId[c.id] ?? 0;
          items.add(
            _ContractorSnowRow(
              contractor: c,
              totalVolume: 0,
              deltaVolume: 0 - previous,
              tripCount: 0,
            ),
          );
        }
      }

      items.sort((a, b) => b.totalVolume.compareTo(a.totalVolume));

      final limited = widget.maxItems == null
          ? items
          : items.take(widget.maxItems!).toList();

      for (final item in items) {
        _previousVolumesByContractorId[item.contractor.id] = item.totalVolume;
      }

      setState(() {
        _data = AsyncValue.data(
          _ContractorsSnowData(
            contractorsCount: contractors.length,
            rows: limited,
            totalRows: items.length,
          ),
        );
      });
    } catch (e, st) {
      setState(() {
        _data = AsyncValue.error(e, st);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppPadding.large),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSize.cardRadius),
        border: Border.all(color: AppColors.divider, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: AppSize.shadowBlur,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _data.when(
        data: (data) => _buildData(context, data),
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(AppPadding.large),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (e, _) => Row(
          children: [
            Expanded(
              child: Text(
                e.toString(),
                style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              ),
            ),
            IconButton(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildData(BuildContext context, _ContractorsSnowData data) {
    final maxVolume = data.rows.isEmpty
        ? 0.0
        : data.rows
            .map((e) => e.totalVolume)
            .fold<double>(0.0, (prev, v) => v > prev ? v : prev);

    return Container(
      padding: const EdgeInsets.all(AppPadding.large),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.cyan.shade50,
            Colors.blue.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(AppSize.cardRadius),
        border: Border.all(
          color: Colors.cyan.shade200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.cyan.withAlpha(20),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок с иконкой и количеством
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.cyan.shade400,
                      Colors.cyan.shade600,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyan.withAlpha(40),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.groups_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppPadding.normal),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Топ подрядчиков',
                      style: AppTextStyles.title1.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.cyan.shade900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.cyan.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${data.contractorsCount} активных',
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.cyan.shade800,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppPadding.small),
                        if (data.totalRows > data.rows.length)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Топ ${data.rows.length}',
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.orange.shade800,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _load,
                tooltip: 'Обновить данные',
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.refresh_rounded,
                    color: Colors.cyan.shade700,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppPadding.large),
          
          // Большой индикатор общего количества
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppPadding.large),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(180),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.cyan.shade200.withAlpha(100),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  data.contractorsCount.toString(),
                  style: AppTextStyles.title1.copyWith(
                    fontWeight: FontWeight.w900,
                    color: Colors.cyan.shade900,
                    fontSize: 48,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ПОДРЯДЧИКОВ В СИСТЕМЕ',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.cyan.shade700,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppPadding.large),
          
          // Список подрядчиков с объемом снега
          if (data.rows.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppPadding.large),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: AppPadding.normal),
                  Text(
                    'Нет данных о вывозе снега',
                    style: AppTextStyles.body.copyWith(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          else
            ...data.rows.asMap().entries.map((entry) {
              final index = entry.key;
              final row = entry.value;
              return _ContractorSnowTile(
                row: row,
                maxVolume: maxVolume,
                position: index + 1, // Передаем позицию для топ-бейджа
              );
            }),
          
          if (data.totalRows > data.rows.length)
            Padding(
              padding: const EdgeInsets.only(top: AppPadding.normal),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppPadding.normal,
                  vertical: AppPadding.small,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Показаны топ-${data.rows.length} из ${data.totalRows} подрядчиков',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ContractorsSnowData {
  const _ContractorsSnowData({
    required this.contractorsCount,
    required this.rows,
    required this.totalRows,
  });

  final int contractorsCount;
  final List<_ContractorSnowRow> rows;
  final int totalRows;
}

class _ContractorSnowRow {
  const _ContractorSnowRow({
    required this.contractor,
    required this.totalVolume,
    required this.deltaVolume,
    required this.tripCount,
  });

  final Organization contractor;
  final double totalVolume;
  final double deltaVolume;
  final int tripCount;
}

class _ContractorSnowTile extends StatelessWidget {
  const _ContractorSnowTile({
    required this.row,
    required this.maxVolume,
    required this.position, // Позиция в топе (1, 2, 3...)
  });

  final _ContractorSnowRow row;
  final double maxVolume;
  final int position;

  @override
  Widget build(BuildContext context) {
    final progress = maxVolume <= 0 ? 0.0 : (row.totalVolume / maxVolume).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: AppPadding.small),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.cyan.shade100,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.cyan.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppPadding.normal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Верхняя строка с топ-бейджем, названием и объемом
            Row(
              children: [
                // Топ-бейдж (1, 2, 3 место)
                _buildTopBadge(position),
                const SizedBox(width: AppPadding.small),
                Expanded(
                  child: Text(
                    row.contractor.name,
                    style: AppTextStyles.title3.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.cyan.shade900,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: AppPadding.small),
                _buildDeltaBadge(row.deltaVolume),
                const SizedBox(width: AppPadding.small),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.cyan.shade400,
                        Colors.cyan.shade600,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyan.withAlpha(30),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '${row.totalVolume.toStringAsFixed(1)} м³',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppPadding.small),
            
            // Прогресс-бар объема снега
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.cyan.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.cyan.shade500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppPadding.small),
            
            // Нижняя строка с количеством поездок
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.directions_car_rounded,
                        size: 14,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${row.tripCount}',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  'рейсов',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBadge(int position) {
    switch (position) {
      case 1:
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.amber.shade300,
                Colors.amber.shade600,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withAlpha(40),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.emoji_events,
            color: Colors.white,
            size: 18,
          ),
        );
      case 2:
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade500,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withAlpha(30),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.looks_two,
            color: Colors.white,
            size: 18,
          ),
        );
      case 3:
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.brown.shade300,
                Colors.brown.shade500,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.brown.withAlpha(30),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.looks_3,
            color: Colors.white,
            size: 18,
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDeltaBadge(double delta) {
    final rounded = double.parse(delta.toStringAsFixed(1));

    if (rounded > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green.shade200, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add,
              size: 16,
              color: Colors.green.shade700,
            ),
            const SizedBox(width: 4),
            Text(
              rounded.toStringAsFixed(1),
              style: AppTextStyles.caption.copyWith(
                color: Colors.green.shade700,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    if (rounded < 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red.shade200, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.remove,
              size: 16,
              color: Colors.red.shade700,
            ),
            const SizedBox(width: 4),
            Text(
              rounded.abs().toStringAsFixed(1),
              style: AppTextStyles.caption.copyWith(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.remove,
            size: 16,
            color: Colors.grey.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            '0',
            style: AppTextStyles.caption.copyWith(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
