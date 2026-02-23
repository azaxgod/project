import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/core/ui/app_textstyle.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/vehicle.dart';
import 'package:akimat_project/modules/dashboard/src/model/tickets/ticket.dart';
import 'package:akimat_project/modules/dashboard/src/model/tickets/ticket_assignment.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DriverCurrentTripCard extends StatelessWidget {
  const DriverCurrentTripCard({
    super.key,
    required this.ticket,
    required this.assignment, 
    required this.onStartTrip,
    required this.onCompleteTrip,
    this.onShowDetails,
    this.areaName,
    this.polygonName,
    this.vehicle,
  });

  final Ticket ticket;
  final TicketAssignment assignment;
  final VoidCallback onStartTrip;
  final VoidCallback onCompleteTrip;
  final VoidCallback? onShowDetails; // Колбэк для показа деталей тикета
  final String? areaName;
  final String? polygonName;
  final Vehicle? vehicle; // Техника для индикатора состояния

  @override
  Widget build(BuildContext context) {
    final isInWork = assignment.assignmentStatus == AssignmentStatus.inWork;
    final isCompleted = assignment.assignmentStatus == AssignmentStatus.completed;
    // Кнопка "Начать рейс" показывается если статус null (еще не установлен) или NOT_STARTED
    final canStart = assignment.assignmentStatus == null || 
                     assignment.assignmentStatus == AssignmentStatus.notStarted;
    final canComplete = isInWork;

    return Container(
      margin: const EdgeInsets.all(AppPadding.normal),
      padding: const EdgeInsets.all(AppPadding.large),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSize.cardRadius),
        border: Border.all(
          // Зелёная рамка когда рейс в работе (IN_PROGRESS)
          color: isInWork ? Colors.green : AppColors.divider,
          width: isInWork ? 3 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isInWork 
                ? Colors.green.withOpacity(0.2)
                : Colors.black.withOpacity(0.05),
            blurRadius: isInWork ? 8 : 4,
            offset: const Offset(0, 2),
            spreadRadius: isInWork ? 2 : 0,
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
                  color: _getAssignmentStatusColor(assignment.assignmentStatus).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSize.smallRadius),
                ),
                child: Icon(
                  Icons.assignment,
                  color: _getAssignmentStatusColor(assignment.assignmentStatus),
                  size: 24,
                ),
              ),
              const SizedBox(width: AppPadding.normal),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Текущий рейс',
                      style: AppTextStyles.title2,
                    ),
                    const SizedBox(height: AppPadding.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppPadding.small,
                        vertical: AppPadding.xs,
                      ),
                      decoration: BoxDecoration(
                        color: _getAssignmentStatusColor(assignment.assignmentStatus).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(AppSize.smallRadius),
                      ),
                      child: Text(
                        _getAssignmentStatusDisplayLabel(assignment.assignmentStatus),
                        style: AppTextStyles.caption.copyWith(
                          color: _getAssignmentStatusColor(assignment.assignmentStatus),
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
          // Информация о задании
          _buildInfoRow(
            icon: Icons.location_on,
            label: 'Участок уборки',
            value: areaName ?? 'Не указан',
          ),
          const SizedBox(height: AppPadding.small),
          _buildInfoRow(
            icon: Icons.access_time,
            label: 'Время',
            value: '${DateFormat('dd.MM.yyyy HH:mm').format(ticket.plannedStartAt)} - ${DateFormat('dd.MM.yyyy HH:mm').format(ticket.plannedEndAt)}',
          ),
          if (polygonName != null) ...[
            const SizedBox(height: AppPadding.small),
            _buildInfoRow(
              icon: Icons.map,
              label: 'Полигон',
              value: polygonName!,
            ),
          ],
          const SizedBox(height: AppPadding.small),
          _buildInfoRow(
            icon: Icons.info_outline,
            label: 'Статус',
            value: _getAssignmentStatusDisplayLabel(assignment.assignmentStatus),
          ),
          // Индикатор состояния машины
          if (vehicle != null) ...[
            const SizedBox(height: AppPadding.small),
            _buildVehicleStatusIndicator(),
          ],
          const SizedBox(height: AppPadding.large),
          // Кнопки действий
          if (canStart)
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: onStartTrip,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Начать рейс'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: AppPadding.normal),
                    ),
                  ),
                ),
                if (onShowDetails != null) ...[
                  const SizedBox(width: AppPadding.small),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onShowDetails,
                      icon: const Icon(Icons.info_outline),
                      label: const Text('Подробнее'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: AppPadding.normal),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          if (canComplete)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: onCompleteTrip,
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Завершить рейс'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: AppPadding.normal),
                        ),
                      ),
                    ),
                    if (onShowDetails != null) ...[
                      const SizedBox(width: AppPadding.small),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onShowDetails,
                          icon: const Icon(Icons.info_outline),
                          label: const Text('Подробнее'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: AppPadding.normal),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppPadding.small),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppPadding.small),
                  child: Text(
                    'Примечание: Рейс также может быть завершён автоматически после выезда с полигона (фиксируется камерами LANDFILL)',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          // Кнопка "Подробнее" для завершенных рейсов
          if (isCompleted && onShowDetails != null)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onShowDetails,
                icon: const Icon(Icons.info_outline),
                label: const Text('Подробнее'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppPadding.normal),
                ),
              ),
            ),
          if (isCompleted)
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
                    'Задание завершено',
                    style: AppTextStyles.body.copyWith(
                      color: Colors.green,
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
        return 'Не начат';
      case AssignmentStatus.inWork:
        return 'В работе';
      case AssignmentStatus.completed:
        return 'Завершён';
      case null:
        return 'Неизвестно';
    }
  }

  /// Получить отображаемый статус в формате PLANNED/IN_PROGRESS/COMPLETED
  String _getAssignmentStatusDisplayLabel(AssignmentStatus? status) {
    switch (status) {
      case AssignmentStatus.notStarted:
        return 'PLANNED';
      case AssignmentStatus.inWork:
        return 'IN_PROGRESS';
      case AssignmentStatus.completed:
        return 'COMPLETED';
      case null:
        // null означает, что статус еще не установлен, считаем как PLANNED
        return 'PLANNED';
    }
  }

  /// Получить цвет для статуса назначения
  Color _getAssignmentStatusColor(AssignmentStatus? status) {
    switch (status) {
      case AssignmentStatus.notStarted:
        return Colors.blue;
      case AssignmentStatus.inWork:
        return Colors.green;
      case AssignmentStatus.completed:
        return Colors.orange;
      case null:
        // null означает, что статус еще не установлен, используем цвет для PLANNED
        return Colors.blue;
    }
  }

  /// Индикатор состояния машины (в работе/не в работе)
  Widget _buildVehicleStatusIndicator() {
    final isVehicleInWork = assignment.assignmentStatus == AssignmentStatus.inWork;
    final vehicleStatus = isVehicleInWork ? 'В работе' : 'Не в работе';
    final vehicleStatusColor = isVehicleInWork ? Colors.green : Colors.grey;

    return Container(
      padding: const EdgeInsets.all(AppPadding.small),
      decoration: BoxDecoration(
        color: vehicleStatusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSize.smallRadius),
        border: Border.all(
          color: vehicleStatusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: vehicleStatusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppPadding.small),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Состояние машины',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (vehicle != null) ...[
                      Text(
                        '${vehicle!.brand} ${vehicle!.model} (${vehicle!.plateNumber})',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: AppPadding.small),
                    ],
                    Text(
                      vehicleStatus,
                      style: AppTextStyles.body.copyWith(
                        color: vehicleStatusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

