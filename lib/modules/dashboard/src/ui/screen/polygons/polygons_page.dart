import 'package:akimat_project/core/locale/locale_provider.dart';
import 'package:akimat_project/core/navbar/drawer_mobile.dart';
import 'package:akimat_project/core/navbar/header_navbar.dart';
import 'package:akimat_project/core/navbar/navbar_widgets_provider.dart';
import 'package:akimat_project/core/platform/platform_utils.dart';
import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/core/ui/app_textstyle.dart';
import 'package:akimat_project/l10n/l10n.dart';
import 'package:akimat_project/modules/dashboard/src/controller/polygons_controller.dart';
import 'package:akimat_project/modules/dashboard/src/controller/polygons_state.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/user_role.dart';
import 'package:akimat_project/modules/dashboard/src/model/polygons/camera.dart';
import 'package:akimat_project/modules/dashboard/src/model/polygons/polygon.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/areas/widgets/areas_map_widget.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_error_state.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/polygons/widgets/polygons_dialogs.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PolygonsPage extends ConsumerWidget {
  const PolygonsPage({
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
    final state = ref.watch(polygonsControllerProvider);
    final controller = ref.watch(polygonsControllerProvider.notifier);

    return Scaffold(
      key: scaffoldKey,
      drawer: !kIsWeb ? const DrawerMobile() : null,
      appBar: kIsWeb
          ? null
          : AppBar(
              title: Text(s.polygons),
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
            HeaderNavbar(
              webWidgets: webNavbarWidgets,
            ),
          Expanded(
            child: state.data.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => OrganizationsErrorState(
                message: s.failed_to_load_data(error),
                onRetry: controller.refresh,
              ),
              data: (data) => _PolygonsContent(
                state: state,
                data: data,
                controller: controller,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PolygonsContent extends ConsumerStatefulWidget {
  const _PolygonsContent({
    required this.state,
    required this.data,
    required this.controller,
  });

  final PolygonsState state;
  final PolygonsData data;
  final PolygonsController controller;

  @override
  ConsumerState<_PolygonsContent> createState() => _PolygonsContentState();
}

class _PolygonsContentState extends ConsumerState<_PolygonsContent> {
  bool _isDrawingMode = false;
  List<List<double>>? _draftGeometry;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final config = PlatformConfig.instance;
    final canEdit = widget.state.role == UserRole.akimatAdmin;

    return Row(
      children: [
        // List (left side)
        Expanded(
          flex: 1,
          child: Container(
            margin: EdgeInsets.only(
              left: config.padding,
              top: config.padding,
              bottom: config.padding,
            ),
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
                      bottom: BorderSide(color: AppColors.divider, width: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.polygons,
                              style: AppTextStyles.title2,
                            ),
                            const SizedBox(height: AppPadding.xs),
                            Text(
                              '${widget.data.polygons.length} полигонов',
                              style: AppTextStyles.footnote,
                            ),
                          ],
                        ),
                      ),
                      if (canEdit)
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            setState(() {
                              _isDrawingMode = true;
                            });
                          },
                          tooltip: 'Создать полигон',
                        ),
                    ],
                  ),
                ),
                // Polygons list
                Expanded(
                  child: widget.data.polygons.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.map_outlined,
                                size: 64,
                                color: AppColors.textTertiary,
                              ),
                              const SizedBox(height: AppPadding.normal),
                              Text(
                                'Нет полигонов',
                                style: AppTextStyles.headline.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: widget.data.polygons.length,
                          itemBuilder: (context, index) {
                            final polygon = widget.data.polygons[index];
                            final isSelected = widget.state.selectedPolygon?.id == polygon.id;
                            final cameras = widget.data.cameras
                                .where((c) => c.polygonId == polygon.id)
                                .toList();

                            return InkWell(
                              onTap: () {
                                widget.controller.selectPolygon(polygon);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(AppPadding.normal),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary.withOpacity(0.1)
                                      : null,
                                  border: Border(
                                    bottom: BorderSide(
                                      color: AppColors.divider,
                                      width: 0.5,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            polygon.name,
                                            style: AppTextStyles.headline,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppPadding.small,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: polygon.isActive
                                                ? AppColors.success.withOpacity(0.2)
                                                : AppColors.textTertiary.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            polygon.isActive ? 'Активный' : 'Неактивный',
                                            style: AppTextStyles.caption.copyWith(
                                              color: polygon.isActive
                                                  ? AppColors.success
                                                  : AppColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (polygon.address != null) ...[
                                      const SizedBox(height: AppPadding.xs),
                                      Text(
                                        polygon.address!,
                                        style: AppTextStyles.footnote,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                    const SizedBox(height: AppPadding.xs),
                                    Text(
                                      'Камер: ${cameras.length}',
                                      style: AppTextStyles.footnote,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
        // Map and Info (right side)
        Expanded(
          flex: 2,
          child: Row(
            children: [
              // Map
              Expanded(
                flex: 2,
                child: Container(
                  margin: EdgeInsets.only(
                    top: config.padding,
                    bottom: config.padding,
                    right: config.padding / 2,
                  ),
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppSize.cardRadius),
                    child: Stack(
                      children: [
                        AreasMapWidget(
                          polygonGeometry: widget.state.selectedPolygon?.geometry,
                          existingPolygons: widget.data.polygons
                              .map((polygon) => polygon.geometry)
                              .toList(),
                          isDrawingMode: _isDrawingMode,
                          onPolygonComplete: (geometry) {
                            setState(() {
                              _draftGeometry = geometry;
                              _isDrawingMode = false;
                            });
                            _showCreatePolygonDialog(geometry);
                          },
                        ),
                        if (_isDrawingMode)
                          Positioned(
                            top: AppPadding.normal,
                            left: AppPadding.normal,
                            child: Container(
                              padding: const EdgeInsets.all(AppPadding.normal),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(AppSize.cardRadius),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Режим рисования',
                                    style: AppTextStyles.headline,
                                  ),
                                  const SizedBox(height: AppPadding.xs),
                                  Text(
                                    'Кликните на карте минимум 3 точки, затем закройте полигон, кликнув на первую точку',
                                    style: AppTextStyles.footnote,
                                  ),
                                  const SizedBox(height: AppPadding.small),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _isDrawingMode = false;
                                        _draftGeometry = null;
                                      });
                                    },
                                    child: const Text('Отмена'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              // Info panel
              if (widget.state.selectedPolygon != null)
                Expanded(
                  flex: 1,
                  child: Container(
                    margin: EdgeInsets.only(
                      top: config.padding,
                      bottom: config.padding,
                      left: config.padding / 2,
                      right: config.padding,
                    ),
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
                    child: _PolygonInfoPanel(
                      polygon: widget.state.selectedPolygon!,
                      cameras: widget.data.cameras
                          .where((c) => c.polygonId == widget.state.selectedPolygon!.id)
                          .toList(),
                      canEdit: canEdit,
                      controller: widget.controller,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _showCreatePolygonDialog(List<List<double>> geometry) {
    PolygonsDialogs.showCreatePolygonDialog(
      context: context,
      controller: widget.controller,
      geometry: geometry,
    );
  }
}

class _PolygonInfoPanel extends StatelessWidget {
  const _PolygonInfoPanel({
    required this.polygon,
    required this.cameras,
    required this.canEdit,
    required this.controller,
  });

  final Polygon polygon;
  final List<Camera> cameras;
  final bool canEdit;
  final PolygonsController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(AppPadding.large),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.divider, width: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      polygon.name,
                      style: AppTextStyles.title2,
                    ),
                  ),
                  if (canEdit)
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => controller.selectPolygon(null),
                      tooltip: 'Закрыть',
                    ),
                ],
              ),
              const SizedBox(height: AppPadding.xs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppPadding.small,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: polygon.isActive
                      ? AppColors.success.withValues(alpha: 0.2)
                      : AppColors.textTertiary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  polygon.isActive ? 'Активный' : 'Неактивный',
                  style: AppTextStyles.caption.copyWith(
                    color: polygon.isActive
                        ? AppColors.success
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Info
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppPadding.large),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (polygon.address != null) ...[
                  Text(
                    'Адрес',
                    style: AppTextStyles.footnote.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppPadding.xs),
                  Text(
                    polygon.address!,
                    style: AppTextStyles.body,
                  ),
                  const SizedBox(height: AppPadding.normal),
                ],
                if (polygon.description != null) ...[
                  Text(
                    'Описание',
                    style: AppTextStyles.footnote.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppPadding.xs),
                  Text(
                    polygon.description!,
                    style: AppTextStyles.body,
                  ),
                  const SizedBox(height: AppPadding.normal),
                ],
                const Divider(),
                const SizedBox(height: AppPadding.normal),
                Row(
                  children: [
                    Text(
                      'Камеры (${cameras.length})',
                      style: AppTextStyles.headline,
                    ),
                    const Spacer(),
                    if (canEdit)
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => PolygonsDialogs.showCreateCameraDialog(
                          context: context,
                          controller: controller,
                          polygonId: polygon.id,
                        ),
                        tooltip: 'Добавить камеру',
                      ),
                  ],
                ),
                const SizedBox(height: AppPadding.small),
                if (cameras.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(AppPadding.normal),
                    child: Text(
                      'Нет камер',
                      style: AppTextStyles.footnote.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                else
                  ...cameras.map((camera) => Container(
                        margin: const EdgeInsets.only(bottom: AppPadding.small),
                        padding: const EdgeInsets.all(AppPadding.normal),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryBackground,
                          borderRadius: BorderRadius.circular(AppSize.smallRadius),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              camera.type == CameraType.lpr
                                  ? Icons.camera_alt
                                  : Icons.camera,
                              size: 20,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: AppPadding.small),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    camera.name,
                                    style: AppTextStyles.body,
                                  ),
                                  Text(
                                    camera.type == CameraType.lpr
                                        ? 'LPR'
                                        : 'VOLUME',
                                    style: AppTextStyles.caption,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppPadding.small,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: camera.isActive
                                    ? AppColors.success.withValues(alpha: 0.2)
                                    : AppColors.textTertiary.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                camera.isActive ? 'Активна' : 'Неактивна',
                                style: AppTextStyles.caption.copyWith(
                                  color: camera.isActive
                                      ? AppColors.success
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

