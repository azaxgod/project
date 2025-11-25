import 'package:akimat_project/core/locale/locale_provider.dart';
import 'package:akimat_project/core/platform/platform_utils.dart';
import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/core/ui/app_textstyle.dart';
import 'package:akimat_project/l10n/l10n.dart';
import 'package:akimat_project/modules/dashboard/src/controller/organizations_controller.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/driver.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/contractor_cabinet/widgets/vehicle_card.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_empty_state.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_error_state.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_tab_header.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/dialogs/organizations_dialogs.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/dialogs/organizations_details_dialogs.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ContractorVehiclesPage extends ConsumerWidget {
  const ContractorVehiclesPage({
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

    return state.data.when(
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

        // Фильтруем транспорт
        final vehicles = data.vehicles
            .where((vehicle) => vehicle.contractorId.toLowerCase().trim() == state.organizationId!.toLowerCase().trim())
            .toList();

        debugPrint('ContractorVehiclesPage: Filtered ${vehicles.length} vehicles');

        return SizedBox.expand(
          child: Container(
            margin: EdgeInsets.all(config.padding),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(AppSize.cardRadius),
              border: Border.all(color: AppColors.divider, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Заголовок
              Padding(
                padding: const EdgeInsets.all(AppPadding.large),
                child: OrganizationsTabHeader(
                  title: 'Техника',
                  subtitle: 'Управление техникой подрядчика',
                  actionLabel: '+ Добавить транспорт',
                  onAction: () => OrganizationsDialogs.showVehicleDialog(
                    context: context,
                    controller: ref.read(organizationsControllerProvider.notifier),
                    data: data,
                    contractorId: state.organizationId!,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Контент
              if (vehicles.isEmpty)
                const Expanded(
                  child: OrganizationsEmptyState(
                    title: 'Нет транспорта',
                    message: 'Добавьте транспорт, чтобы закреплять водителей.',
                  ),
                )
              else
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppPadding.large),
                    child: ListView.builder(
                      itemCount: vehicles.length,
                      itemBuilder: (context, index) {
                        final vehicle = vehicles[index];
                        Driver? driver;
                        if (vehicle.driverId != null && vehicle.driverId!.isNotEmpty) {
                          try {
                            driver = data.drivers.firstWhere(
                              (d) => d.id == vehicle.driverId,
                            );
                          } catch (e) {
                            debugPrint('Driver not found for vehicle ${vehicle.id}: $e');
                            driver = null;
                          }
                        }

                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: index < vehicles.length - 1 ? AppPadding.normal : 0,
                          ),
                          child: VehicleCard(
                            vehicle: vehicle,
                            driver: driver,
                            onTap: () {
                              try {
                                OrganizationsDetailsDialogs.showVehicleDetails(
                                  context: context,
                                  vehicle: vehicle,
                                  driver: driver ?? Driver(
                                    id: '',
                                    contractorId: '',
                                    fullName: 'Не назначен',
                                    iin: '',
                                    phone: '',
                                    isActive: false,
                                  ),
                                );
                              } catch (e) {
                                debugPrint('Error showing vehicle details: $e');
                              }
                            },
                            onEdit: () {
                              try {
                                OrganizationsDialogs.showVehicleDialog(
                                  context: context,
                                  controller: ref.read(organizationsControllerProvider.notifier),
                                  data: data,
                                  contractorId: vehicle.contractorId,
                                  vehicle: vehicle,
                                );
                              } catch (e) {
                                debugPrint('Error showing vehicle edit dialog: $e');
                              }
                            },
                            onAssignDriver: () {
                              try {
                                OrganizationsDialogs.showAssignDriverDialog(
                                  context: context,
                                  controller: ref.read(organizationsControllerProvider.notifier),
                                  data: data,
                                  vehicle: vehicle,
                                );
                              } catch (e) {
                                debugPrint('Error showing assign driver dialog: $e');
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
