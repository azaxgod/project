import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_textstyle.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_data_table.dart';
import 'package:akimat_project/services/organizations/model/user_dto.dart';
import 'package:flutter/material.dart';

class UserTable extends StatelessWidget {
  const UserTable({
    super.key,
    required this.users,
    required this.onBlock,
    required this.onUnblock,
    required this.onResetPassword,
    required this.onEdit,
  });

  final List<UserDto> users;
  final Future<void> Function(String userId, String? blockReason) onBlock;
  final Future<void> Function(String userId) onUnblock;
  final Future<String> Function(String userId) onResetPassword;
  final Future<void> Function(UserDto user) onEdit;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: OrganizationsDataTable(
          columns: const [
            DataColumn(label: Text('Телефон')),
            DataColumn(label: Text('Логин')),
            DataColumn(label: Text('Роль')),
            DataColumn(label: Text('Статус')),
            DataColumn(label: Text('Причина блокировки')),
            DataColumn(label: Text('Действия')),
          ],
          rows: users.map((user) {
            final isBlocked = !user.isActive;
            return DataRow(
              cells: [
                DataCell(Text(user.phone)),
                DataCell(Text(user.login ?? '—')),
                DataCell(Text(user.role)),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isBlocked
                          ? Colors.red.withOpacity(0.2)
                          : Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isBlocked ? 'Заблокирован' : 'Активен',
                      style: TextStyle(
                        color: isBlocked ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    user.blockReason ?? '—',
                    style: AppTextStyles.caption.copyWith(
                      color: user.blockReason != null
                          ? Colors.red
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () => onEdit(user),
                        child: const Text('Изменить'),
                      ),
                      if (isBlocked)
                        TextButton(
                          onPressed: () => onUnblock(user.id),
                          child: const Text('Разблокировать'),
                        )
                      else
                        TextButton(
                          onPressed: () async {
                            final reason = await _showBlockDialog(context);
                            if (reason != null) {
                              await onBlock(user.id, reason);
                            }
                          },
                          child: const Text('Заблокировать'),
                        ),
                      TextButton(
                        onPressed: () async {
                          final newPassword = await onResetPassword(user.id);
                          if (context.mounted) {
                            _showPasswordDialog(context, newPassword);
                          }
                        },
                        child: const Text('Сбросить пароль'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<String?> _showBlockDialog(BuildContext context) async {
    final reasonController = TextEditingController();
    return showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Блокировка пользователя'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Укажите причину блокировки (необязательно):'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Причина блокировки',
                hintText: 'Нарушение правил использования системы',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(
              reasonController.text.trim().isEmpty
                  ? null
                  : reasonController.text.trim(),
            ),
            child: const Text('Заблокировать'),
          ),
        ],
      ),
    );
  }

  void _showPasswordDialog(BuildContext context, String password) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Новый пароль'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Пароль успешно сброшен. Новый пароль:'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.secondaryBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                password,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Скопируйте пароль и передайте пользователю.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
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



