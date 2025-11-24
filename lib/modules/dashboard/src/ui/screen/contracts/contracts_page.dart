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
import 'package:akimat_project/core/ui/widgets/animated_contract_card.dart';
import 'package:akimat_project/l10n/l10n.dart';
import 'package:akimat_project/modules/auth/src/controller/auth_notifier.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/contracts/widgets/contract_dialogs.dart';
import 'package:akimat_project/modules/dashboard/src/controller/contracts_controller.dart';
import 'package:akimat_project/modules/dashboard/src/controller/contracts_state.dart';
import 'package:akimat_project/modules/dashboard/src/model/contracts/contract.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/user_role.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_data_table.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_error_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class ContractsPage extends ConsumerWidget {
  const ContractsPage({
    super.key,
    required this.scaffoldKey,
    this.webNavbarWidgets,
    this.mobileNavbarWidgets,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;
  final List<Widget>? webNavbarWidgets;
  final List<Widget>? mobileNavbarWidgets;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localeProvider);
    final s = S.of(context)!;
    final state = ref.watch(contractsControllerProvider);
    final controller = ref.watch(contractsControllerProvider.notifier);
    final config = PlatformConfig.instance;

    return Scaffold(
      key: scaffoldKey,
      drawer: !kIsWeb ? const DrawerMobile() : null,
      appBar: kIsWeb
          ? null
          : AppBar(
              title: Text(s.contracts),
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              actions: NavbarWidgetsProvider.combineMobileWidgets(
                context,
                mobileNavbarWidgets,
              ),
            ),
      body: Column(
        children: [
          if (kIsWeb)
            HeaderNavbar(
              webWidgets: webNavbarWidgets,
            ),
          Expanded(
            child: state.data.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => OrganizationsErrorState(
                message: s.failed_to_load_data(error),
                onRetry: controller.refresh,
              ),
              data: (data) => _ContractsContent(
                config: config,
                state: state,
                data: data,
                controller: controller,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContractsContent extends ConsumerWidget {
  const _ContractsContent({
    required this.config,
    required this.state,
    required this.data,
    required this.controller,
  });

  final PlatformConfig config;
  final ContractsState state;
  final ContractsData data;
  final ContractsController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context)!;
    final dateFormat = DateFormat('dd.MM.yyyy');

    return Container(
      margin: EdgeInsets.all(config.padding),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSize.cardRadius),
        border: Border.all(color: AppColors.divider, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: AppSize.shadowBlur,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppPadding.large),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.divider, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    s.contracts,
                    style: AppTextStyles.title1,
                  ),
                ),
                // Кнопка создания только для KGU ZKH
                if (state.role == UserRole.kguZkhAdmin)
                  FilledButton.icon(
                    onPressed: () {
                      final authState = ref.read(authNotifierProvider);
                      ContractDialogs.showCreateContractDialog(
                        context: context,
                        controller: controller,
                        data: data,
                        organizationId: authState.user?.organizationId, // Передаем ID организации KGU ZKH
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(s.create_contract),
                    ),
                  ),
              ],
            ),
          ),
          // Filters
          Container(
            padding: const EdgeInsets.all(AppPadding.normal),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.divider, width: 0.5),
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 800;
                final isMobile = !kIsWeb || constraints.maxWidth < 600;
                final itemWidth = isWide ? 200.0 : (constraints.maxWidth - AppPadding.normal * 3) / 2;
                
                return Wrap(
                  spacing: AppPadding.normal,
                  runSpacing: AppPadding.small,
                  children: [
                    // Contractor filter (только для KGU ZKH и Акимата)
                    if (state.role == UserRole.kguZkhAdmin || state.role == UserRole.akimatAdmin)
                      SizedBox(
                        width: itemWidth,
                        child: SafeDropdownButtonFormField<String?>(
                          value: state.contractorFilter,
                          decoration: InputDecoration(
                            labelText: s.contractor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppSize.smallRadius),
                            ),
                            isDense: true,
                          ),
                          isExpanded: true,
                          items: [
                            DropdownMenuItem(
                              value: null,
                              child: Text(s.all, overflow: TextOverflow.ellipsis),
                            ),
                            ...data.contractors.map(
                              (contractor) => DropdownMenuItem(
                                value: contractor.id,
                                child: Text(
                                  contractor.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            // Всегда вызываем setContractorFilter, даже если значение не изменилось
                            // PopupMenuButton всегда вызывает onSelected, что позволяет повторно выбрать "Все"
                            controller.setContractorFilter(value);
                          },
                        ),
                      ),
                    // Status filter
                    SizedBox(
                      width: itemWidth,
                      child: SafeDropdownButtonFormField<ContractStatus?>(
                        value: state.statusFilter,
                        decoration: InputDecoration(
                          labelText: s.status,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSize.smallRadius),
                          ),
                          isDense: true,
                        ),
                        isExpanded: true,
                        items: [
                          DropdownMenuItem(
                            value: null,
                            child: Text(s.all, overflow: TextOverflow.ellipsis),
                          ),
                          DropdownMenuItem(
                            value: ContractStatus.planned,
                            child: Text(s.planned, overflow: TextOverflow.ellipsis),
                          ),
                          DropdownMenuItem(
                            value: ContractStatus.active,
                            child: Text(s.active, overflow: TextOverflow.ellipsis),
                          ),
                          DropdownMenuItem(
                            value: ContractStatus.expired,
                            child: Text(s.expired, overflow: TextOverflow.ellipsis),
                          ),
                          DropdownMenuItem(
                            value: ContractStatus.archived,
                            child: Text(s.archived, overflow: TextOverflow.ellipsis),
                          ),
                        ],
                        onChanged: (value) {
                          // Всегда вызываем setStatusFilter, даже если значение не изменилось
                          // PopupMenuButton всегда вызывает onSelected, что позволяет повторно выбрать "Все"
                          controller.setStatusFilter(value);
                        },
                      ),
                    ),
                    // Period filter - используем кастомный date range picker для мобильных
                    if (isMobile)
                      SizedBox(
                        width: double.infinity,
                        child: CustomDateRangePicker(
                          label: s.period,
                          initialStartDate: state.periodStart,
                          initialEndDate: state.periodEnd,
                          onDateRangeSelected: (start, end) {
                            controller.setPeriodFilter(start, end);
                          },
                        ),
                      )
                    else
                      ...[
                        SizedBox(
                          width: itemWidth,
                          child: TextFormField(
                            decoration: InputDecoration(
                              labelText: s.period_start,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppSize.smallRadius),
                              ),
                              suffixIcon: const Icon(Icons.calendar_today),
                              isDense: true,
                            ),
                            readOnly: true,
                            controller: TextEditingController(
                              text: state.periodStart != null
                                  ? dateFormat.format(state.periodStart!)
                                  : '',
                            ),
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: state.periodStart ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (date != null) {
                                controller.setPeriodFilter(
                                  date,
                                  state.periodEnd,
                                );
                              }
                            },
                          ),
                        ),
                        SizedBox(
                          width: itemWidth,
                          child: TextFormField(
                            decoration: InputDecoration(
                              labelText: s.period_end,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppSize.smallRadius),
                              ),
                              suffixIcon: const Icon(Icons.calendar_today),
                              isDense: true,
                            ),
                            readOnly: true,
                            controller: TextEditingController(
                              text: state.periodEnd != null
                                  ? dateFormat.format(state.periodEnd!)
                                  : '',
                            ),
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: state.periodEnd ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (date != null) {
                                controller.setPeriodFilter(
                                  state.periodStart,
                                  date,
                                );
                              }
                            },
                          ),
                        ),
                      ],
                  ],
                );
              },
            ),
          ),
          // Table
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(kIsWeb ? AppPadding.large : AppPadding.normal),
              child: data.contracts.isEmpty
                  ? Center(
                      child: Text(
                        s.no_contracts_found,
                        style: AppTextStyles.body,
                      ),
                    )
                  : kIsWeb
                      ? SingleChildScrollView(
                          // Вертикальный скролл для таблицы
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: OrganizationsDataTable(
                        columns: [
                          DataColumn(label: Text(s.contract_name)),
                          DataColumn(label: Text(s.contractor)),
                          DataColumn(label: Text(s.period)),
                          DataColumn(label: Text(s.status)),
                          DataColumn(label: Text(s.price_per_m3)),
                          DataColumn(label: Text(s.volume_progress)),
                          DataColumn(label: Text(s.budget_progress)),
                          DataColumn(label: Text(s.budget_exceeded)),
                          DataColumn(label: Text(s.actions)),
                        ],
                      rows: data.contracts.map((contract) {
                        final contractor = data.contractors.firstWhere(
                          (c) => c.id == contract.contractorId,
                          orElse: () => data.contractors.first,
                        );
                        final volumeProgress = contract.usage != null &&
                                (contract.minimalVolumeM3 ?? 0) > 0
                            ? (contract.usage!.totalVolumeM3 /
                                    (contract.minimalVolumeM3 ?? 1) *
                                    100.0)
                                .clamp(0.0, 100.0)
                            : 0.0;
                        final budgetProgress = (contract.budgetTotal ?? 0) > 0
                            ? (contract.usage?.totalCost ?? 0.0) /
                                    (contract.budgetTotal ?? 1) *
                                    100.0
                            : 0.0;
                        final budgetExceeded =
                            contract.budgetTotal != null &&
                            (contract.usage?.totalCost ?? 0.0) >
                                contract.budgetTotal!;

                        return DataRow(
                          cells: [
                            DataCell(
                              SizedBox(
                                width: 150,
                                child: Text(
                                  contract.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 150,
                                child: Text(
                                  contractor.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 180,
                                child: Text(
                                  '${dateFormat.format(contract.startAt)} - ${dateFormat.format(contract.endAt)}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            DataCell(_ContractStatusChip(status: _getContractStatus(contract))),
                            DataCell(Text('${contract.pricePerM3.toStringAsFixed(2)} ₸')),
                            DataCell(
                              SizedBox(
                                width: 200,
                                child: _ProgressBar(
                                  progress: volumeProgress,
                                  label:
                                      '${contract.usage?.totalVolumeM3.toStringAsFixed(1) ?? '0'} / ${contract.minimalVolumeM3?.toStringAsFixed(1)} м³',
                                ),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 200,
                                child: _ProgressBar(
                                  progress: budgetProgress,
                                  label:
                                      '${(contract.usage?.totalCost ?? 0.0).toStringAsFixed(0)} / ${contract.budgetTotal?.toStringAsFixed(0)} ₸',
                                ),
                              ),
                            ),
                            DataCell(Text(budgetExceeded ? s.yes : s.no)),
                            DataCell(
                              TextButton(
                                onPressed: () {
                                  // TODO: Показать карточку контракта
                                },
                                child: Text(s.open),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: AppPadding.large),
                          itemCount: data.contracts.length,
                          itemBuilder: (context, index) {
                            final contract = data.contracts[index];
                            final contractor = data.contractors.firstWhere(
                              (c) => c.id == contract.contractorId,
                              orElse: () => data.contractors.first,
                            );

                            return AnimatedContractCard(
                              contract: contract,
                              contractorName: contractor.name,
                              index: index,
                              onTap: () {
                                // TODO: Показать карточку контракта
                              },
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  ContractStatus _getContractStatus(Contract contract) {
    final now = DateTime.now();
    if (!contract.isActive) return ContractStatus.archived;
    if (now.isBefore(contract.startAt)) return ContractStatus.planned;
    if (now.isAfter(contract.endAt)) return ContractStatus.expired;
    return ContractStatus.active;
  }
}

class _ContractStatusChip extends StatelessWidget {
  const _ContractStatusChip({required this.status});

  final ContractStatus status;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    Color color;
    String label;

    switch (status) {
      case ContractStatus.planned:
        color = Colors.blue;
        label = s.planned;
        break;
      case ContractStatus.active:
        color = Colors.green;
        label = s.active;
        break;
      case ContractStatus.expired:
        color = Colors.orange;
        label = s.expired;
        break;
      case ContractStatus.archived:
        color = Colors.grey;
        label = s.archived;
        break;
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
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress, required this.label});

  final double progress;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        LinearProgressIndicator(
          value: progress / 100,
          minHeight: 8,
          backgroundColor: AppColors.secondaryBackground,
          valueColor: AlwaysStoppedAnimation<Color>(
            progress > 100 ? Colors.red : Colors.green,
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

class _ContractInfoRow extends StatelessWidget {
  const _ContractInfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppPadding.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.body,
            ),
          ),
        ],
      ),
    );
  }
}

