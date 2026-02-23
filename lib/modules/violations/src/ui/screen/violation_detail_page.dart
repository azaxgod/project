import 'package:akimat_project/core/locale/locale_provider.dart';
import 'package:akimat_project/core/navbar/drawer_mobile.dart';
import 'package:akimat_project/core/navbar/header_navbar.dart';
import 'package:akimat_project/core/navbar/navbar_widgets_provider.dart';
import 'package:akimat_project/core/platform/platform_utils.dart';
import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/core/ui/app_textstyle.dart';
import 'package:akimat_project/l10n/l10n.dart';
import 'package:akimat_project/modules/violations/src/controller/violations_controller.dart';
import 'package:akimat_project/modules/violations/src/controller/violations_providers.dart';
import 'package:akimat_project/services/violations/model/violation.dart';
import 'package:akimat_project/services/violations/model/appeal.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ViolationDetailPage extends ConsumerStatefulWidget {
  const ViolationDetailPage({
    super.key,
    required this.violationId,
    required this.scaffoldKey,
    this.webNavbarWidgets,
    this.mobileNavbarWidgets,
  });

  final String violationId;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final List<Widget>? webNavbarWidgets;
  final List<Widget>? mobileNavbarWidgets;

  @override
  ConsumerState<ViolationDetailPage> createState() => _ViolationDetailPageState();
}

class _ViolationDetailPageState extends ConsumerState<ViolationDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(violationsControllerProvider.notifier).loadViolationDetail(widget.violationId);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final s = S.of(context)!;
    final state = ref.watch(violationsControllerProvider);
    final controller = ref.read(violationsControllerProvider.notifier);
    final config = PlatformConfig.instance;

    return Scaffold(
      key: widget.scaffoldKey,
      drawer: !kIsWeb ? const DrawerMobile() : null,
      appBar: kIsWeb
          ? null
          : AppBar(
              title: Text(s.violations),
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
            child: state.violationDetail?.when(
              data: (data) => _buildViolationDetail(data, controller),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Ошибка загрузки данных: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => controller.loadViolationDetail(widget.violationId),
                      child: const Text('Повторить'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.pop(),
                      child: const Text('Назад'),
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

  Widget _buildViolationDetail(data, ViolationsController controller) {
    final violation = data.violation.violation;
    final appeals = data.appeals;

    return SingleChildScrollView(
      padding: EdgeInsets.all(PlatformConfig.instance.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок с кнопкой назад
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
              Expanded(
                child: Text(
                  'Детали нарушения',
                  style: AppTextStyles.title1,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppPadding.large),
          
          // Информация о нарушении
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSize.cardRadius),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppPadding.large),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          violation.type.value,
                          style: AppTextStyles.title2,
                        ),
                      ),
                      Row(
                        children: [
                          _buildStatusChip(violation.status),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => _showUpdateStatusDialog(context, ref.read(violationsControllerProvider.notifier), violation),
                            icon: const Icon(Icons.edit, size: 20),
                            tooltip: 'Изменить статус',
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppPadding.normal),
                  _buildInfoRow('ID', violation.id),
                  _buildInfoRow('Рейс', data.violation.violation.tripId),
                  _buildInfoRow('Тип', violation.type.value),
                  _buildInfoRow('Серьезность', violation.severity.value),
                  _buildInfoRow('Обнаружено', violation.detectedBy.value),
                  _buildInfoRow('Статус', violation.status.value),
                  if (violation.description != null)
                    _buildInfoRow('Описание', violation.description!),
                  if (data.violation.driver != null)
                    _buildInfoRow('Водитель', data.violation.driver!.fullName),
                  if (data.violation.vehicle != null)
                    _buildInfoRow('Машина', data.violation.vehicle!.plateNumber),
                  if (data.violation.contractor != null)
                    _buildInfoRow('Подрядчик', data.violation.contractor!.name),
                  _buildInfoRow('Создано', _formatDateTime(violation.createdAt)),
                  _buildInfoRow('Обновлено', _formatDateTime(violation.updatedAt)),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: AppPadding.large),
          
          // Апелляции
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Апелляции (${appeals.length})',
                style: AppTextStyles.title2,
              ),
              ElevatedButton.icon(
                onPressed: () => _showCreateAppealDialog(context, ref.read(violationsControllerProvider.notifier), violation.id),
                icon: const Icon(Icons.add),
                label: const Text('Создать апелляцию'),
              ),
            ],
          ),
          const SizedBox(height: AppPadding.normal),
          
          if (appeals.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppPadding.large),
                child: Center(
                  child: Text(
                    'Апелляций нет',
                    style: AppTextStyles.body.copyWith(color: Colors.grey[600]),
                  ),
                ),
              ),
            )
          else
            ...appeals.map((appeal) => _buildAppealCard(appeal)),
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
            width: 120,
            child: Text(
              '$label:',
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
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

  Widget _buildStatusChip(ViolationStatus status) {
    Color color;
    switch (status.value) {
      case 'OPEN':
        color = Colors.orange;
        break;
      case 'CANCELED':
        color = Colors.green;
        break;
      case 'FIXED':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppPadding.normal,
        vertical: AppPadding.small,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSize.buttonRadius),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.value,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildAppealCard(appeal) {
    final appealData = appeal.appeal;
    return Card(
      margin: const EdgeInsets.only(bottom: AppPadding.normal),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSize.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppPadding.large),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Апелляция #${appealData.id.substring(0, 8)}',
                  style: AppTextStyles.title3,
                ),
                Row(
                  children: [
                    _buildAppealStatusChip(appealData.status),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      tooltip: 'Действия',
                      onSelected: (action) => _showAppealActionDialog(context, ref.read(violationsControllerProvider.notifier), appeal.appeal.id, action),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'UNDER_REVIEW',
                          child: Text('В рассмотрении'),
                        ),
                        const PopupMenuItem(
                          value: 'NEED_INFO',
                          child: Text('Требуется информация'),
                        ),
                        const PopupMenuItem(
                          value: 'APPROVE',
                          child: Text('Одобрить'),
                        ),
                        const PopupMenuItem(
                          value: 'REJECT',
                          child: Text('Отклонить'),
                        ),
                        const PopupMenuItem(
                          value: 'CLOSE',
                          child: Text('Закрыть'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppPadding.small),
            Text(
              'Причина: ${appealData.reasonCode.value}',
              style: AppTextStyles.body,
            ),
            if (appealData.reasonText.isNotEmpty) ...[
              const SizedBox(height: AppPadding.small),
              Text(
                appealData.reasonText,
                style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: AppPadding.small),
            Text(
              'Создано: ${_formatDateTime(appealData.createdAt)}',
              style: AppTextStyles.caption,
            ),
            if (appeal.comments.isEmpty) ...[
              const SizedBox(height: AppPadding.small),
              ElevatedButton.icon(
                onPressed: () => _showAddCommentDialog(context, ref.read(violationsControllerProvider.notifier), appeal.appeal.id),
                icon: const Icon(Icons.comment, size: 16),
                label: const Text('Добавить комментарий'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ] else ...[
              const SizedBox(height: AppPadding.normal),
              Text(
                'Комментарии (${appeal.comments.length})',
                style: AppTextStyles.subheadline.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppPadding.small),
              ...appeal.comments.map((comment) => Padding(
                    padding: const EdgeInsets.only(bottom: AppPadding.small),
                    child: Container(
                      padding: const EdgeInsets.all(AppPadding.small),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppSize.smallRadius),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${comment.authorRole}: ${_formatDateTime(comment.createdAt)}',
                            style: AppTextStyles.caption,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            comment.message,
                            style: AppTextStyles.body,
                          ),
                        ],
                      ),
                    ),
                  )),
              const SizedBox(height: AppPadding.small),
              ElevatedButton.icon(
                onPressed: () => _showAddCommentDialog(context, ref.read(violationsControllerProvider.notifier), appeal.appeal.id),
                icon: const Icon(Icons.comment, size: 16),
                label: const Text('Добавить комментарий'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAppealStatusChip(appealStatus) {
    Color color;
    switch (appealStatus.value) {
      case 'SUBMITTED':
        color = Colors.blue;
        break;
      case 'UNDER_REVIEW':
        color = Colors.orange;
        break;
      case 'NEED_INFO':
        color = Colors.yellow.shade700;
        break;
      case 'APPROVED':
        color = Colors.green;
        break;
      case 'REJECTED':
        color = Colors.red;
        break;
      case 'CLOSED':
        color = Colors.grey;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppPadding.small,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSize.smallRadius),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        appealStatus.value,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showUpdateStatusDialog(BuildContext context, ViolationsController controller, Violation violation) {
    final descriptionController = TextEditingController();
    ViolationStatus? selectedStatus = violation.status;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Изменить статус нарушения'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Текущий статус: ${violation.status.value}',
                  style: AppTextStyles.body.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<ViolationStatus>(
                  value: selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Новый статус',
                    border: OutlineInputBorder(),
                  ),
                  items: ViolationStatus.values.map((status) => DropdownMenuItem(
                    value: status,
                    child: Text(status.value),
                  )).toList(),
                  onChanged: (value) => setState(() => selectedStatus = value),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Причина изменения',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedStatus == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Выберите новый статус')),
                  );
                  return;
                }

                try {
                  await controller.updateViolationStatus(
                    violationId: violation.id,
                    status: selectedStatus!,
                    description: descriptionController.text.isEmpty 
                        ? null 
                        : descriptionController.text,
                  );
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Статус успешно обновлен')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка: $e')),
                  );
                }
              },
              child: const Text('Обновить'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateAppealDialog(BuildContext context, ViolationsController controller, String violationId) {
    final reasonTextController = TextEditingController();
    AppealReasonCode? selectedReasonCode;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Создать апелляцию'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<AppealReasonCode>(
                  value: selectedReasonCode,
                  decoration: const InputDecoration(
                    labelText: 'Причина апелляции *',
                    border: OutlineInputBorder(),
                  ),
                  items: AppealReasonCode.values.map((reasonCode) => DropdownMenuItem(
                    value: reasonCode,
                    child: Text(reasonCode.value),
                  )).toList(),
                  onChanged: (value) => setState(() => selectedReasonCode = value),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonTextController,
                  decoration: const InputDecoration(
                    labelText: 'Описание причины *',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 5,
                ),
                const SizedBox(height: 8),
                Text(
                  'Вы можете прикрепить файлы (фото, видео, документы) для поддержки вашей апелляции',
                  style: AppTextStyles.caption.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedReasonCode == null || reasonTextController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Заполните все обязательные поля')),
                  );
                  return;
                }

                try {
                  await controller.createAppeal(
                    violationId: violationId,
                    reasonCode: selectedReasonCode!,
                    reasonText: reasonTextController.text,
                    attachments: [], // TODO: Add file attachment functionality
                  );
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Апелляция успешно создана')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка: $e')),
                  );
                }
              },
              child: const Text('Создать'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCommentDialog(BuildContext context, ViolationsController controller, String appealId) {
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавить комментарий'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: messageController,
                decoration: const InputDecoration(
                  labelText: 'Комментарий *',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 8),
              Text(
                'Вы можете прикрепить файлы (фото, видео, документы) к комментарию',
                style: AppTextStyles.caption.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (messageController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Введите комментарий')),
                );
                return;
              }

              try {
                await controller.addAppealComment(
                  appealId: appealId,
                  message: messageController.text,
                  attachments: [], // TODO: Add file attachment functionality
                );
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Комментарий добавлен')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Ошибка: $e')),
                );
              }
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  void _showAppealActionDialog(BuildContext context, ViolationsController controller, String appealId, String action) {
    final messageController = TextEditingController();
    String actionTitle = '';
    String actionDescription = '';

    switch (action) {
      case 'UNDER_REVIEW':
        actionTitle = 'В рассмотрении';
        actionDescription = 'Перевести апелляцию в статус "В рассмотрении"';
        break;
      case 'NEED_INFO':
        actionTitle = 'Требуется информация';
        actionDescription = 'Запросить дополнительную информацию по апелляции';
        break;
      case 'APPROVE':
        actionTitle = 'Одобрить';
        actionDescription = 'Одобрить апелляцию';
        break;
      case 'REJECT':
        actionTitle = 'Отклонить';
        actionDescription = 'Отклонить апелляцию';
        break;
      case 'CLOSE':
        actionTitle = 'Закрыть';
        actionDescription = 'Закрыть апелляцию';
        break;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(actionTitle),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                actionDescription,
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                decoration: const InputDecoration(
                  labelText: 'Комментарий (необязательно)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await controller.performAppealAction(
                  appealId: appealId,
                  action: action,
                  message: messageController.text.isEmpty 
                      ? null 
                      : messageController.text,
                );
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Действие "$actionTitle" выполнено')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Ошибка: $e')),
                );
              }
            },
            child: Text(actionTitle),
          ),
        ],
      ),
    );
  }
}








