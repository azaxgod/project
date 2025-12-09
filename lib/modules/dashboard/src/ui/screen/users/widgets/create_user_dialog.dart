import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/core/utils/notification_helper.dart';
import 'package:akimat_project/modules/dashboard/src/controller/users/users_controller_base.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_text_field.dart';
import 'package:akimat_project/services/organizations/model/user_dto.dart';
import 'package:flutter/material.dart';

class CreateUserDialog {
  static Future<void> show({
    required BuildContext context,
    required UsersControllerBase controller,
    required String userType, // 'AKIMAT_USER', 'KGU_ZKH_USER', 'LANDFILL_USER', 'CONTRACTOR_USER'
    UserDto? user, // Если указан, то редактирование
  }) async {
    final formKey = GlobalKey<FormState>();
    final phoneController = TextEditingController(text: user?.phone ?? '');
    final loginController = TextEditingController(text: user?.login ?? '');
    final passwordController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user == null ? 'Создать пользователя' : 'Изменить пользователя'),
        content: SizedBox(
          width: 400,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OrganizationsTextField(
                    controller: phoneController,
                    label: 'Телефон*',
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Введите номер телефона';
                      }
                      final normalized = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
                      final phonePattern = RegExp(r'^(\+?7|8)?[0-9]{10}$');
                      if (!phonePattern.hasMatch(normalized)) {
                        return 'Введите корректный номер телефона';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppPadding.normal),
                  OrganizationsTextField(
                    controller: loginController,
                    label: 'Логин*',
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Введите логин' : null,
                  ),
                  const SizedBox(height: AppPadding.normal),
                  OrganizationsTextField(
                    controller: passwordController,
                    label: user == null ? 'Пароль*' : 'Новый пароль (оставьте пустым, чтобы не менять)',
                    obscureText: true,
                    validator: user == null
                        ? (value) =>
                            value == null || value.isEmpty ? 'Введите пароль' : null
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              // Нормализация телефона
              String phoneNormalized = phoneController.text.trim()
                  .replaceAll(RegExp(r'[\s\-\(\)]'), '');
              if (phoneNormalized.startsWith('8')) {
                phoneNormalized = '+7${phoneNormalized.substring(1)}';
              } else if (phoneNormalized.startsWith('7') &&
                  !phoneNormalized.startsWith('+7')) {
                phoneNormalized = '+7${phoneNormalized.substring(1)}';
              } else if (!phoneNormalized.startsWith('+7')) {
                phoneNormalized = '+7$phoneNormalized';
              }

              try {
                if (user == null) {
                  // Создание
                  await controller.createUser(
                    phone: phoneNormalized,
                    login: loginController.text.trim(),
                    password: passwordController.text.trim(),
                    skipReload: true,
                  );
                } else {
                  // Редактирование
                  await controller.updateUser(
                    user.id,
                    phone: phoneNormalized,
                    login: loginController.text.trim(),
                    password: passwordController.text.trim().isEmpty
                        ? null
                        : passwordController.text.trim(),
                    skipReload: true,
                  );
                }
                if (context.mounted) {
                  Navigator.of(context).pop();
                  // Показываем уведомление и обновляем данные после 4 секунд
                  await context.showSuccessWithReload(
                    user == null 
                        ? 'Пользователь успешно создан'
                        : 'Данные пользователя успешно обновлены',
                    () async {
                      await controller.refresh();
                    },
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  context.showErrorNotificationFromException(e);
                }
              }
            },
            child: Text(user == null ? 'Создать' : 'Сохранить'),
          ),
        ],
      ),
    );
  }
}





