import 'package:akimat_project/core/locale/locale_provider.dart';
import 'package:akimat_project/core/navbar/drawer_mobile.dart';
import 'package:akimat_project/core/navbar/header_navbar.dart';
import 'package:akimat_project/core/navbar/navbar_widgets_provider.dart';
import 'package:akimat_project/core/platform/platform_utils.dart';
import 'package:akimat_project/l10n/l10n.dart';
import 'package:akimat_project/modules/dashboard/src/controller/monitoring_controller.dart';
import 'package:akimat_project/modules/dashboard/src/controller/monitoring_state.dart';
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
           return Stack(
             children: [
               Row(
                 children: [
                   // Карта (левая часть)
                   Expanded(
                     flex: 2,
                     child: MonitoringMapWidget(
                       areas: state.showAreas ? data.areas : [],
                       polygons: state.showPolygons ? data.polygons : [],
                       cameras: state.showCameras ? data.cameras : [],
                       vehicles: state.showVehicles ? data.vehicles : [],
                       selectedAreaId: state.selectedAreaId,
                       selectedPolygonId: state.selectedPolygonId,
                       selectedVehicleId: state.selectedVehicleId,
                       selectedVehicleTrack: state.selectedVehicleTrack,
                       drawingGeometry: state.drawingGeometry,
                       onAreaTap: (areaId) => controller.selectArea(areaId),
                       onPolygonTap: (polygonId) => controller.selectPolygon(polygonId),
                       onVehicleTap: (vehicleId) => controller.selectVehicle(vehicleId),
                       onMapTap: state.createMode != null ? (lat, lon) {
                         controller.addDrawingPoint(lon, lat);
                       } : null,
                     ),
                   ),
                   // Панель справа
                   SizedBox(
                     width: 400,
                     child: MonitoringSidebar(
                       state: state,
                       data: data,
                       controller: controller,
                     ),
                   ),
                 ],
               ),
               // Боковая панель создания справа
               if (state.createMode != null)
                 Positioned(
                   right: 0,
                   top: 0,
                   bottom: 0,
                   child: MonitoringCreatePanel(
                     controller: controller,
                     mode: state.createMode,
                     onClose: () => controller.setCreateMode(null),
                   ),
                 ),
             ],
           );
         }
}

