import 'package:akimat_project/core/locale/locale_provider.dart';
import 'package:akimat_project/core/navbar/drawer_mobile.dart';
import 'package:akimat_project/core/navbar/navbar_widgets_provider.dart';
import 'package:akimat_project/core/platform/platform_utils.dart';
import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/core/ui/app_textstyle.dart';
import 'package:akimat_project/l10n/l10n.dart';
import 'package:akimat_project/modules/dashboard/src/controller/users/akimat_users_controller.dart';
import 'package:akimat_project/modules/dashboard/src/controller/users/akimat_users_state.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/users/widgets/create_user_dialog.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/users/widgets/user_table.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_error_state.dart';
import 'package:akimat_project/services/organizations/model/user_dto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AkimatUsersPage extends ConsumerWidget {
  const AkimatUsersPage({
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
    final state = ref.watch(akimatUsersControllerProvider);
    final controller = ref.watch(akimatUsersControllerProvider.notifier);
    final config = PlatformConfig.instance;

    return Scaffold(
      key: scaffoldKey,
      drawer: !kIsWeb ? const DrawerMobile() : null,
      appBar: kIsWeb
          ? null
          : AppBar(
              title: const Text('Пользователи Акимата'),
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
      body: state.data.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => OrganizationsErrorState(
                message: s.failed_to_load_data(error),
                onRetry: controller.refresh,
              ),
              data: (users) => _AkimatUsersContent(
                config: config,
                state: state,
                users: users,
                controller: controller,
              ),
            ),
      // ),
    );
  }
}

class _AkimatUsersContent extends ConsumerWidget {
  const _AkimatUsersContent({
    required this.config,
    required this.state,
    required this.users,
    required this.controller,
  });

  final PlatformConfig config;
  final AkimatUsersState state;
  final List<UserDto> users;
  final AkimatUsersController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context)!;

    return Container(
      margin: EdgeInsets.all(config.padding),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSize.cardRadius),
        border: Border.all(color: AppColors.divider, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
                    'Пользователи Акимата',
                    style: AppTextStyles.title1,
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => CreateUserDialog.show(
                    context: context,
                    controller: controller,
                    userType: 'AKIMAT_USER',
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Создать пользователя'),
                ),
              ],
            ),
          ),
          // Table
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(kIsWeb ? AppPadding.large : AppPadding.normal),
              child: users.isEmpty
                  ? Center(
                      child: Text(
                        'Нет пользователей',
                        style: AppTextStyles.body,
                      ),
                    )
                  : UserTable(
                      users: users,
                      onBlock: (userId, blockReason) => controller.blockUser(
                        userId,
                        blockReason: blockReason,
                      ),
                      onUnblock: (userId) => controller.unblockUser(userId),
                      onResetPassword: (userId) => controller.resetPassword(userId),
                      onEdit: (user) => CreateUserDialog.show(
                        context: context,
                        controller: controller,
                        userType: 'AKIMAT_USER',
                        user: user,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

