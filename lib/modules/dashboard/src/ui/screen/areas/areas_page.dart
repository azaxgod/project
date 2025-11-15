import 'package:akimat_project/core/locale/locale_provider.dart';
import 'package:akimat_project/core/navbar/drawer_mobile.dart';
import 'package:akimat_project/core/navbar/header_navbar.dart';
import 'package:akimat_project/core/navbar/navbar_widgets_provider.dart';
import 'package:akimat_project/core/platform/platform_utils.dart';
import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/core/ui/app_textstyle.dart';
import 'package:akimat_project/generated/l10n.dart';
import 'package:akimat_project/modules/dashboard/src/controller/areas_controller.dart';
import 'package:akimat_project/modules/dashboard/src/controller/areas_state.dart';
import 'package:akimat_project/modules/dashboard/src/model/areas/cleaning_area.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/organization.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/user_role.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/areas/widgets/areas_dialogs.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/areas/widgets/areas_map_widget.dart';
import 'package:akimat_project/modules/dashboard/src/ui/screen/organizations/widgets/components/organizations_error_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AreasPage extends ConsumerWidget {
  const AreasPage({
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
    final s = S.of(context);
    final state = ref.watch(areasControllerProvider);
    final controller = ref.watch(areasControllerProvider.notifier);
    final config = PlatformConfig.instance;

    return Scaffold(
      key: scaffoldKey,
      drawer: !kIsWeb ? const DrawerMobile() : null,
      appBar: kIsWeb
          ? null
          : AppBar(
              title: Text(s.areas),
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
              data: (data) {
                if (state.role == UserRole.driver) {
                  return _ForbiddenAreasPage(
                    scaffoldKey: scaffoldKey,
                    webNavbarWidgets: webNavbarWidgets,
                    mobileNavbarWidgets: mobileNavbarWidgets,
                  );
                }

                return _AreasContent(
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
}

class _AreasContent extends ConsumerStatefulWidget {
  const _AreasContent({
    required this.config,
    required this.state,
    required this.data,
    required this.controller,
  });

  final PlatformConfig config;
  final AreasState state;
  final AreasData data;
  final AreasController controller;

  @override
  ConsumerState<_AreasContent> createState() => _AreasContentState();
}

class _AreasContentState extends ConsumerState<_AreasContent> {
  bool _isDrawingMode = false;
  List<List<double>>? _draftGeometry;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final canEdit = widget.state.role == UserRole.akimatAdmin || 
                    widget.state.role == UserRole.kguZkhAdmin ||
                    widget.state.role == UserRole.tooAdmin;

    // Filter areas
    var filteredAreas = widget.data.areas;
    if (widget.state.statusFilter != null) {
      filteredAreas = filteredAreas
          .where((area) => area.status == widget.state.statusFilter)
          .toList();
    }
    if (widget.state.contractorFilter != null) {
      filteredAreas = filteredAreas
          .where((area) => area.defaultContractorId == widget.state.contractorFilter)
          .toList();
    }

    return Row(
      children: [
        // Map and Info (left side)
        Expanded(
          flex: 2,
          child: Row(
            children: [
              // Map
              Expanded(
                flex: 2,
                child: Container(
                  margin: EdgeInsets.only(
                    top: widget.config.padding,
                    bottom: widget.config.padding,
                    left: widget.config.padding,
                    right: widget.config.padding / 2,
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
                          polygonGeometry: widget.state.selectedArea?.geometry,
                          existingPolygons: widget.data.areas
                              .map((area) => area.geometry)
                              .toList(),
                          isDrawingMode: _isDrawingMode,
                          onPolygonComplete: (geometry) {
                            setState(() {
                              _draftGeometry = geometry;
                              _isDrawingMode = false;
                            });
                            _showCreateAreaDialog(geometry);
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
              if (widget.state.selectedArea != null)
                Expanded(
                  flex: 1,
                  child: Container(
                    margin: EdgeInsets.only(
                      top: widget.config.padding,
                      bottom: widget.config.padding,
                      left: widget.config.padding / 2,
                      right: widget.config.padding,
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
                    child: _AreaInfoPanel(
                      area: widget.state.selectedArea!,
                      contractors: widget.data.contractors,
                      canEdit: canEdit,
                      controller: widget.controller,
                    ),
                  ),
                ),
            ],
          ),
        ),
        // List (right side)
        Expanded(
          flex: 1,
          child: Container(
            margin: EdgeInsets.only(
              right: widget.config.padding,
              top: widget.config.padding,
              bottom: widget.config.padding,
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
                              s.areas,
                              style: AppTextStyles.title2,
                            ),
                            const SizedBox(height: AppPadding.xs),
                            Text(
                              '${filteredAreas.length} участков',
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
                          tooltip: 'Создать участок',
                        ),
                    ],
                  ),
                ),
                // Filters
                Container(
                  padding: const EdgeInsets.all(AppPadding.normal),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.divider, width: 0.5),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Status filter
                      DropdownButtonFormField<CleaningAreaStatus?>(
                        value: widget.state.statusFilter,
                        decoration: InputDecoration(
                          labelText: 'Статус',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSize.smallRadius),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppPadding.normal,
                            vertical: AppPadding.small,
                          ),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Все'),
                          ),
                          const DropdownMenuItem(
                            value: CleaningAreaStatus.active,
                            child: Text('Активные'),
                          ),
                          const DropdownMenuItem(
                            value: CleaningAreaStatus.inactive,
                            child: Text('Неактивные'),
                          ),
                        ],
                        onChanged: widget.controller.setStatusFilter,
                      ),
                      const SizedBox(height: AppPadding.small),
                      // Contractor filter
                      DropdownButtonFormField<String?>(
                        value: widget.state.contractorFilter,
                        decoration: InputDecoration(
                          labelText: 'Ответственный',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSize.smallRadius),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppPadding.normal,
                            vertical: AppPadding.small,
                          ),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Все'),
                          ),
                          ...widget.data.contractors.map(
                            (contractor) => DropdownMenuItem(
                              value: contractor.id,
                              child: Text(contractor.name),
                            ),
                          ),
                        ],
                        onChanged: widget.controller.setContractorFilter,
                      ),
                    ],
                  ),
                ),
                // Areas list
                Expanded(
                  child: filteredAreas.isEmpty
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
                                'Нет участков',
                                style: AppTextStyles.headline.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredAreas.length,
                          itemBuilder: (context, index) {
                            final area = filteredAreas[index];
                            final isSelected = widget.state.selectedArea?.id == area.id;
                            final contractor = widget.data.contractors.firstWhere(
                              (c) => c.id == area.defaultContractorId,
                              orElse: () => widget.data.contractors.first,
                            );

                            return InkWell(
                              onTap: () {
                                widget.controller.selectArea(area);
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
                                            area.name,
                                            style: AppTextStyles.headline,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppPadding.small,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: area.status == CleaningAreaStatus.active
                                                ? AppColors.success.withOpacity(0.2)
                                                : AppColors.textTertiary.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            area.status == CleaningAreaStatus.active
                                                ? 'Активный'
                                                : 'Неактивный',
                                            style: AppTextStyles.caption.copyWith(
                                              color: area.status == CleaningAreaStatus.active
                                                  ? AppColors.success
                                                  : AppColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (area.description != null) ...[
                                      const SizedBox(height: AppPadding.xs),
                                      Text(
                                        area.description!,
                                        style: AppTextStyles.footnote,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                    if (area.defaultContractorId != null) ...[
                                      const SizedBox(height: AppPadding.xs),
                                      Text(
                                        'Ответственный: ${contractor.name}',
                                        style: AppTextStyles.footnote,
                                      ),
                                    ],
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
      ],
    );
  }

  void _showCreateAreaDialog(List<List<double>> geometry) {
    AreasDialogs.showCreateAreaDialog(
      context: context,
      controller: widget.controller,
      data: widget.data,
      geometry: geometry,
    );
  }
}

class _AreaInfoPanel extends StatelessWidget {
  const _AreaInfoPanel({
    required this.area,
    required this.contractors,
    required this.canEdit,
    required this.controller,
  });

  final CleaningArea area;
  final List<Organization> contractors;
  final bool canEdit;
  final AreasController controller;

  @override
  Widget build(BuildContext context) {
    final contractor = contractors.firstWhere(
      (c) => c.id == area.defaultContractorId,
      orElse: () => contractors.isNotEmpty ? contractors.first : Organization(
        id: '',
        type: OrganizationType.contractor,
        name: '—',
        bin: '',
        isActive: false,
      ),
    );

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
                      area.name,
                      style: AppTextStyles.title2,
                    ),
                  ),
                  if (canEdit)
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => controller.selectArea(null),
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
                  color: area.status == CleaningAreaStatus.active
                      ? AppColors.success.withOpacity(0.2)
                      : AppColors.textTertiary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  area.status == CleaningAreaStatus.active ? 'Активный' : 'Неактивный',
                  style: AppTextStyles.caption.copyWith(
                    color: area.status == CleaningAreaStatus.active
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
                if (area.description != null) ...[
                  Text(
                    'Описание',
                    style: AppTextStyles.footnote.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppPadding.xs),
                  Text(
                    area.description!,
                    style: AppTextStyles.body,
                  ),
                  const SizedBox(height: AppPadding.normal),
                ],
                Text(
                  'Город',
                  style: AppTextStyles.footnote.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppPadding.xs),
                Text(
                  area.city,
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: AppPadding.normal),
                const Divider(),
                const SizedBox(height: AppPadding.normal),
                Text(
                  'Ответственный',
                  style: AppTextStyles.footnote.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppPadding.xs),
                Text(
                  area.defaultContractorId != null ? contractor.name : 'Не назначен',
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: AppPadding.normal),
                if (canEdit) ...[
                  const Divider(),
                  const SizedBox(height: AppPadding.normal),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        // TODO: Implement edit dialog
                      },
                      child: const Text('Редактировать'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ForbiddenAreasPage extends StatelessWidget {
  const _ForbiddenAreasPage({
    required this.scaffoldKey,
    this.webNavbarWidgets,
    this.mobileNavbarWidgets,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;
  final List<Widget>? webNavbarWidgets;
  final List<Widget>? mobileNavbarWidgets;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      key: scaffoldKey,
      drawer: !kIsWeb ? const DrawerMobile() : null,
      appBar: kIsWeb
          ? null
          : AppBar(
              title: Text(s.insufficient_permissions),
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
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline, size: 64, color: Colors.redAccent),
                  const SizedBox(height: 16),
                  Text(
                    s.insufficient_permissions,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.insufficient_permissions_message,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

