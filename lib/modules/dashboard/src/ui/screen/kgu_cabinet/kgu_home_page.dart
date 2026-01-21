import 'package:akimat_project/core/platform/platform_utils.dart';
import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/core/ui/app_textstyle.dart';
import 'package:akimat_project/modules/analytics/src/ui/widgets/anpr_section.dart';
import 'package:akimat_project/modules/auth/src/controller/auth_notifier.dart';
import 'package:akimat_project/modules/dashboard/src/ui/widgets/home_contractors_snow_dashboard_card.dart';
import 'package:akimat_project/modules/dashboard/src/ui/widgets/home_snow_charts_section.dart';
import 'package:akimat_project/modules/dashboard/src/ui/widgets/last_trips_home_card.dart';
import 'package:akimat_project/modules/dashboard/src/ui/widgets/home_areas_contractors_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/user_role.dart';

class KguHomePage extends StatelessWidget {
  const KguHomePage({
    super.key,
    required this.scaffoldKey,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;

  @override
  Widget build(BuildContext context) {
    final config = PlatformConfig.instance;

    return Container(
      margin: EdgeInsets.all(config.padding),
      child: SingleChildScrollView(
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
                          'Главная',
                          style: AppTextStyles.title1,
                        ),
                        const SizedBox(height: AppPadding.xs),
                        Text(
                          'Дашборд КГУ ЖКХ',
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
            const SizedBox(height: AppPadding.large),

            // ---------------- Графики (самый верхний блок) ----------------
            const HomeSnowChartsSection(days: 7),
            const SizedBox(height: AppPadding.large),

            // ---------------- ANPR — Распознавание номеров (самый верхний блок) ----------------
            Consumer(
              builder: (context, ref, _) {
                final authState = ref.watch(authNotifierProvider);
                final userRole = userRoleFromString(authState.user?.role);

                if (userRole != UserRole.kguZkhAdmin &&
                    userRole != UserRole.akimatAdmin &&
                    userRole != UserRole.contractorAdmin) {
                  return const SizedBox.shrink();
                }

                final now = DateTime.now();
                final anprDateFrom = now.subtract(const Duration(hours: 24));

                final contractorId = userRole == UserRole.contractorAdmin
                    ? authState.user?.organizationId
                    : null;

                return Column(
                  children: [
                    AnprSection(
                      dateFrom: anprDateFrom,
                      dateTo: now,
                      contractorId: contractorId,
                      showReports: false,
                      showEvents: false,
                    ),
                    const LastTripsHomeCard(limit: 5),
                    const SizedBox(height: AppPadding.large),
                  ],
                );
              },
            ),

            // ---------------- Подрядчики (самый верхний блок) ----------------
            const HomeContractorsSnowDashboardCard(
              hours: 24,
              maxItems: 10,
            ),
            const SizedBox(height: AppPadding.large),
            
            // KPI карточки
            Text(
              'Метрики',
              style: AppTextStyles.title2,
            ),
            const SizedBox(height: AppPadding.normal),
            const HomeAreasContractorsCard(),
            const SizedBox(height: AppPadding.large),

            // Напоминания
            Text(
              'Напоминания',
              style: AppTextStyles.title2,
            ),
            const SizedBox(height: AppPadding.normal),
            Container(
              padding: const EdgeInsets.all(AppPadding.large),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(AppSize.cardRadius),
                border: Border.all(color: AppColors.divider, width: 0.5),
              ),
              child: Text(
                'Здесь будут отображаться напоминания о не сформированных актах',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

