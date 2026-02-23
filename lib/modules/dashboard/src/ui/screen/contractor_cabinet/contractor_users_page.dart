import 'package:akimat_project/core/locale/locale_provider.dart';
import 'package:akimat_project/core/platform/platform_utils.dart';
import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/core/ui/app_textstyle.dart';
import 'package:akimat_project/modules/dashboard/src/controller/users/contractor_users_controller.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/users/widgets/create_user_dialog.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/users/widgets/user_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ContractorUsersPage extends ConsumerWidget {
  const ContractorUsersPage({
    super.key,
    required this.scaffoldKey,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localeProvider);
    final config = PlatformConfig.instance;
    final state = ref.watch(contractorUsersControllerProvider);
    final controller = ref.read(contractorUsersControllerProvider.notifier);

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
                    Icons.people,
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
                        'Пользователи',
                        style: AppTextStyles.title1,
                      ),
                      const SizedBox(height: AppPadding.xs),
                      Text(
                        'Управление пользователями подрядчика',
                        style: AppTextStyles.footnote.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: () {
                    CreateUserDialog.show(
                      context: context,
                      controller: controller,
                      userType: 'CONTRACTOR_USER',
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Создать пользователя'),
                ),
                const SizedBox(width: AppPadding.small),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: controller.refresh,
                  tooltip: 'Обновить',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppPadding.large),
          // Таблица пользователей
          Expanded(
            child: state.data.when(
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
              data: (users) => users.isEmpty
                  ? Center(
                      child: Text(
                        'Нет пользователей',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  : UserTable(
                      users: users,
                      resetPasswords: state.resetPasswords,
                      onBlock: (userId, blockReason) => controller.blockUser(
                        userId,
                        blockReason: blockReason,
                      ),
                      onUnblock: (userId) => controller.unblockUser(userId),
                      onResetPassword: (userId) => controller.resetPassword(userId),
                      onEdit: (user) => CreateUserDialog.show(
                        context: context,
                        controller: controller,
                        userType: 'CONTRACTOR_USER',
                        user: user,
                      ),
                      onClearPassword: (userId) => controller.clearPassword(userId),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

