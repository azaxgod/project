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
import 'package:akimat_project/l10n/l10n.dart';
import 'package:akimat_project/modules/dashboard/src/controller/tickets_controller.dart';
import 'package:akimat_project/modules/dashboard/src/controller/tickets_state.dart';
import 'package:akimat_project/modules/auth/src/controller/auth_notifier.dart';
import 'package:akimat_project/modules/dashboard/src/model/areas/cleaning_area.dart';
import 'package:akimat_project/modules/dashboard/src/model/contracts/contract.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/organization.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/organization_type.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/user_role.dart';
import 'package:akimat_project/modules/dashboard/src/model/tickets/ticket.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_error_state.dart';
import 'package:akimat_project/core/ui/widgets/date_range_picker.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/tickets/widgets/ticket_create_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class TicketsPage extends ConsumerWidget {
  const TicketsPage({
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
    final state = ref.watch(ticketsControllerProvider);
    final controller = ref.watch(ticketsControllerProvider.notifier);
    final config = PlatformConfig.instance;

    return Scaffold(
      key: scaffoldKey,
      drawer: !kIsWeb ? const DrawerMobile() : null,
      appBar: kIsWeb
          ? null
          : AppBar(
              title: Text(s.tickets),
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
              data: (data) => _TicketsContent(
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

class _TicketsContent extends ConsumerWidget {
  const _TicketsContent({
    required this.config,
    required this.state,
    required this.data,
    required this.controller,
  });

  final PlatformConfig config;
  final TicketsState state;
  final TicketsData data;
  final TicketsController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context)!;
    
    debugPrint('_TicketsContent.build: data.tickets.length = ${data.tickets.length}');
    debugPrint('_TicketsContent.build: state.statusFilter = ${state.statusFilter}');
    debugPrint('_TicketsContent.build: state.contractorFilter = ${state.contractorFilter}');
    debugPrint('_TicketsContent.build: state.areaFilter = ${state.areaFilter}');
    debugPrint('_TicketsContent.build: state.contractFilter = ${state.contractFilter}');
    
    // Фильтрация тикетов
    // ВАЖНО: Фильтры status, contractor, area, contract, planned period уже применяются на сервере
    // через query параметры в loadTickets(), поэтому НЕ нужно фильтровать их на клиенте повторно.
    // Сервер уже вернул отфильтрованные данные.
    // Применяем только фильтры, которые НЕ поддерживаются сервером (например, fact period).
    List<Ticket> filteredTickets = data.tickets;
    
    // Фильтры по статусу, подрядчику, участку, контракту и плановому периоду
    // уже применены на сервере через query параметры, поэтому НЕ применяем их повторно.
    
    // Фильтр по фактическому периоду - может не поддерживаться на сервере,
    // поэтому применяем на клиенте
    if (state.factPeriodStart != null) {
      filteredTickets = filteredTickets
          .where((ticket) => ticket.factStartAt != null && 
                            (ticket.factStartAt!.isAfter(state.factPeriodStart!) || 
                             ticket.factStartAt!.isAtSameMomentAs(state.factPeriodStart!)))
          .toList();
    }
    if (state.factPeriodEnd != null) {
      filteredTickets = filteredTickets
          .where((ticket) => ticket.factEndAt != null && 
                            (ticket.factEndAt!.isBefore(state.factPeriodEnd!) || 
                             ticket.factEndAt!.isAtSameMomentAs(state.factPeriodEnd!)))
          .toList();
    }
    
    // Фильтр по роли:
    // - Подрядчик: сервер уже фильтрует тикеты по contractor_id из JWT токена через /contractor/tickets,
    //   поэтому НЕ нужно фильтровать на клиенте повторно
    // - Водитель видит только тикеты, где он назначен (TODO: реализовать через ticket_assignment)
    // - Акимат и KGU ZKH видят все тикеты - сервер возвращает все тикеты через /akimat/tickets или /kgu/tickets
    // 
    // ВАЖНО: Не применяем дополнительную фильтрацию по contractorId для подрядчика,
    // так как сервер уже вернул только его тикеты через endpoint /contractor/tickets
    if (state.role == UserRole.driver && state.organizationId != null) {
      // TODO: Фильтровать по ticket_assignment, когда будет реализована загрузка назначений
      // Пока водитель видит все тикеты (временное решение)
      filteredTickets = filteredTickets;
    }
    // Подрядчик, Акимат и KGU ZKH - сервер уже применил фильтрацию, не фильтруем на клиенте

    return Container(
      margin: EdgeInsets.all(config.padding),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSize.cardRadius),
        border: Border.all(color: AppColors.divider, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
                    s.tickets,
                    style: AppTextStyles.title1,
                  ),
                ),
                // Кнопка создания только для KGU ZKH
                if (state.role == UserRole.kguZkhAdmin)
                  FilledButton.icon(
                    onPressed: () {
                      final authState = ref.read(authNotifierProvider);
                      TicketCreateDialog.show(
                        context: context,
                        controller: controller,
                        data: data,
                        organizationId: authState.user?.organizationId,
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: Text(s.create_ticket),
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
                // Адаптивная ширина для фильтров
                final filterWidth = constraints.maxWidth > 800 
                    ? 200.0 
                    : (constraints.maxWidth - AppPadding.normal * 3) / 2;
                
                return Wrap(
                  spacing: AppPadding.normal,
                  runSpacing: AppPadding.small,
                  children: [
                    // Status filter
                    SizedBox(
                      width: filterWidth,
                      child: SafeDropdownButtonFormField<TicketStatus?>(
                        value: state.statusFilter,
                        decoration: InputDecoration(
                          labelText: s.status,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSize.smallRadius),
                          ),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: null,
                            child: Text(s.all),
                          ),
                          DropdownMenuItem(
                            value: TicketStatus.planned,
                            child: Text(s.planned),
                          ),
                          DropdownMenuItem(
                            value: TicketStatus.inProgress,
                            child: Text(s.in_progress),
                          ),
                          DropdownMenuItem(
                            value: TicketStatus.completed,
                            child: Text(s.completed),
                          ),
                          DropdownMenuItem(
                            value: TicketStatus.closed,
                            child: Text(s.closed),
                          ),
                          DropdownMenuItem(
                            value: TicketStatus.cancelled,
                            child: Text(s.cancelled),
                          ),
                        ],
                        onChanged: controller.setStatusFilter,
                      ),
                    ),
                    // Contractor filter (только для KGU ZKH и Акимата)
                    if (state.role == UserRole.kguZkhAdmin || state.role == UserRole.akimatAdmin)
                      SizedBox(
                        width: filterWidth,
                        child: SafeDropdownButtonFormField<String?>(
                          value: state.contractorFilter,
                          decoration: InputDecoration(
                            labelText: s.contractor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppSize.smallRadius),
                            ),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: null,
                              child: Text(s.all),
                            ),
                            ...data.contractors.map(
                              (contractor) => DropdownMenuItem(
                                value: contractor.id,
                                child: Text(contractor.name),
                              ),
                            ),
                          ],
                          onChanged: controller.setContractorFilter,
                        ),
                      ),
                    // Area filter
                    SizedBox(
                      width: filterWidth,
                      child: SafeDropdownButtonFormField<String?>(
                        value: state.areaFilter,
                        decoration: InputDecoration(
                          labelText: s.area,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSize.smallRadius),
                          ),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: null,
                            child: Text(s.all),
                          ),
                          ...data.areas.map(
                            (area) => DropdownMenuItem(
                              value: area.id,
                              child: Text(area.name),
                            ),
                          ),
                        ],
                        onChanged: controller.setAreaFilter,
                      ),
                    ),
                    // Contract filter
                    SizedBox(
                      width: filterWidth,
                      child: SafeDropdownButtonFormField<String?>(
                        value: state.contractFilter,
                        decoration: InputDecoration(
                          labelText: s.contract,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSize.smallRadius),
                          ),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: null,
                            child: Text(s.all),
                          ),
                          ...data.contracts.map(
                            (contract) => DropdownMenuItem(
                              value: contract.id,
                              child: Text(contract.name),
                            ),
                          ),
                        ],
                        onChanged: controller.setContractFilter,
                      ),
                    ),
                    // Фильтр по плановому периоду
                    SizedBox(
                      width: filterWidth * 2, // Шире для дат
                      child: CustomDateRangePicker(
                        label: 'Плановый период',
                        initialStartDate: state.periodStart,
                        initialEndDate: state.periodEnd,
                        onDateRangeSelected: (start, end) {
                          controller.setPeriodFilter(start, end);
                        },
                      ),
                    ),
                    // Фильтр по фактическому периоду
                    SizedBox(
                      width: filterWidth * 2, // Шире для дат
                      child: CustomDateRangePicker(
                        label: 'Фактический период',
                        initialStartDate: state.factPeriodStart,
                        initialEndDate: state.factPeriodEnd,
                        onDateRangeSelected: (start, end) {
                          controller.setFactPeriodFilter(start, end);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          // Table
          Expanded(
            child: filteredTickets.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 64,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(height: AppPadding.normal),
                        Text(
                          data.tickets.isEmpty 
                              ? 'Нет тикетов'
                              : 'Нет тикетов, соответствующих фильтрам',
                          style: AppTextStyles.headline.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (data.tickets.isNotEmpty && filteredTickets.isEmpty) ...[
                          const SizedBox(height: AppPadding.small),
                          TextButton(
                            onPressed: () {
                              // Сбрасываем все фильтры
                              controller.setStatusFilter(null);
                              controller.setContractorFilter(null);
                              controller.setAreaFilter(null);
                              controller.setContractFilter(null);
                              controller.setPeriodFilter(null, null);
                              controller.setFactPeriodFilter(null, null);
                            },
                            child: const Text('Сбросить фильтры'),
                          ),
                        ],
                      ],
                    ),
                  )
                : kIsWeb
                    ? SingleChildScrollView(
                        // Вертикальный скролл для таблицы
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                      columns: [
                        DataColumn(label: Text(s.ticket_id)),
                        DataColumn(label: Text(s.area)),
                        DataColumn(label: Text(s.contractor)),
                        DataColumn(label: Text(s.contract)),
                        DataColumn(label: Text(s.period)),
                        DataColumn(label: Text(s.status)),
                        // Колонка "Назначено водителей" только для Подрядчика
                        if (state.role == UserRole.contractorAdmin)
                          DataColumn(label: Text('Назначено')),
                        DataColumn(label: Text(s.trips_count)),
                        DataColumn(label: Text(s.volume_shipped)),
                        DataColumn(label: Text(s.violations)),
                        if (state.role == UserRole.kguZkhAdmin || state.role == UserRole.contractorAdmin)
                          DataColumn(label: Text(s.actions)),
                      ],
                      rows: filteredTickets.map((ticket) {
                        final area = data.areas.firstWhere(
                          (a) => a.id == ticket.cleaningAreaId,
                          orElse: () => data.areas.isNotEmpty 
                              ? data.areas.first 
                              : CleaningArea(
                                  id: '',
                                  name: '—',
                                  geometry: [],
                                  status: CleaningAreaStatus.active,
                                  isActive: false,
                                  createdAt: DateTime.now(),
                                  updatedAt: DateTime.now(),
                                ),
                        );
                        final contractor = data.contractors.firstWhere(
                          (c) => c.id == ticket.contractorId,
                          orElse: () => data.contractors.isNotEmpty 
                              ? data.contractors.first 
                              : Organization(
                                  id: '',
                                  type: OrganizationType.contractor,
                                  name: '—',
                                  bin: '',
                                  isActive: false,
                                ),
                        );
                        final contract = data.contracts.firstWhere(
                          (c) => c.id == ticket.contractId,
                          orElse: () => data.contracts.isNotEmpty 
                              ? data.contracts.first 
                              : Contract(
                                  id: '',
                                  contractorId: '',
                                  name: '—',
                                  workType: ContractWorkType.road,
                                  pricePerM3: 0,
                                  budgetTotal: 0,
                                  minimalVolumeM3: 0,
                                  startAt: DateTime.now(),
                                  endAt: DateTime.now(),
                                  isActive: false,
                                  createdAt: DateTime.now(),
                                ),
                        );
                        
                        final cells = [
                          DataCell(Text(ticket.id.length >= 8 ? ticket.id.substring(0, 8) : ticket.id)),
                          DataCell(Text(area.name)),
                          DataCell(Text(contractor.name)),
                          DataCell(Text(contract.name)),
                          DataCell(Text(
                            '${DateFormat('dd.MM.yyyy').format(ticket.plannedStartAt)} - ${DateFormat('dd.MM.yyyy').format(ticket.plannedEndAt)}',
                          )),
                          DataCell(_StatusChip(status: ticket.status)),
                          // Колонка "Назначено водителей" только для Подрядчика
                          if (state.role == UserRole.contractorAdmin)
                            DataCell(Text('${data.assignments[ticket.id]?.length ?? 0}')),
                          DataCell(Text('${ticket.tripsCount ?? 0}')),
                          DataCell(Text('${ticket.volumeShipped ?? 0} м³')),
                          DataCell(
                            ticket.hasViolations
                                ? const Icon(Icons.warning, color: Colors.orange)
                                : const Icon(Icons.check, color: Colors.green),
                          ),
                        ];
                        
                        // Добавляем колонку действий для KGU ZKH и Подрядчика
                        if (state.role == UserRole.kguZkhAdmin || state.role == UserRole.contractorAdmin) {
                          cells.add(
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.info_outline, size: 20),
                                    onPressed: () {
                                      // TODO: Открыть карточку тикета
                                      controller.selectTicket(ticket);
                                    },
                                    tooltip: s.details,
                                  ),
                                  if (state.role == UserRole.kguZkhAdmin) ...[
                                    if (ticket.status == TicketStatus.planned)
                                      IconButton(
                                        icon: const Icon(Icons.cancel, size: 20, color: Colors.red),
                                        onPressed: () => controller.cancelTicket(ticket),
                                        tooltip: s.cancel_ticket,
                                      ),
                                    if (ticket.status == TicketStatus.completed)
                                      IconButton(
                                        icon: const Icon(Icons.check_circle, size: 20, color: Colors.green),
                                        onPressed: () => controller.closeTicket(ticket),
                                        tooltip: s.close_ticket,
                                      ),
                                  ],
                                  // Для Подрядчика: кнопка "Назначить" водителей/технику
                                  if (state.role == UserRole.contractorAdmin && ticket.status != TicketStatus.cancelled && ticket.status != TicketStatus.closed)
                                    IconButton(
                                      icon: const Icon(Icons.person_add, size: 20),
                                      onPressed: () {
                                        _TicketsContent._showAssignmentDialog(context, ticket, data, controller);
                                      },
                                      tooltip: 'Назначить водителей/технику',
                                    ),
                                  // Для Подрядчика: перевод в IN_PROGRESS
                                  if (state.role == UserRole.contractorAdmin && ticket.status == TicketStatus.planned)
                                    IconButton(
                                      icon: const Icon(Icons.play_arrow, size: 20, color: Colors.blue),
                                      onPressed: () => controller.startTicket(ticket),
                                      tooltip: 'Начать работы',
                                    ),
                                  // Для Подрядчика: перевод в COMPLETED
                                  if (state.role == UserRole.contractorAdmin && ticket.status == TicketStatus.inProgress)
                                    IconButton(
                                      icon: const Icon(Icons.check_circle_outline, size: 20, color: Colors.green),
                                      onPressed: () => controller.completeTicket(ticket),
                                      tooltip: 'Завершить работы',
                                    ),
                                ],
                              ),
                            ),
                          );
                        }
                        
                        return DataRow(
                          cells: cells,
                        );
                      }).toList(),
                          ),
                        ),
                      )
                    : const SizedBox(), // Для мобильной версии можно добавить ListView с карточками позже
          ),
        ],
      ),
    );
  }

  /// Диалог назначения водителей/техники на тикет
  static void _showAssignmentDialog(
    BuildContext context,
    Ticket ticket,
    TicketsData data,
    TicketsController controller,
  ) {
    // TODO: Реализовать диалог назначения
    // Пока показываем заглушку
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Назначить водителей/технику'),
        content: const Text('Функция назначения будет реализована в следующей версии'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final TicketStatus status;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    Color color;
    String label;
    
    switch (status) {
      case TicketStatus.planned:
        color = Colors.blue;
        label = s.planned;
        break;
      case TicketStatus.inProgress:
        color = Colors.blue;
        label = s.in_progress;
        break;
      case TicketStatus.completed:
        color = Colors.green;
        label = s.completed;
        break;
      case TicketStatus.closed:
        color = Colors.grey;
        label = s.closed;
        break;
      case TicketStatus.cancelled:
        color = Colors.red;
        label = s.cancelled;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppPadding.small, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(color: color),
      ),
    );
  }
}

