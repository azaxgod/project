import 'package:akimat_project/core/locale/locale_provider.dart';
import 'package:akimat_project/core/platform/platform_utils.dart';
import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/core/ui/app_textstyle.dart';
import 'package:akimat_project/l10n/l10n.dart';
import 'package:akimat_project/modules/auth/src/controller/auth_notifier.dart';
import 'package:akimat_project/modules/dashboard/src/controller/organizations_controller.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/organization_type.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_empty_state.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_error_state.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_tab_header.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/dialogs/organizations_dialogs.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/tabs/organizations_contractors_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ContractorsPage extends ConsumerWidget {
  const ContractorsPage({
    super.key,
    required this.scaffoldKey,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localeProvider);
    final s = S.of(context)!;
    final state = ref.watch(organizationsControllerProvider);
    final config = PlatformConfig.instance;
    final authState = ref.watch(authNotifierProvider);
    final kguOrgId = authState.user?.organizationId;

    return Container(
      margin: EdgeInsets.all(config.padding),
      child: state.data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => OrganizationsErrorState(
          message: s.failed_to_load_data(error),
          onRetry: ref.read(organizationsControllerProvider.notifier).refresh,
        ),
        data: (data) {
          // Фильтруем только подрядчиков (CONTRACTOR)
          final contractors = data.organizations
              .where((org) => org.type == OrganizationType.contractor)
              .toList();

          return Column(
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
                child: OrganizationsTabHeader(
                  title: 'Подрядчики',
                  subtitle: 'Управление подрядчиками КГУ ЖКХ',
                  actionLabel: '+ Создать подрядчика',
                  onAction: () => OrganizationsDialogs.showOrganizationDialog(
                    context: context,
                    controller: ref.read(organizationsControllerProvider.notifier),
                    data: data,
                    type: OrganizationType.contractor,
                    parentOrganizationId: kguOrgId,
                  ),
                ),
              ),
              const SizedBox(height: AppPadding.large),
              // Контент
              Expanded(
                child: contractors.isEmpty
                    ? const OrganizationsEmptyState(
                        title: 'Нет подрядчиков',
                        message: 'Создайте подрядчика для начала работы.',
                      )
                    : OrganizationsContractorsTab(
                        data: data,
                        controller: ref.read(organizationsControllerProvider.notifier),
                        parentOrganizationId: kguOrgId,
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
