import 'package:akimat_project/core/locale/locale_provider.dart';
import 'package:akimat_project/core/navbar/drawer_mobile.dart';
import 'package:akimat_project/core/navbar/navbar_widgets_provider.dart';
import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/core/ui/app_textstyle.dart';
import 'package:akimat_project/l10n/l10n.dart';
import 'package:akimat_project/modules/analytics/src/controller/analytics_providers.dart';
import 'package:akimat_project/modules/dashboard/src/controller/dashboard_controller.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/akimat_dashboard/widgets/kpi_card.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/akimat_dashboard/widgets/map_widget.dart';
import 'package:akimat_project/modules/dashboard/src/ui/widgets/snow_reports_home_card.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:akimat_project/core/platform/platform_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class AkimatHome extends ConsumerWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final List<Widget>? webNavbarWidgets;
  final List<Widget>? mobileNavbarWidgets;

  const AkimatHome({
    super.key,
    required this.scaffoldKey,
    this.webNavbarWidgets,
    this.mobileNavbarWidgets,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch locale to ensure rebuild when language changes
    ref.watch(localeProvider);
    final s = S.of(context)!;
    final config = PlatformConfig.instance;

    final state = ref.watch(akimatHomeControllerProvider);
    final anprState = ref.watch(anprControllerProvider);

    return Scaffold(
      key: scaffoldKey,
      drawer: !kIsWeb ? const DrawerMobile() : null,
      appBar: kIsWeb
          ? null
          : AppBar(
              title: Text(s.main),
              leading: Builder(
                builder: (context) {
                  return IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  );
                },
              ),
              actions: NavbarWidgetsProvider.combineMobileWidgets(
                context,
                mobileNavbarWidgets,
              ),
            ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (kIsWeb) const VerticalDivider(thickness: 1, width: 1),
          Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(config.padding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (config.topOffset > 0)
                          SizedBox(height: config.topOffset),
                        Container(
                          padding: const EdgeInsets.all(AppPadding.large),
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(AppSize.cardRadius),
                            border: Border.all(
                              color: AppColors.divider,
                              width: 0.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(10),
                                blurRadius: AppSize.shadowBlur,
                                offset: const Offset(0, 2),
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AppPadding.normal),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withAlpha(26),
                                  borderRadius: BorderRadius.circular(AppSize.smallRadius),
                                ),
                                child: Icon(
                                  Icons.dashboard,
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
                                      s.main_panel,
                                      style: AppTextStyles.title1,
                                    ),
                                    const SizedBox(height: AppPadding.xs),
                                    Text(
                                      'SnowOps Control System',
                                      style: AppTextStyles.footnote,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppPadding.large),

                        // ---------------- KPI карточки ----------------
                        SizedBox(
                          height: 140,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: state.kpiCards.length,
                            itemBuilder: (context, index) {
                              final kpi = state.kpiCards[index];
                              return KpiCardWidget(
                               // data: kpi,
                                onTap: kpi.clickable
                                    ? () {
                                        // действие при клике, если нужно
                                      }
                                    : null,
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ---------------- Дополнительные платформенные виджеты ----------------
                        SnowReportsHomeCard(compact: !config.showExtraWidget),
                        const SizedBox(height: AppPadding.large),

                        // ---------------- Карта ----------------
              if (state.polygons.isNotEmpty)
  SizedBox(
    height: 300,
    child: MapWidget(
      polygons: state.polygons
          .map((p) => PolygonData(
                name: p.name,
                contractor: p.contractor,
                status: p.status,
                color: p.color,
              ))
          .toList(),
    ),
  ),
const SizedBox(height: 16),

                        // ---------------- Последние рейсы ----------------
                        Container(
                          padding: const EdgeInsets.all(AppPadding.large),
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(AppSize.cardRadius),
                            border: Border.all(
                              color: AppColors.divider,
                              width: 0.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(10),
                                blurRadius: AppSize.shadowBlur,
                                offset: const Offset(0, 2),
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(AppPadding.small),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withAlpha(26),
                                      borderRadius: BorderRadius.circular(AppSize.smallRadius),
                                    ),
                                    child: Icon(
                                      Icons.directions_car,
                                      color: AppColors.primary,
                                      size: AppSize.iconSize,
                                    ),
                                  ),
                                  const SizedBox(width: AppPadding.normal),
                                  Text(
                                    s.last_trips,
                                    style: AppTextStyles.title2,
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppPadding.normal),
                              Builder(
                                builder: (context) {
                                  final reports = anprState.reports;
                                  if (reports == null) {
                                    return const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(32),
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }

                                  return reports.when(
                                    data: (reportData) {
                                      final events = reportData.events.take(5).toList();
                                      if (events.isEmpty) {
                                        return Center(
                                          child: Padding(
                                            padding: const EdgeInsets.all(32),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.inbox_outlined,
                                                  size: 64,
                                                  color: AppColors.textSecondary.withAlpha(77),
                                                ),
                                                const SizedBox(height: AppPadding.normal),
                                                Text(
                                                  'Нет данных о рейсах',
                                                  style: AppTextStyles.body.copyWith(
                                                    color: AppColors.textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }

                                      return Column(
                                        children: [
                                          for (final e in events)
                                            Padding(
                                              padding: const EdgeInsets.only(bottom: AppPadding.small),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          e.plateNumber,
                                                          style: AppTextStyles.body.copyWith(
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 2),
                                                        Text(
                                                          DateFormat('dd.MM.yyyy HH:mm').format(e.eventTime.toLocal()),
                                                          style: AppTextStyles.caption.copyWith(
                                                            color: AppColors.textSecondary,
                                                          ),
                                                        ),
                                                        if ((e.vehicleBrand != null && e.vehicleBrand!.trim().isNotEmpty) ||
                                                            (e.vehicleModel != null && e.vehicleModel!.trim().isNotEmpty))
                                                          Text(
                                                            '${e.vehicleBrand ?? ''} ${e.vehicleModel ?? ''}'.trim(),
                                                            style: AppTextStyles.caption.copyWith(
                                                              color: AppColors.textSecondary,
                                                            ),
                                                          ),
                                                        if (e.contractorName != null && e.contractorName!.trim().isNotEmpty)
                                                          Text(
                                                            e.contractorName!,
                                                            style: AppTextStyles.caption.copyWith(
                                                              color: AppColors.textSecondary,
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                  if (e.snowVolumeM3 != null)
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: AppPadding.small,
                                                        vertical: AppPadding.xs,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.cyan.withAlpha(26),
                                                        borderRadius: BorderRadius.circular(AppSize.smallRadius),
                                                      ),
                                                      child: Text(
                                                        '${e.snowVolumeM3!.toStringAsFixed(1)} м³',
                                                        style: AppTextStyles.body.copyWith(
                                                          color: Colors.cyan,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      );
                                    },
                                    loading: () => const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(32),
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                                    error: (error, stack) => Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(32),
                                        child: Text(
                                          error.toString(),
                                          style: AppTextStyles.body.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        // ],
      // ),
    // );
  }
}
