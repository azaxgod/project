import 'package:akimat_project/core/locale/locale_provider.dart';
import 'package:akimat_project/core/platform/platform_utils.dart';
import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/core/ui/app_textstyle.dart';
import 'package:akimat_project/modules/dashboard/src/controller/landfill_acts_controller.dart';
import 'package:akimat_project/modules/dashboard/src/model/acts/act.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class LandfillActsPage extends ConsumerStatefulWidget {
  const LandfillActsPage({
    super.key,
    required this.scaffoldKey,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;

  @override
  ConsumerState<LandfillActsPage> createState() => _LandfillActsPageState();
}

class _LandfillActsPageState extends ConsumerState<LandfillActsPage> {
  DateTime? _selectedDateFrom;
  DateTime? _selectedDateTo;
  String? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final config = PlatformConfig.instance;
    final state = ref.watch(landfillActsControllerProvider);
    final controller = ref.read(landfillActsControllerProvider.notifier);

    return Container(
      margin: EdgeInsets.all(config.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Заголовок
            Container(
              padding: const EdgeInsets.all(AppPadding.large),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(AppSize.cardRadius),
                border: Border.all(color: AppColors.divider, width: 0.5),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppPadding.normal),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSize.smallRadius),
                    ),
                    child: Icon(
                      Icons.description,
                      color: AppColors.primary,
                      size: AppSize.iconSizeLarge,
                    ),
                  ),
                  const SizedBox(width: AppPadding.normal),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Акты с КГУ',
                          style: AppTextStyles.title1,
                        ),
                        const SizedBox(height: AppPadding.xs),
                        Text(
                          'Просмотр и подтверждение актов КГУ ↔ организация приёма снега',
                          style: AppTextStyles.footnote.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: controller.refresh,
                  tooltip: 'Обновить',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppPadding.large),
          // Фильтры
            Container(
            padding: const EdgeInsets.all(AppPadding.normal),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(AppSize.cardRadius),
                border: Border.all(color: AppColors.divider, width: 0.5),
              ),
            child: Row(
              children: [
                // Фильтр по дате от
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDateFrom ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          _selectedDateFrom = date;
                        });
                        controller.setDateRange(_selectedDateFrom, _selectedDateTo);
                      }
                    },
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      _selectedDateFrom != null
                          ? DateFormat('dd.MM.yyyy').format(_selectedDateFrom!)
                          : 'Дата от',
                    ),
                  ),
                ),
                const SizedBox(width: AppPadding.small),
                // Фильтр по дате до
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDateTo ?? DateTime.now(),
                        firstDate: _selectedDateFrom ?? DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          _selectedDateTo = date;
                        });
                        controller.setDateRange(_selectedDateFrom, _selectedDateTo);
                      }
                    },
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      _selectedDateTo != null
                          ? DateFormat('dd.MM.yyyy').format(_selectedDateTo!)
                          : 'Дата до',
                    ),
                  ),
                ),
                const SizedBox(width: AppPadding.small),
                // Фильтр по статусу
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Статус',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppPadding.small,
                        vertical: AppPadding.xs,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Все статусы')),
                      DropdownMenuItem(value: 'SENT_TO_LANDFILL', child: Text('Отправлен')),
                      DropdownMenuItem(value: 'CONFIRMED_BY_LANDFILL', child: Text('Подтверждён')),
                      DropdownMenuItem(value: 'REJECTED', child: Text('Отклонён')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus = value;
                      });
                      controller.setStatusFilter(value);
                    },
                  ),
                ),
                const SizedBox(width: AppPadding.small),
                // Кнопка сброса фильтров
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _selectedDateFrom = null;
                      _selectedDateTo = null;
                      _selectedStatus = null;
                    });
                    controller.setDateRange(null, null);
                    controller.setStatusFilter(null);
                  },
                  tooltip: 'Сбросить фильтры',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppPadding.normal),
          // Список актов
          Expanded(
            child: state.acts.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Ошибка загрузки данных: $error',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: AppPadding.normal),
                    ElevatedButton(
                      onPressed: controller.refresh,
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              ),
              data: (acts) {
                if (acts.isEmpty) {
                  return Center(
              child: Text(
                      'Нет актов',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(AppPadding.normal),
                  itemCount: acts.length,
                  itemBuilder: (context, index) {
                    final act = acts[index];
                    return _buildActCard(act, controller);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActCard(Act act, LandfillActsController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppPadding.normal),
      padding: const EdgeInsets.all(AppPadding.normal),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSize.cardRadius),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Акт №${act.actNumber}',
                      style: AppTextStyles.title2,
                    ),
                    const SizedBox(height: AppPadding.xs),
                    Text(
                      'Период: ${DateFormat('dd.MM.yyyy').format(act.periodStart)} - ${DateFormat('dd.MM.yyyy').format(act.periodEnd)}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppPadding.small,
                  vertical: AppPadding.xs,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(act.status).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppSize.smallRadius),
                ),
                child: Text(
                  _getStatusLabel(act.status),
                  style: AppTextStyles.caption.copyWith(
                    color: _getStatusColor(act.status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppPadding.normal),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Объём', '${act.totalVolumeM3.toStringAsFixed(2)} м³'),
              ),
              Expanded(
                child: _buildStatItem('Сумма', '${act.totalWithVat.toStringAsFixed(2)} ₸'),
              ),
            ],
          ),
          if (act.status == ActStatus.sentToLandfill) ...[
            const SizedBox(height: AppPadding.normal),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _showApproveDialog(act, controller),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Подтвердить'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ),
                const SizedBox(width: AppPadding.small),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRejectDialog(act, controller),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Отклонить'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppPadding.xs),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(ActStatus status) {
    switch (status) {
      case ActStatus.sentToLandfill:
        return Colors.orange;
      case ActStatus.confirmedByLandfill:
        return Colors.blue;
      case ActStatus.approvedByKgu:
        return Colors.green;
      case ActStatus.rejected:
        return Colors.red;
      case ActStatus.signed:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(ActStatus status) {
    switch (status) {
      case ActStatus.sentToLandfill:
        return 'Отправлен';
      case ActStatus.confirmedByLandfill:
        return 'Подтверждён';
      case ActStatus.approvedByKgu:
        return 'Утверждён КГУ';
      case ActStatus.rejected:
        return 'Отклонён';
      case ActStatus.signed:
        return 'Подписан';
      default:
        return 'Черновик';
    }
  }

  Future<void> _showApproveDialog(Act act, LandfillActsController controller) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтвердить акт'),
        content: const Text('Вы уверены, что хотите подтвердить этот акт?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Подтвердить'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await controller.approveAct(act.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Акт подтверждён')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка: $e')),
          );
        }
      }
    }
  }

  Future<void> _showRejectDialog(Act act, LandfillActsController controller) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отклонить акт'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Укажите причину отклонения:'),
            const SizedBox(height: AppPadding.normal),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Причина',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              if (reasonController.text.trim().isNotEmpty) {
                Navigator.of(context).pop(true);
  }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Отклонить'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await controller.rejectAct(act.id, reason: reasonController.text.trim());
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Акт отклонён')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка: $e')),
          );
        }
      }
    }
  }
}
