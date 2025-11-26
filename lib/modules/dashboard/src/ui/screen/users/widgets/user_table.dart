import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_textstyle.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_data_table.dart';
import 'package:akimat_project/services/organizations/model/user_dto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UserTable extends StatelessWidget {
  const UserTable({
    super.key,
    required this.users,
    required this.onBlock,
    required this.onUnblock,
    required this.onResetPassword,
    required this.onEdit,
    this.resetPasswords = const {},
    this.onClearPassword,
  });

  final List<UserDto> users;
  final Future<void> Function(String userId, String? blockReason) onBlock;
  final Future<void> Function(String userId) onUnblock;
  final Future<String> Function(String userId) onResetPassword;
  final Future<void> Function(UserDto user) onEdit;
  final Map<String, String> resetPasswords;
  final void Function(String userId)? onClearPassword;

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
                          onPressed: user.id.isEmpty ? null : () async {
                            if (user.id.isEmpty) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Ошибка: ID пользователя отсутствует. Обновите список.'),
                                    backgroundColor: Colors.red,
                                    duration: Duration(seconds: 4),
                                  ),
                                );
                              }
                              return;
                            }
                            
                            // Показываем индикатор загрузки
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Разблокировка пользователя...'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            }
                            
                            try {
                              // Используем ID из объекта пользователя
                              final userId = user.id.trim();
                              if (userId.isEmpty) {
                                throw Exception('ID пользователя пустой');
                              }
                              
                              await onUnblock(userId);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Пользователь успешно разблокирован'),
                                    backgroundColor: Colors.green,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                final errorMessage = e.toString()
                                    .replaceAll('Exception: ', '')
                                    .replaceAll('RolesException: ', '');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Ошибка при разблокировке: $errorMessage\nID: ${user.id}'),
                                    backgroundColor: Colors.red,
                                    duration: const Duration(seconds: 5),
                                  ),
                                );
                              }
                            }
                          },
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
                      Builder(
                        builder: (context) {
                          final resetPassword = resetPasswords[user.id];
                          if (resetPassword != null) {
                            // Показываем пароль рядом с кнопкой
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.green.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.lock_reset,
                                        size: 16,
                                        color: Colors.green.shade700,
                                      ),
                                      const SizedBox(width: 8),
                                      SelectableText(
                                        resetPassword,
                                        style: AppTextStyles.caption.copyWith(
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade700,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        onPressed: () {
                                          Clipboard.setData(
                                            ClipboardData(text: resetPassword),
                                          );
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text('Пароль скопирован'),
                                              duration: Duration(seconds: 1),
                                            ),
                                          );
                                        },
                                        icon: Icon(
                                          Icons.copy,
                                          size: 16,
                                          color: Colors.green.shade700,
                                        ),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        tooltip: 'Копировать',
                                      ),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        onPressed: () {
                                          onClearPassword?.call(user.id);
                                        },
                                        icon: Icon(
                                          Icons.close,
                                          size: 16,
                                          color: Colors.green.shade700,
                                        ),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        tooltip: 'Скрыть',
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: () async {
                                    final newPassword =
                                        await onResetPassword(user.id);
                                    if (context.mounted) {
                                      _showPasswordDialog(context, newPassword);
                                    }
                                  },
                                  child: const Text('Сбросить снова'),
                                ),
                              ],
                            );
                          }
                          // Показываем обычную кнопку сброса
                          return TextButton(
                            onPressed: () async {
                              final newPassword = await onResetPassword(user.id);
                              if (context.mounted) {
                                _showPasswordDialog(context, newPassword);
                              }
                            },
                            child: const Text('Сбросить пароль'),
                          );
                        },
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
      barrierDismissible: false,
      builder: (context) => _PasswordDialog(password: password),
    );
  }
}

class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog({required this.password});

  final String password;

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  bool _isCopied = false;

  Future<void> _copyPassword() async {
    await Clipboard.setData(ClipboardData(text: widget.password));
    setState(() {
      _isCopied = true;
    });
    
    // Сбрасываем состояние через 2 секунды
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isCopied = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Пароль успешно сброшен',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Новый пароль был сгенерирован. Скопируйте его и передайте пользователю:',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.secondaryBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.divider,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      widget.password,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        fontSize: 18,
                        letterSpacing: 2,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: _copyPassword,
                    icon: Icon(
                      _isCopied ? Icons.check : Icons.copy,
                      color: _isCopied ? Colors.green : AppColors.textSecondary,
                    ),
                    tooltip: _isCopied ? 'Скопировано!' : 'Копировать',
                    style: IconButton.styleFrom(
                      backgroundColor: _isCopied
                          ? Colors.green.withOpacity(0.1)
                          : AppColors.secondaryBackground,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: Colors.blue.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Важно: Сохраните этот пароль. Он больше не будет показан.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Закрыть'),
        ),
        FilledButton.icon(
          onPressed: _copyPassword,
          icon: Icon(_isCopied ? Icons.check : Icons.copy),
          label: Text(_isCopied ? 'Скопировано!' : 'Копировать пароль'),
          style: FilledButton.styleFrom(
            backgroundColor: _isCopied ? Colors.green : null,
          ),
        ),
      ],
    );
  }
}





