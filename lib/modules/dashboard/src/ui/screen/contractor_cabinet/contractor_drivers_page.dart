import 'package:akimat_project/core/locale/locale_provider.dart';
import 'package:akimat_project/core/platform/platform_utils.dart';
import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/core/ui/app_textstyle.dart';
import 'package:akimat_project/l10n/l10n.dart';
import 'package:akimat_project/modules/dashboard/src/controller/organizations_controller.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_error_state.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/tabs/organizations_drivers_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ContractorDriversPage extends ConsumerWidget {
  const ContractorDriversPage({
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
                if (state.organizationId == null) {
                  return Center(
                    child: Text(
                      'Организация подрядчика не найдена',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                }

                return Container(
                  margin: EdgeInsets.all(config.padding),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(AppSize.cardRadius),
                    border: Border.all(color: AppColors.divider, width: 0.5),
                  ),
                  child: Column(
                    children: [
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
                                Icons.person,
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
                                    'Водители',
                                    style: AppTextStyles.title1,
                                  ),
                                  const SizedBox(height: AppPadding.xs),
                                  Text(
                                    'Управление водителями подрядчика',
                                    style: AppTextStyles.footnote.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: OrganizationsDriversTab(
                          data: data,
                          controller: ref.read(organizationsControllerProvider.notifier),
                          canManage: true,
                          organizationId: state.organizationId,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

