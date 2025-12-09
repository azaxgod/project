import 'package:akimat_project/core/locale/locale_provider.dart';
import 'package:akimat_project/core/navbar/drawer_mobile.dart';
import 'package:akimat_project/core/navbar/header_navbar.dart';
import 'package:akimat_project/core/navbar/navbar_widgets_provider.dart';
import 'package:akimat_project/core/platform/platform_utils.dart';
import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/core/ui/app_textstyle.dart';
import 'package:akimat_project/core/ui/widgets/animated_card.dart';
import 'package:akimat_project/core/ui/widgets/animated_button.dart';
import 'package:akimat_project/core/ui/widgets/animated_list_item.dart';
import 'package:akimat_project/core/ui/widgets/professional_badge.dart';
import 'package:akimat_project/core/ui/widgets/professional_chip.dart';
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
      backgroundColor: AppColors.background,
      drawer: !kIsWeb ? const DrawerMobile() : null,
      appBar: kIsWeb
          ? null
          : AppBar(
              backgroundColor: AppColors.surface,
              elevation: 0,
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.background,
              AppColors.background.withOpacity(0.95),
              AppColors.secondaryBackground.withOpacity(0.3),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Column(
        children: [
          if (kIsWeb)
            HeaderNavbar(
              webWidgets: webNavbarWidgets,
            ),
          Expanded(
            child: state.data.when(
              loading: () => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: AppPadding.large),
                    Text(
                      'Загрузка полигонов...',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
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
    // LANDFILL_ADMIN может редактировать полигоны и камеры
    final canEdit = widget.state.role == UserRole.akimatAdmin ||
                    widget.state.role == UserRole.landfillAdmin;

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
            child: AnimatedCard(
              delay: 0,
              padding: EdgeInsets.zero,
              child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(AppPadding.large),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.05),
                        AppColors.cardBackground,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
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
                            Row(
                              children: [
                                Icon(
                                  Icons.map_outlined,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                                const SizedBox(width: AppPadding.small),
                                Text(
                                  s.polygons,
                                  style: AppTextStyles.title2.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
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
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${widget.data.polygons.length} полигонов',
                                style: AppTextStyles.footnote.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (canEdit)
                        AnimatedButton(
                          label: 'Добавить',
                          icon: Icons.add_circle,
                          onPressed: () {
                            setState(() {
                              _isDrawingMode = true;
                            });
                          },
                          isOutlined: false,
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
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 800),
                                curve: Curves.easeOutBack,
                                padding: const EdgeInsets.all(AppPadding.large),
                                decoration: BoxDecoration(
                                  color: AppColors.secondaryBackground,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.map_outlined,
                                  size: 64,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                              const SizedBox(height: AppPadding.large),
                              Text(
                                'Нет полигонов',
                                style: AppTextStyles.headline.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: AppPadding.xs),
                              Text(
                                'Добавьте первый полигон',
                                style: AppTextStyles.footnote.copyWith(
                                  color: AppColors.textTertiary,
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

                            return AnimatedListItem(
                              index: index,
                              isSelected: isSelected,
                              onTap: () {
                                widget.controller.selectPolygon(polygon);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(AppPadding.normal),
                                decoration: BoxDecoration(
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
                                            style: AppTextStyles.headline.copyWith(
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.w600,
                                              color: isSelected
                                                  ? AppColors.primary
                                                  : AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                        ProfessionalBadge(
                                          text: polygon.isActive ? 'Активный' : 'Неактивный',
                                          type: polygon.isActive
                                              ? BadgeType.success
                                              : BadgeType.secondary,
                                          size: BadgeSize.small,
                                          icon: polygon.isActive ? Icons.check_circle : null,
                                        ),
                                      ],
                                    ),
                                    if (polygon.address != null) ...[
                                      const SizedBox(height: AppPadding.xs),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.location_on_outlined,
                                            size: 14,
                                            color: AppColors.textSecondary,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              polygon.address!,
                                              style: AppTextStyles.footnote,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    const SizedBox(height: AppPadding.small),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.videocam_outlined,
                                          size: 16,
                                          color: AppColors.textSecondary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Камер: ${cameras.length}',
                                          style: AppTextStyles.footnote.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
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
                  child: AnimatedCard(
                    delay: 100,
                    padding: EdgeInsets.zero,
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
                            child: AnimatedCard(
                              delay: 0,
                              padding: const EdgeInsets.all(AppPadding.large),
                              backgroundColor: AppColors.cardBackground,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          gradient: AppColors.primaryGradient,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.edit_location_alt,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: AppPadding.small),
                                      Text(
                                        'Режим рисования',
                                        style: AppTextStyles.headline.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppPadding.normal),
                                  Text(
                                    'Кликните на карте минимум 3 точки, затем закройте полигон, кликнув на первую точку',
                                    style: AppTextStyles.footnote,
                                  ),
                                  const SizedBox(height: AppPadding.normal),
                                  AnimatedButton(
                                    label: 'Отмена',
                                    icon: Icons.close,
                                    onPressed: () {
                                      setState(() {
                                        _isDrawingMode = false;
                                        _draftGeometry = null;
                                      });
                                    },
                                    isOutlined: false,
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
                    child: AnimatedCard(
                      delay: 200,
                      padding: EdgeInsets.zero,
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
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.08),
                AppColors.cardBackground,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border(
              bottom: BorderSide(color: AppColors.divider, width: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppPadding.small),
                  Expanded(
                    child: Text(
                      polygon.name,
                      style: AppTextStyles.title2.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (canEdit)
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryBackground,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.close, size: 18),
                      ),
                      onPressed: () => controller.selectPolygon(null),
                      tooltip: 'Закрыть',
                    ),
                ],
              ),
              const SizedBox(height: AppPadding.small),
              ProfessionalBadge(
                text: polygon.isActive ? 'Активный' : 'Неактивный',
                type: polygon.isActive
                    ? BadgeType.success
                    : BadgeType.secondary,
                size: BadgeSize.medium,
                icon: polygon.isActive ? Icons.check_circle : Icons.cancel_outlined,
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
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Адрес',
                        style: AppTextStyles.footnote.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppPadding.xs),
                  Container(
                    padding: const EdgeInsets.all(AppPadding.small),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      polygon.address!,
                      style: AppTextStyles.body,
                    ),
                  ),
                  const SizedBox(height: AppPadding.normal),
                ],
                if (polygon.description != null) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Описание',
                        style: AppTextStyles.footnote.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppPadding.xs),
                  Container(
                    padding: const EdgeInsets.all(AppPadding.small),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      polygon.description!,
                      style: AppTextStyles.body,
                    ),
                  ),
                  const SizedBox(height: AppPadding.normal),
                ],
                Divider(
                  color: AppColors.divider,
                  thickness: 0.5,
                ),
                const SizedBox(height: AppPadding.normal),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: AppColors.secondaryGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.videocam,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: AppPadding.small),
                    Text(
                      'Камеры',
                      style: AppTextStyles.headline.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: AppPadding.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${cameras.length}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (canEdit)
                      AnimatedButton(
                        label: 'Добавить',
                        icon: Icons.add,
                        onPressed: () => PolygonsDialogs.showCreateCameraDialog(
                          context: context,
                          controller: controller,
                          polygonId: polygon.id,
                        ),
                        isOutlined: false,
                      ),
                  ],
                ),
                const SizedBox(height: AppPadding.small),
                if (cameras.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(AppPadding.large),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.videocam_off_outlined,
                            size: 48,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(height: AppPadding.normal),
                          Text(
                            'Нет камер',
                            style: AppTextStyles.footnote.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...cameras.asMap().entries.map((entry) {
                    final index = entry.key;
                    final camera = entry.value;
                    return AnimatedListItem(
                      index: index,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: AppPadding.small),
                        padding: const EdgeInsets.all(AppPadding.normal),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryBackground,
                          borderRadius: BorderRadius.circular(AppSize.smallRadius),
                          border: Border.all(
                            color: AppColors.divider.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                camera.type == CameraType.lpr
                                    ? Icons.camera_alt
                                    : Icons.camera,
                                size: 20,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: AppPadding.small),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    camera.name,
                                    style: AppTextStyles.body.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.secondary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      camera.type == CameraType.lpr
                                          ? 'LPR'
                                          : 'VOLUME',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.secondary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ProfessionalBadge(
                              text: camera.isActive ? 'Активна' : 'Неактивна',
                              type: camera.isActive
                                  ? BadgeType.success
                                  : BadgeType.secondary,
                              size: BadgeSize.small,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

