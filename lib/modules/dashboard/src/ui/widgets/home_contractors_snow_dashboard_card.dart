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
          items.add(
            _ContractorSnowRow(
              contractor: c,
              totalVolume: report.data.totalVolume,
              tripCount: report.data.tripCount,
            ),
          );
        } catch (_) {
          items.add(
            _ContractorSnowRow(
              contractor: c,
              totalVolume: 0,
              tripCount: 0,
            ),
          );
        }
      }

      items.sort((a, b) => b.totalVolume.compareTo(a.totalVolume));

      final limited = widget.maxItems == null
          ? items
          : items.take(widget.maxItems!).toList();

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppPadding.small),
              decoration: BoxDecoration(
                color: Colors.cyan.withAlpha(26),
                borderRadius: BorderRadius.circular(AppSize.smallRadius),
              ),
              child: const Icon(
                Icons.groups_outlined,
                color: Colors.cyan,
                size: AppSize.iconSize,
              ),
            ),
            const SizedBox(width: AppPadding.normal),
            Expanded(
              child: Text(
                'Подрядчики',
                style: AppTextStyles.title2,
              ),
            ),
            IconButton(
              onPressed: _load,
              tooltip: 'Обновить',
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: AppPadding.normal),
        Center(
          child: Column(
            children: [
              Text(
                data.contractorsCount.toString(),
                style: AppTextStyles.title1.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'количество подрядчиков',
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppPadding.large),
        if (data.rows.isEmpty)
          Text(
            'Нет данных',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          )
        else
          Column(
            children: [
              for (final row in data.rows)
                _ContractorSnowTile(
                  row: row,
                  maxVolume: maxVolume,
                ),
              if (data.totalRows > data.rows.length)
                Padding(
                  padding: const EdgeInsets.only(top: AppPadding.small),
                  child: Text(
                    'Показано: ${data.rows.length} из ${data.totalRows}',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                  ),
                ),
            ],
          ),
      ],
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
    required this.tripCount,
  });

  final Organization contractor;
  final double totalVolume;
  final int tripCount;
}

class _ContractorSnowTile extends StatelessWidget {
  const _ContractorSnowTile({
    required this.row,
    required this.maxVolume,
  });

  final _ContractorSnowRow row;
  final double maxVolume;

  @override
  Widget build(BuildContext context) {
    final progress = maxVolume <= 0 ? 0.0 : (row.totalVolume / maxVolume).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: AppPadding.small),
      padding: const EdgeInsets.all(AppPadding.normal),
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground,
        borderRadius: BorderRadius.circular(AppSize.cardRadius),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  row.contractor.name,
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: AppPadding.small),
              Text(
                '${row.totalVolume.toStringAsFixed(1)} м³',
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.cyan,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppPadding.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.cyan.withAlpha(13),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan.withAlpha(179)),
            ),
          ),
          const SizedBox(height: AppPadding.xs),
          Text(
            'Поездок: ${row.tripCount}',
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
