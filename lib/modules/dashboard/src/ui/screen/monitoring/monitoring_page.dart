import 'package:akimat_project/core/locale/locale_provider.dart';
import 'package:akimat_project/core/navbar/drawer_mobile.dart';
import 'package:akimat_project/core/navbar/header_navbar.dart';
import 'package:akimat_project/core/navbar/navbar_widgets_provider.dart';
import 'package:akimat_project/core/platform/platform_utils.dart';
import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/core/ui/app_textstyle.dart';
import 'package:akimat_project/core/widgets/app_footer.dart';
import 'package:akimat_project/l10n/l10n.dart';
import 'package:akimat_project/modules/dashboard/src/controller/monitoring_controller.dart';
import 'package:akimat_project/modules/dashboard/src/controller/monitoring_state.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/user_role.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/monitoring/widgets/monitoring_create_panel.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/monitoring/widgets/monitoring_map_widget.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/monitoring/widgets/monitoring_sidebar.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_error_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MonitoringPage extends ConsumerWidget {
  const MonitoringPage({
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
    debugPrint('=== MonitoringPage build: Starting build method ===');
    
    try {
      debugPrint('MonitoringPage build: Step 1 - Watching localeProvider');
      ref.watch(localeProvider);
      debugPrint('MonitoringPage build: Step 1 - localeProvider watched OK');
      
      debugPrint('MonitoringPage build: Step 2 - Getting S and config');
      final s = S.of(context)!;
      final config = PlatformConfig.instance;
      debugPrint('MonitoringPage build: Step 2 - Got S and config OK');
      
      debugPrint('MonitoringPage build: Step 3 - Watching monitoringControllerProvider');
      MonitoringState state;
      MonitoringController controller;
      try {
        state = ref.watch(monitoringControllerProvider);
        debugPrint('MonitoringPage build: Step 3a - Got state, state.data=${state.data}');
        
        debugPrint('MonitoringPage build: Step 3b - Getting controller notifier');
        controller = ref.watch(monitoringControllerProvider.notifier);
        debugPrint('MonitoringPage build: Step 3b - Got controller OK');
      } catch (providerError, providerStack) {
        debugPrint('=== MonitoringPage build: Provider error: $providerError ===');
        debugPrint('MonitoringPage build: Provider stack: $providerStack');
        return _buildErrorScaffold(context, providerError, s);
      }
      
      debugPrint('MonitoringPage build: Step 4 - Building Scaffold');
      return _buildScaffold(context, state, controller, s, config);
    } catch (e, stackTrace) {
      debugPrint('=== MonitoringPage build: FATAL ERROR: $e ===');
      debugPrint('MonitoringPage build: Stack: $stackTrace');
      try {
        return _buildErrorScaffold(context, e, S.of(context)!);
      } catch (_) {
        // Если даже S.of(context) падает, возвращаем простую страницу
        return Scaffold(
          body: Center(
            child: Text('Критическая ошибка: $e'),
          ),
        );
      }
    }
  }

  Widget _buildScaffold(
    BuildContext context,
    MonitoringState? state,
    MonitoringController? controller,
    S s,
    PlatformConfig config,
  ) {
    return Scaffold(
        key: scaffoldKey,
        drawer: !kIsWeb ? const DrawerMobile() : null,
        appBar: kIsWeb
            ? null
            : AppBar(
                title: const Text('Мониторинг'),
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
        body: Column(
          children: [
            if (kIsWeb)
              Builder(
                builder: (context) => HeaderNavbar(
                  webWidgets: webNavbarWidgets ?? NavbarWidgetsProvider.getDefaultWebWidgets(context),
                ),
              ),
            Expanded(
              child: state == null || controller == null
                  ? const Center(child: CircularProgressIndicator())
                  : state.data.when(
                      loading: () {
                        debugPrint('MonitoringPage: Showing loading state');
                        return const Center(child: CircularProgressIndicator());
                      },
                      error: (error, stack) {
                        debugPrint('MonitoringPage error: $error');
                        debugPrint('MonitoringPage stack: $stack');
                        
                        // Показываем более понятное сообщение для ошибок бэкенда
                        String errorMessage = s.failed_to_load_data(error);
                        final errorStr = error.toString().toLowerCase();
                        if (errorStr.contains('500') || errorStr.contains('internal error')) {
                          errorMessage = 'Ошибка сервера при загрузке данных. Пожалуйста, попробуйте позже или обратитесь к администратору.';
                        } else if (errorStr.contains('401') || errorStr.contains('403')) {
                          errorMessage = 'Ошибка авторизации. Пожалуйста, войдите заново.';
                        } else if (errorStr.contains('network') || errorStr.contains('connection')) {
                          errorMessage = 'Ошибка подключения к серверу. Проверьте интернет-соединение.';
                        }
                        
                        return OrganizationsErrorState(
                          message: errorMessage,
                          onRetry: controller.refresh,
                        );
                      },
                      data: (data) {
                        debugPrint('MonitoringPage: Showing data, areas=${data.areas.length}, polygons=${data.polygons.length}');
                        return _MonitoringContent(
                          config: config,
                          state: state,
                          data: data,
                          controller: controller,
                        );
                      },
                    ),
            ),
            // Футер с версией (только для web)
            if (kIsWeb) const AppFooter(),
          ],
        ),
      );
  }

  Widget _buildErrorScaffold(BuildContext context, Object error, S s) {
    return Scaffold(
      key: scaffoldKey,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Ошибка загрузки страницы: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Попробуем перезагрузить страницу
                GoRouter.of(context).go('/monitoring');
              },
              child: const Text('Попробовать снова'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonitoringContent extends ConsumerWidget {
  const _MonitoringContent({
    required this.config,
    required this.state,
    required this.data,
    required this.controller,
  });

  final PlatformConfig config;
  final MonitoringState state;
  final MonitoringData data;
  final MonitoringController controller;

         @override
         Widget build(BuildContext context, WidgetRef ref) {
           // ВАЖНО: Отслеживаем изменения состояния через ref.watch
           // чтобы виджет перестраивался при изменении createMode
           final currentState = ref.watch(monitoringControllerProvider);
           
           // Логируем для отладки
           WidgetsBinding.instance.addPostFrameCallback((_) {
             debugPrint('_MonitoringContent.build: createMode=${currentState.createMode}');
           });
           
           return Stack(
             clipBehavior: Clip.none,
             children: [
               Row(
                   children: [
                     // Карта (левая часть)
                     Expanded(
                       flex: 2,
                      child: MonitoringMapWidget(
                        areas: currentState.showAreas ? data.areas : [],
                        polygons: currentState.showPolygons ? data.polygons : [],
                        cameras: currentState.showCameras ? data.cameras : [],
                        vehicles: currentState.showVehicles ? data.vehicles : [],
                        selectedAreaId: currentState.selectedAreaId,
                        selectedPolygonId: currentState.selectedPolygonId,
                        selectedVehicleId: currentState.selectedVehicleId,
                        selectedVehicleTrack: currentState.selectedVehicleTrack,
                        drawingGeometry: currentState.drawingGeometry,
                        createMode: currentState.createMode,
                        isEditingGeometry: currentState.isEditingGeometry,
                        showAreas: currentState.showAreas,
                        showPolygons: currentState.showPolygons,
                        showCameras: currentState.showCameras,
                        showVehicles: currentState.showVehicles,
                        onAreaTap: (areaId) => controller.selectArea(areaId),
                        onPolygonTap: (polygonId) => controller.selectPolygon(polygonId),
                        onVehicleTap: (vehicleId) => controller.selectVehicle(vehicleId),
                        onMapTap: currentState.createMode != null && !currentState.isEditingGeometry
                            ? (lat, lon) {
                                controller.addDrawingPoint(lon, lat);
                              }
                            : null,
                        onPointTap: currentState.isEditingGeometry
                            ? (index) {
                                controller.removeDrawingPoint(index);
                              }
                            : null,
                        onToggleAreas: () => controller.toggleAreas(!currentState.showAreas),
                        onTogglePolygons: () => controller.togglePolygons(!currentState.showPolygons),
                        onToggleCameras: () => controller.toggleCameras(!currentState.showCameras),
                        onToggleVehicles: () => controller.toggleVehicles(!currentState.showVehicles),
                        onRefresh: () => controller.refresh(),
                      ),
                     ),
                     // Панель справа
                     SizedBox(
                       width: 400,
                       child: MonitoringSidebar(
                         state: currentState,
                         data: data,
                         controller: controller,
                       ),
                     ),
                   ],
                 ),
               // Боковая панель действий справа (появляется после 3+ точек)
               if (currentState.createMode != null && 
                   currentState.drawingGeometry.isNotEmpty && 
                   currentState.drawingGeometry.length >= 3 &&
                   (currentState.createMode == 'area' || currentState.createMode == 'polygon'))
                 Positioned(
                   right: 420, // Справа от сайдбара (400px) + отступ
                   top: 100,
                   child: Material(
                     elevation: 16,
                     shadowColor: Colors.black.withValues(alpha: 0.3),
                     borderRadius: BorderRadius.circular(AppSize.cardRadius),
                     child: Container(
                       width: 280,
                       padding: const EdgeInsets.all(AppPadding.normal),
                       decoration: BoxDecoration(
                         color: AppColors.cardBackground,
                         borderRadius: BorderRadius.circular(AppSize.cardRadius),
                         border: Border.all(
                           color: AppColors.primary.withValues(alpha: 0.2),
                           width: 2,
                         ),
                       ),
                       child: Column(
                         mainAxisSize: MainAxisSize.min,
                         crossAxisAlignment: CrossAxisAlignment.stretch,
                         children: [
                           Row(
                             children: [
                               Icon(
                                 Icons.edit_location_alt,
                                 color: AppColors.primary,
                                 size: 24,
                               ),
                               const SizedBox(width: AppPadding.small),
                               Expanded(
                                 child: Text(
                                   'Геометрия готова',
                                   style: AppTextStyles.title2.copyWith(
                                     fontWeight: FontWeight.bold,
                                     color: AppColors.primary,
                                   ),
                                 ),
                               ),
                             ],
                           ),
                           const SizedBox(height: AppPadding.small),
                           Text(
                             'Точек: ${currentState.drawingGeometry.length}',
                             style: AppTextStyles.caption,
                           ),
                           const SizedBox(height: AppPadding.normal),
                           // Кнопка Сохранить (сохраняет геометрию, но не отправляет)
                           if (currentState.isEditingGeometry)
                             FilledButton.icon(
                               onPressed: () {
                                 controller.saveGeometry();
                               },
                               icon: const Icon(Icons.save, size: 20),
                               label: const Text('Сохранить'),
                               style: FilledButton.styleFrom(
                                 padding: const EdgeInsets.symmetric(vertical: AppPadding.normal),
                                 backgroundColor: AppColors.success,
                               ),
                             ),
                           // Кнопка Завершить (отправляет на сервер)
                           if (!currentState.isEditingGeometry)
                             FilledButton.icon(
                               onPressed: () {
                                 controller.finishDrawing();
                                 // Прокручиваем к форме внизу для заполнения и отправки
                                 // Форма сама отправит данные на сервер
                               },
                               icon: const Icon(Icons.check, size: 20),
                               label: const Text('Завершить'),
                               style: FilledButton.styleFrom(
                                 padding: const EdgeInsets.symmetric(vertical: AppPadding.normal),
                               ),
                             ),
                           const SizedBox(height: AppPadding.small),
                           // Кнопка Редактировать (включает режим редактирования)
                           if (!currentState.isEditingGeometry)
                             OutlinedButton.icon(
                               onPressed: () {
                                 controller.enableEditingGeometry();
                               },
                               icon: const Icon(Icons.edit, size: 20),
                               label: const Text('Редактировать'),
                               style: OutlinedButton.styleFrom(
                                 padding: const EdgeInsets.symmetric(vertical: AppPadding.normal),
                               ),
                             ),
                           // Кнопка Отменить редактирование
                           if (currentState.isEditingGeometry)
                             OutlinedButton.icon(
                               onPressed: () {
                                 controller.disableEditingGeometry();
                               },
                               icon: const Icon(Icons.cancel, size: 20),
                               label: const Text('Отменить редактирование'),
                               style: OutlinedButton.styleFrom(
                                 padding: const EdgeInsets.symmetric(vertical: AppPadding.normal),
                               ),
                             ),
                           const SizedBox(height: AppPadding.small),
                           // Кнопка Отменить (закрыть панель)
                           OutlinedButton.icon(
                             onPressed: () {
                               controller.setCreateMode(null);
                             },
                             icon: const Icon(Icons.close, size: 20),
                             label: const Text('Отменить'),
                             style: OutlinedButton.styleFrom(
                               padding: const EdgeInsets.symmetric(vertical: AppPadding.normal),
                               foregroundColor: AppColors.error,
                             ),
                           ),
                           // Подсказка в режиме редактирования
                           if (currentState.isEditingGeometry) ...[
                             const SizedBox(height: AppPadding.normal),
                             Container(
                               padding: const EdgeInsets.all(AppPadding.small),
                               decoration: BoxDecoration(
                                 color: AppColors.primary.withValues(alpha: 0.1),
                                 borderRadius: BorderRadius.circular(AppSize.smallRadius),
                               ),
                               child: Row(
                                 children: [
                                   Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                                   const SizedBox(width: AppPadding.small),
                                   Expanded(
                                     child: Text(
                                       'Кликните на точку на карте для удаления',
                                       style: AppTextStyles.caption.copyWith(
                                         color: AppColors.primary,
                                       ),
                                     ),
                                   ),
                                 ],
                               ),
                             ),
                           ],
                         ],
                       ),
                     ),
                   ),
                 ),
              // Компактная панель создания слева (плавающая)
              if (currentState.createMode != null)
                Positioned(
                  left: 16,
                  top: 16,
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(-20 * (1 - value), 0),
                        child: Opacity(
                          opacity: value,
                          child: child,
                        ),
                      );
                    },
                    child: Material(
                      elevation: 8,
                      shadowColor: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 320,
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            width: 1.5,
                          ),
                        ),
                        child: MonitoringCreatePanel(
                          key: ValueKey('create_panel_${currentState.createMode}'),
                          controller: controller,
                          mode: currentState.createMode,
                          onClose: () {
                            debugPrint('MonitoringPage: onClose called');
                            controller.setCreateMode(null);
                          },
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        }
}

