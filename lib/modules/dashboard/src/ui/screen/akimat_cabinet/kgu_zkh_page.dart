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
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_data_table.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_empty_state.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_error_state.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_status_chip.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_table_actions.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/dialogs/organizations_details_dialogs.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/dialogs/organizations_dialogs.dart';
import 'package:akimat_project/services/organizations/module.dart';
import 'package:akimat_project/services/organizations/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class KguZkhPage extends ConsumerWidget {
  const KguZkhPage({
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
    final authState = ref.watch(authNotifierProvider);
    final isSuperAdmin = authState.user?.role == 'AKIMAT_ADMIN';
    final state = ref.watch(organizationsControllerProvider);
    final config = PlatformConfig.instance;

    return Scaffold(
      key: scaffoldKey,
      body: state.data.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => OrganizationsErrorState(
                message: s.failed_to_load_data(error),
                onRetry: ref.read(organizationsControllerProvider.notifier).refresh,
              ),
              data: (data) {
                final kguOrganizations = data.organizations
                    .where((org) => org.type == OrganizationType.kguZkh)
                    .toList();

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
                            bottom: BorderSide(
                              color: AppColors.divider,
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppPadding.normal),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(
                                  AppSize.smallRadius,
                                ),
                              ),
                              child: Icon(
                                Icons.business,
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
                                    'KGU ЖКХ',
                                    style: AppTextStyles.title1,
                                  ),
                                  const SizedBox(height: AppPadding.xs),
                                  Text(
                                    'Управление КГУ ЖКХ',
                                    style: AppTextStyles.footnote.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSuperAdmin && kguOrganizations.isEmpty)
                              FilledButton.icon(
                                onPressed: () => OrganizationsDialogs.showOrganizationDialog(
                                  context: context,
                                  controller: ref.read(organizationsControllerProvider.notifier),
                                  type: OrganizationType.kguZkh,
                                  data: data,
                                ),
                                icon: const Icon(Icons.add),
                                label: const Text('Создать KGU ЖКХ'),
                              ),
                          ],
                        ),
                      ),
                      // Content
                      Expanded(
                        child: kguOrganizations.isEmpty
                            ? OrganizationsEmptyState(
                                title: 'Нет KGU ЖКХ',
                                message: isSuperAdmin
                                    ? 'Нажмите "Создать KGU ЖКХ", чтобы добавить организацию'
                                    : 'KGU ЖКХ еще не создан',
                              )
                            : Padding(
                                padding: EdgeInsets.all(
                                  kIsWeb ? AppPadding.large : AppPadding.normal,
                                ),
                                child: _buildKguList(
                                  context,
                                  ref,
                                  kguOrganizations,
                                  data,
                                  isSuperAdmin,
                                ),
                              ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildKguList(
    BuildContext context,
    WidgetRef ref,
    List<dynamic> kguOrganizations,
    dynamic data,
    bool isSuperAdmin,
  ) {
    return ListView.builder(
      itemCount: kguOrganizations.length,
      itemBuilder: (context, index) {
        final kgu = kguOrganizations[index];

        return Card(
          margin: const EdgeInsets.only(bottom: AppPadding.normal),
          child: ListTile(
            contentPadding: const EdgeInsets.all(AppPadding.normal),
            leading: Container(
              padding: const EdgeInsets.all(AppPadding.normal),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSize.smallRadius),
              ),
              child: Icon(
                Icons.business,
                color: AppColors.primary,
                size: AppSize.iconSizeLarge,
              ),
            ),
            title: Text(
              kgu.name,
              style: AppTextStyles.title2,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppPadding.small),
                Row(
                  children: [
                    Icon(
                      Icons.location_city,
                      size: AppSize.iconSizeSmall,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppPadding.xs),
                    Text(
                      kgu.address ?? 'Город не указан',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppPadding.xs),
                Row(
                  children: [
                    OrganizationsStatusChip(isActive: kgu.isActive),
                  ],
                ),
              ],
            ),
            trailing: isSuperAdmin
                ? IconButton(
                    icon: const Icon(Icons.info_outline),
                    onPressed: () => OrganizationsDetailsDialogs.showOrganizationDetails(
                      context: context,
                      organization: kgu,
                      data: data,
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }
}

