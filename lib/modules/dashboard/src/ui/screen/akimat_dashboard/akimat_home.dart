import 'package:akimat_project/core/locale/locale_provider.dart';
import 'package:akimat_project/core/navbar/drawer_mobile.dart';
import 'package:akimat_project/core/navbar/navbar_widgets_provider.dart';
import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/core/ui/app_textstyle.dart';
import 'package:akimat_project/l10n/l10n.dart';
import 'package:akimat_project/modules/dashboard/src/controller/dashboard_controller.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/akimat_dashboard/widgets/kpi_card.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/akimat_dashboard/widgets/map_widget.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/akimat_dashboard/widgets/trip_table_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:akimat_project/core/platform/platform_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
            child: RefreshIndicator(
              onRefresh: () async {
                ref.read(akimatHomeControllerProvider.notifier).refreshData();
              },
              child: SingleChildScrollView(
                padding: EdgeInsets.all(config.padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (config.topOffset > 0)
                      SizedBox(height: config.topOffset),
                    
                    // Важная информация
                    _buildImportantInfoSection(state, ref),
                    
                    const SizedBox(height: AppPadding.large),

                    _buildQuickActions(context),

                    const SizedBox(height: AppPadding.large),

                    _buildProjectSummary(state),

                    const SizedBox(height: AppPadding.large),

                    // Заголовок панели
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
                            color: Colors.black.withValues(alpha: 0.04),
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
                              color: AppColors.primary.withValues(alpha: 0.1),
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
                          if (state.isLoading)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppPadding.large),

                    // ---------------- KPI карточки ----------------
                    if (state.error != null)
                      _buildErrorWidget(state.error!, ref)
                    else ...[
                      SizedBox(
                        height: 140,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: state.kpiCards.length,
                          itemBuilder: (context, index) {
                            final kpi = state.kpiCards[index];
                            return KpiCardWidget(
                              data: kpi,
                              onTap: kpi.clickable
                                  ? () {
                                      // Обработка кликов на KPI карточки
                                      if (kpi.title.contains('участки')) {
                                        context.go('/areas');
                                      } else if (kpi.title.contains('тикеты')) {
                                        context.go('/tickets');
                                      } else if (kpi.title.contains('Нарушения')) {
                                        context.go('/violations');
                                      }
                                    }
                                    : null,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ---------------- Дополнительные платформенные виджеты ----------------
                      ...config.showExtraWidget
                          ? [
                              Container(
                                height: 120,
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
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: AppSize.shadowBlur,
                                      offset: const Offset(0, 2),
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    s.additional_web_widget,
                                    style: AppTextStyles.callout.copyWith(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                )
                              )
                            ]
                          : [
                              Container(
                                height: 100,
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
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: AppSize.shadowBlur,
                                      offset: const Offset(0, 2),
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    s.additional_mobile_widget,
                                    style: AppTextStyles.callout.copyWith(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              )
                            ],
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
                              color: Colors.black.withValues(alpha: 0.04),
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
                                    color: AppColors.primary.withValues(alpha: 0.1),
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
                                const Spacer(),
                                TextButton(
                                  onPressed: () => context.go('/analytics/trips'),
                                  child: const Text('Все рейсы'),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppPadding.normal),
                            if (state.lastTrips.isNotEmpty)
                              TripTableWidget(
                                trips: state.lastTrips
                                    .map((t) => TripData(
                                          time: t.time,
                                          contractor: t.contractor,
                                          plate: t.plate,
                                          area: t.area,
                                          polygon: t.polygon,
                                          volume: t.volume,
                                          status: t.status,
                                        ))
                                    .toList(),
                              )
                            else
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.inbox_outlined,
                                        size: 64,
                                        color: AppColors.textSecondary.withValues(alpha: 0.3),
                                      ),
                                      const SizedBox(height: AppPadding.normal),
                                      Text(
                                        state.isLoading ? 'Загрузка...' : 'Нет данных о рейсах',
                                        style: AppTextStyles.body.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      _buildLastUpdatedInfo(state),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectSummary(AkimatHomeState state) {
    final hasError = state.error != null;
    final statusText = state.isLoading
        ? 'Загрузка данных'
        : (hasError ? 'Ошибка загрузки данных' : 'Данные актуальны');

    final statusColor = state.isLoading
        ? Colors.orange
        : (hasError ? Colors.red : Colors.green);

    return Container(
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
            color: Colors.black.withValues(alpha: 0.04),
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
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSize.smallRadius),
                ),
                child: Icon(
                  hasError
                      ? Icons.error_outline
                      : (state.isLoading ? Icons.sync : Icons.verified_outlined),
                  color: statusColor,
                  size: AppSize.iconSize,
                ),
              ),
              const SizedBox(width: AppPadding.normal),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Сводка по системе',
                      style: AppTextStyles.title2,
                    ),
                    const SizedBox(height: AppPadding.xs),
                    Text(
                      statusText,
                      style: AppTextStyles.caption.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppPadding.normal),
          Row(
            children: [
              Expanded(
                child: _buildSummaryTile(
                  title: 'Участки',
                  value: state.polygons.length.toString(),
                  icon: Icons.place_outlined,
                ),
              ),
              const SizedBox(width: AppPadding.small),
              Expanded(
                child: _buildSummaryTile(
                  title: 'Последние рейсы',
                  value: state.lastTrips.length.toString(),
                  icon: Icons.directions_car_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppPadding.small),
          Row(
            children: [
              Expanded(
                child: _buildSummaryTile(
                  title: 'KPI карточки',
                  value: state.kpiCards.length.toString(),
                  icon: Icons.dashboard_outlined,
                ),
              ),
              const SizedBox(width: AppPadding.small),
              Expanded(
                child: _buildSummaryTile(
                  title: kIsWeb ? 'Платформа' : 'Платформа',
                  value: kIsWeb ? 'WEB' : 'MOBILE',
                  icon: kIsWeb ? Icons.web : Icons.phone_android,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTile({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppPadding.normal),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSize.smallRadius),
        border: Border.all(
          color: AppColors.divider,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: AppPadding.small),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Container(
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
            color: Colors.black.withValues(alpha: 0.04),
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
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSize.smallRadius),
                ),
                child: Icon(
                  Icons.flash_on,
                  color: AppColors.primary,
                  size: AppSize.iconSize,
                ),
              ),
              const SizedBox(width: AppPadding.normal),
              Text(
                'Быстрые действия',
                style: AppTextStyles.title2,
              ),
            ],
          ),
          const SizedBox(height: AppPadding.normal),
          Wrap(
            spacing: AppPadding.small,
            runSpacing: AppPadding.small,
            children: [
              OutlinedButton.icon(
                onPressed: () => context.go('/monitoring'),
                icon: const Icon(Icons.map, size: 18),
                label: const Text('Мониторинг'),
              ),
              OutlinedButton.icon(
                onPressed: () => context.go('/tickets'),
                icon: const Icon(Icons.confirmation_number_outlined, size: 18),
                label: const Text('Тикеты'),
              ),
              OutlinedButton.icon(
                onPressed: () => context.go('/violations'),
                icon: const Icon(Icons.gavel_outlined, size: 18),
                label: const Text('Нарушения'),
              ),
              OutlinedButton.icon(
                onPressed: () => context.go('/analytics'),
                icon: const Icon(Icons.analytics_outlined, size: 18),
                label: const Text('Аналитика'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLastUpdatedInfo(AkimatHomeState state) {
    final lastUpdated = state.lastUpdated;
    if (lastUpdated == null) {
      return const SizedBox.shrink();
    }

    final value =
        '${lastUpdated.day.toString().padLeft(2, '0')}.${lastUpdated.month.toString().padLeft(2, '0')}.${lastUpdated.year} '
        '${lastUpdated.hour.toString().padLeft(2, '0')}:${lastUpdated.minute.toString().padLeft(2, '0')}';

    return Row(
      children: [
        Icon(
          Icons.update,
          size: 16,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: AppPadding.small),
        Text(
          'Обновлено: ',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildImportantInfoSection(AkimatHomeState state, WidgetRef ref) {
    final now = DateTime.now();
    final isWorkingHours = now.hour >= 8 && now.hour <= 18;
    
    return Container(
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
            color: Colors.black.withValues(alpha: 0.04),
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
                  color: isWorkingHours ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSize.smallRadius),
                ),
                child: Icon(
                  isWorkingHours ? Icons.work : Icons.access_time,
                  color: isWorkingHours ? Colors.green : Colors.orange,
                  size: AppSize.iconSize,
                ),
              ),
              const SizedBox(width: AppPadding.normal),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Информация!',
                      style: AppTextStyles.title2,
                    ),
                    const SizedBox(height: AppPadding.xs),
                    Text(
                      isWorkingHours ? 'Рабочее время' : 'Внерабочее время',
                      style: AppTextStyles.caption.copyWith(
                        color: isWorkingHours ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppPadding.normal),
          _buildInfoItem(
            icon: Icons.calendar_today,
            title: 'Текущая дата',
            value: '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}',
          ),
          const SizedBox(height: AppPadding.small),
          _buildInfoItem(
            icon: Icons.access_time,
            title: 'Текущее время',
            value: '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
          ),
          const SizedBox(height: AppPadding.small),
          _buildInfoItem(
            icon: Icons.info_outline,
            title: 'Статус системы',
            value: state.error != null ? 'Ошибка загрузки' : 'Работает нормально',
            valueColor: state.error != null ? Colors.red : Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: AppPadding.small),
        Text(
          '$title: ',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.caption.copyWith(
            color: valueColor ?? AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget(String error, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppPadding.normal),
      padding: const EdgeInsets.all(AppPadding.normal),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSize.cardRadius),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.red, size: 20),
          const SizedBox(width: AppPadding.small),
          Expanded(
            child: Text(
              'Ошибка загрузки данных: $error',
              style: AppTextStyles.caption.copyWith(color: Colors.red),
            ),
          ),
          TextButton(
            onPressed: () => ref.read(akimatHomeControllerProvider.notifier).refreshData(),
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }
}
