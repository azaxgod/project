import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/core/ui/app_textstyle.dart';
import 'package:akimat_project/modules/dashboard/src/model/tickets/ticket.dart';
import 'package:akimat_project/modules/dashboard/src/model/tickets/ticket_assignment.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DriverTicketDetailsDialog extends StatelessWidget {
  const DriverTicketDetailsDialog({
    super.key,
    required this.ticket,
    this.assignment,
    this.areaName,
    this.polygonName,
    this.metrics,
  });

  final Ticket ticket;
  final TicketAssignment? assignment;
  final String? areaName;
  final String? polygonName;
  final Map<String, dynamic>? metrics; // metrics из TicketDetails

  static Future<void> show({
    required BuildContext context,
    required Ticket ticket,
    TicketAssignment? assignment,
    String? areaName,
    String? polygonName,
    Map<String, dynamic>? metrics,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => DriverTicketDetailsDialog(
        ticket: ticket,
        assignment: assignment,
        areaName: areaName,
        polygonName: polygonName,
        metrics: metrics,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Заголовок
            Container(
              padding: const EdgeInsets.all(AppPadding.large),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                border: Border(
                  bottom: BorderSide(color: AppColors.divider),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Детали тикета',
                      style: AppTextStyles.title2,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Содержимое
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppPadding.large),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Основная информация
                    _buildSection(
                      title: 'Основная информация',
                      children: [
                        _buildInfoRow('ID тикета', ticket.id),
                        _buildInfoRow('Статус', _getStatusLabel(ticket.status)),
                        if (areaName != null)
                          _buildInfoRow('Участок уборки', areaName!),
                        if (polygonName != null)
                          _buildInfoRow('Полигон', polygonName!),
                        _buildInfoRow(
                          'Плановый период',
                          '${DateFormat('dd.MM.yyyy HH:mm').format(ticket.plannedStartAt)} - ${DateFormat('dd.MM.yyyy HH:mm').format(ticket.plannedEndAt)}',
                        ),
                        if (ticket.factStartAt != null)
                          _buildInfoRow(
                            'Фактическое начало',
                            DateFormat('dd.MM.yyyy HH:mm').format(ticket.factStartAt!),
                          ),
                        if (ticket.factEndAt != null)
                          _buildInfoRow(
                            'Фактическое окончание',
                            DateFormat('dd.MM.yyyy HH:mm').format(ticket.factEndAt!),
                          ),
                        if (ticket.description != null && ticket.description!.isNotEmpty)
                          _buildInfoRow('Описание', ticket.description!),
                      ],
                    ),
                    const SizedBox(height: AppPadding.normal),
                    // Метрики
                    if (metrics != null)
                      _buildSection(
                        title: 'Метрики',
                        children: [
                          if (metrics!['total_trips'] != null)
                            _buildInfoRow(
                              'Всего рейсов',
                              metrics!['total_trips'].toString(),
                            ),
                          if (metrics!['total_volume_m3'] != null)
                            _buildInfoRow(
                              'Объем вывезен',
                              '${metrics!['total_volume_m3']} м³',
                            ),
                          if (metrics!['has_violations'] != null)
                            _buildInfoRow(
                              'Нарушения',
                              metrics!['has_violations'] == true ? 'Есть' : 'Нет',
                            ),
                        ],
                      ),
                    if (metrics != null) const SizedBox(height: AppPadding.normal),
                    // Назначение
                    if (assignment != null)
                      _buildSection(
                        title: 'Назначение',
                        children: [
                          _buildInfoRow('ID назначения', assignment!.id),
                          _buildInfoRow(
                            'Статус назначения',
                            _getAssignmentStatusLabel(assignment!.assignmentStatus),
                          ),
                          _buildInfoRow(
                            'Активно',
                            assignment!.isActive ? 'Да' : 'Нет',
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            // Кнопка закрытия
            Container(
              padding: const EdgeInsets.all(AppPadding.normal),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                border: Border(
                  top: BorderSide(color: AppColors.divider),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Закрыть'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppPadding.normal),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSize.cardRadius),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.title3,
          ),
          const SizedBox(height: AppPadding.normal),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppPadding.small),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
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
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
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


