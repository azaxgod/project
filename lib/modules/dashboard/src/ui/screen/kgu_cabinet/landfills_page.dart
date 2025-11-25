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
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_tab_header.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_table_actions.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/dialogs/organizations_details_dialogs.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/dialogs/organizations_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LandfillsPage extends ConsumerWidget {
  const LandfillsPage({
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

    return Container(
      margin: EdgeInsets.all(config.padding),
      child: state.data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => OrganizationsErrorState(
          message: s.failed_to_load_data(error),
          onRetry: ref.read(organizationsControllerProvider.notifier).refresh,
        ),
        data: (data) {
          // Фильтруем только LANDFILL организации (TOO)
          final landfills = data.organizations
              .where((org) => org.type == OrganizationType.too)
              .toList();

          // Подсчитываем количество полигонов для каждой организации
          final landfillsWithPolygonCount = landfills.map((landfill) {
            final polygonCount = data.polygons
                .where((polygon) => polygon.organizationId == landfill.id)
                .length;
            return _LandfillWithPolygonCount(
              organization: landfill,
              polygonCount: polygonCount,
            );
          }).toList();

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
                  title: 'Организации приёма снега (LANDFILL)',
                  subtitle: 'Управление организациями приёма снега',
                  actionLabel: '+ Создать организацию приёма снега',
                  onAction: () => OrganizationsDialogs.showOrganizationDialog(
                    context: context,
                    controller: ref.read(organizationsControllerProvider.notifier),
                    data: data,
                    type: OrganizationType.too,
                  ),
                ),
              ),
              const SizedBox(height: AppPadding.large),
              // Контент
              Expanded(
                child: landfillsWithPolygonCount.isEmpty
                    ? const OrganizationsEmptyState(
                        title: 'Нет организаций приёма снега',
                        message: 'Создайте организацию приёма снега для начала работы.',
                      )
                    : SingleChildScrollView(
                        child: OrganizationsDataTable(
                          columns: const [
                            DataColumn(label: Text('Название ТОО')),
                            DataColumn(label: Text('БИН')),
                            DataColumn(label: Text('Город')),
                            DataColumn(label: Text('Количество полигонов')),
                            DataColumn(label: Text('Статус')),
                            DataColumn(label: Text('Действия')),
                          ],
                          rows: landfillsWithPolygonCount.map((item) {
                            final organization = item.organization;
                            return DataRow(
                              cells: [
                                DataCell(Text(organization.name)),
                                DataCell(Text(organization.bin)),
                                DataCell(Text(organization.city ?? '—')),
                                DataCell(Text(item.polygonCount.toString())),
                                DataCell(OrganizationsStatusChip(isActive: organization.isActive)),
                                DataCell(
                                  OrganizationsTableActions(
                                    actions: [
                                      OrganizationsTableAction(
                                        label: 'Подробнее',
                                        onPressed: () => OrganizationsDetailsDialogs.showOrganizationDetails(
                                          context: context,
                                          organization: organization,
                                          data: data,
                                        ),
                                      ),
                                      OrganizationsTableAction(
                                        label: organization.isActive ? 'Блокировать' : 'Разблокировать',
                                        isDestructive: organization.isActive,
                                        onPressed: () => ref.read(organizationsControllerProvider.notifier).updateOrganization(
                                          organization.copyWith(isActive: !organization.isActive),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LandfillWithPolygonCount {
  final dynamic organization;
  final int polygonCount;

  _LandfillWithPolygonCount({
    required this.organization,
    required this.polygonCount,
  });
}
