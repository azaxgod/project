import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/core/ui/app_textstyle.dart';
import 'package:akimat_project/modules/dashboard/src/controller/driver_controller.dart';
import 'package:akimat_project/modules/dashboard/src/model/areas/cleaning_area.dart';
import 'package:akimat_project/modules/dashboard/src/model/tickets/ticket.dart';
import 'package:akimat_project/modules/dashboard/src/model/tickets/ticket_assignment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class DriverTicketsList extends ConsumerWidget {
  const DriverTicketsList({
    super.key,
    required this.tickets,
    required this.assignments,
    required this.cleaningAreas,
    required this.driverController,
  });

  final List<Ticket> tickets;
  final Map<String, List<TicketAssignment>> assignments;
  final Map<String, CleaningArea> cleaningAreas;
  final DriverController driverController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Нет заданий',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Подождите, пока подрядчик назначит вам задание',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppPadding.normal),
      itemCount: tickets.length,
      itemBuilder: (context, index) {
        final ticket = tickets[index];
        final ticketAssignments = assignments[ticket.id] ?? [];
        
        // Берем первое активное назначение
        final assignment = ticketAssignments.isNotEmpty ? ticketAssignments.first : null;
        final areaName = cleaningAreas[ticket.cleaningAreaId]?.name ?? 'Участок ${ticket.cleaningAreaId.substring(0, 8)}';
        
        return _buildTicketCard(context, ticket, assignment, areaName);
      },
    );
  }

  Widget _buildTicketCard(
    BuildContext context,
    Ticket ticket,
    TicketAssignment? assignment,
    String areaName,
  ) {
    final canStart = assignment != null && 
                     (assignment.assignmentStatus == null || 
                      assignment.assignmentStatus == AssignmentStatus.notStarted);
    final isInWork = assignment?.assignmentStatus == AssignmentStatus.inWork;
    final isCompleted = assignment?.assignmentStatus == AssignmentStatus.completed;

    return Container(
      margin: const EdgeInsets.only(bottom: AppPadding.normal),
      padding: const EdgeInsets.all(AppPadding.large),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSize.cardRadius),
        border: Border.all(
          color: isInWork ? Colors.green : AppColors.divider,
          width: isInWork ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isInWork 
                ? Colors.green.withOpacity(0.2)
                : Colors.black.withOpacity(0.05),
            blurRadius: isInWork ? 8 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppPadding.small),
                decoration: BoxDecoration(
                  color: _getStatusColor(ticket.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSize.smallRadius),
                ),
                child: Icon(
                  Icons.assignment,
                  color: _getStatusColor(ticket.status),
                  size: 24,
                ),
              ),
              const SizedBox(width: AppPadding.normal),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      areaName,
                      style: AppTextStyles.title2,
                    ),
                    const SizedBox(height: AppPadding.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppPadding.small,
                        vertical: AppPadding.xs,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(ticket.status).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(AppSize.smallRadius),
                      ),
                      child: Text(
                        _getStatusLabel(ticket.status),
                        style: AppTextStyles.caption.copyWith(
                          color: _getStatusColor(ticket.status),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppPadding.large),
          const Divider(),
          const SizedBox(height: AppPadding.normal),
          // Информация
          _buildInfoRow(
            icon: Icons.access_time,
            label: 'Плановый период',
            value: '${DateFormat('dd.MM.yyyy HH:mm').format(ticket.plannedStartAt)} - ${DateFormat('dd.MM.yyyy HH:mm').format(ticket.plannedEndAt)}',
          ),
          if (assignment != null) ...[
            const SizedBox(height: AppPadding.small),
            _buildInfoRow(
              icon: Icons.info_outline,
              label: 'Статус назначения',
              value: _getAssignmentStatusLabel(assignment.assignmentStatus),
            ),
          ],
          const SizedBox(height: AppPadding.large),
          // Кнопки действий
          if (canStart)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  if (assignment != null) {
                    try {
                      await driverController.startTrip(assignment.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Рейс начат. Статус: IN_PROGRESS.'),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 3),
                          ),
                        );
                        // Обновляем данные
                        await driverController.refresh();
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Ошибка при начале рейса: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Начать работу'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: AppPadding.normal),
                ),
              ),
            ),
          if (isInWork)
            Container(
              padding: const EdgeInsets.all(AppPadding.normal),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSize.smallRadius),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: AppPadding.small),
                  Text(
                    'Рейс в работе',
                    style: AppTextStyles.body.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          if (isCompleted)
            Container(
              padding: const EdgeInsets.all(AppPadding.normal),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSize.smallRadius),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.orange),
                  const SizedBox(width: AppPadding.small),
                  Text(
                    'Рейс завершён',
                    style: AppTextStyles.body.copyWith(
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: AppPadding.small),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(TicketStatus status) {
    switch (status) {
      case TicketStatus.planned:
        return Colors.blue;
      case TicketStatus.inProgress:
        return Colors.green;
      case TicketStatus.completed:
        return Colors.orange;
      case TicketStatus.closed:
        return Colors.grey;
      case TicketStatus.cancelled:
        return Colors.red;
    }
  }

  String _getStatusLabel(TicketStatus status) {
    switch (status) {
      case TicketStatus.planned:
        return 'Запланирован';
      case TicketStatus.inProgress:
        return 'В работе';
      case TicketStatus.completed:
        return 'Завершён';
      case TicketStatus.closed:
        return 'Закрыт';
      case TicketStatus.cancelled:
        return 'Отменён';
    }
  }

  String _getAssignmentStatusLabel(AssignmentStatus? status) {
    switch (status) {
      case AssignmentStatus.notStarted:
        return 'Не начат (NOT_STARTED)';
      case AssignmentStatus.inWork:
        return 'В работе (IN_WORK)';
      case AssignmentStatus.completed:
        return 'Завершён (COMPLETED)';
      case null:
        return 'Не установлен (PLANNED)';
    }
  }
}

