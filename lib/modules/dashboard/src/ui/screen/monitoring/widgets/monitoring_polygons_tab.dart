import 'dart:html' as html;
import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/core/ui/app_textstyle.dart';
import 'package:akimat_project/modules/dashboard/src/controller/monitoring_controller.dart';
import 'package:akimat_project/modules/dashboard/src/controller/monitoring_state.dart';
import 'package:akimat_project/modules/dashboard/src/model/polygons/camera.dart';
import 'package:akimat_project/modules/dashboard/src/model/polygons/polygon.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MonitoringPolygonsTab extends ConsumerStatefulWidget {
  final MonitoringState state;
  final MonitoringData data;
  final MonitoringController controller;
  final bool canEdit;

  const MonitoringPolygonsTab({
    super.key,
    required this.state,
    required this.data,
    required this.controller,
    required this.canEdit,
  });

  @override
  ConsumerState<MonitoringPolygonsTab> createState() => _MonitoringPolygonsTabState();
}

class _MonitoringPolygonsTabState extends ConsumerState<MonitoringPolygonsTab> {
  int _currentPage = 0;
  static const int _itemsPerPage = 5;
  String? _lastTab; // Отслеживаем последнюю вкладку
  static const String _storageKey = 'monitoring_polygons_page';

  @override
  void initState() {
    super.initState();
    _lastTab = widget.state.selectedTab;
    _restorePage();
  }

  Future<void> _restorePage() async {
    if (kIsWeb) {
      try {
        final savedPage = html.window.localStorage[_storageKey];
        if (savedPage != null) {
          final page = int.tryParse(savedPage);
          if (page != null && page >= 0) {
            setState(() {
              _currentPage = page;
            });
          }
        }
      } catch (e) {
        debugPrint('Error restoring page: $e');
      }
    }
  }

  Future<void> _savePage(int page) async {
    if (kIsWeb) {
      try {
        html.window.localStorage[_storageKey] = page.toString();
      } catch (e) {
        debugPrint('Error saving page: $e');
      }
    }
  }

  @override
  void didUpdateWidget(MonitoringPolygonsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Если переключили вкладку, сбрасываем страницу на первую
    if (oldWidget.state.selectedTab != widget.state.selectedTab) {
      setState(() {
        _currentPage = 0;
        _lastTab = widget.state.selectedTab;
      });
      _savePage(0);
    }
    // Если обновились данные, но вкладка та же - сохраняем текущую страницу
    // (не сбрасываем, если количество элементов не изменилось критически)
    if (oldWidget.data.polygons.length != widget.data.polygons.length) {
      // Проверяем, что текущая страница не выходит за границы
      final totalPages = (widget.data.polygons.length / _itemsPerPage).ceil();
      if (_currentPage >= totalPages && totalPages > 0) {
        setState(() {
          _currentPage = totalPages - 1;
        });
        _savePage(_currentPage);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ВАЖНО: Получаем актуальное состояние через ref.watch
    // чтобы виджет перестраивался при изменении createMode
    final currentState = ref.watch(monitoringControllerProvider);
    final isCreatingPolygon = currentState.createMode == 'polygon';
    final isCreatingCamera = currentState.createMode == 'camera';
    final isCreating = isCreatingPolygon || isCreatingCamera;
    
    // Пагинация
    final totalPages = (widget.data.polygons.length / _itemsPerPage).ceil();
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, widget.data.polygons.length);
    final displayedPolygons = widget.data.polygons.sublist(startIndex, endIndex);
    
    return Column(
      children: [
        // Список полигонов с пагинацией
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: displayedPolygons.isEmpty
                    ? Center(
                        child: Text(
                          'Нет полигонов',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppPadding.normal),
                        itemCount: displayedPolygons.length,
                        itemBuilder: (context, index) {
                          final polygon = displayedPolygons[index];
                          final isSelected = polygon.id == currentState.selectedPolygonId;
                          final polygonCameras = widget.data.cameras
                              .where((c) => c.polygonId == polygon.id)
                              .toList();
                          return _buildPolygonCard(polygon, polygonCameras, isSelected);
                        },
                      ),
              ),
              // Пагинация
              if (totalPages > 1)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppPadding.normal,
                    vertical: AppPadding.small,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: AppColors.divider, width: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: _currentPage > 0
                            ? () {
                                setState(() {
                                  _currentPage--;
                                });
                                _savePage(_currentPage);
                              }
                            : null,
                        icon: const Icon(Icons.chevron_left),
                        iconSize: 20,
                      ),
                      Text(
                        '${_currentPage + 1} / $totalPages',
                        style: AppTextStyles.caption,
                      ),
                      IconButton(
                        onPressed: _currentPage < totalPages - 1
                            ? () {
                                setState(() {
                                  _currentPage++;
                                });
                                _savePage(_currentPage);
                              }
                            : null,
                        icon: const Icon(Icons.chevron_right),
                        iconSize: 20,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        // Кнопки создания снизу (только если не в режиме создания)
        if (widget.canEdit && !isCreating)
          Container(
            padding: const EdgeInsets.all(AppPadding.normal),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.divider, width: 0.5),
              ),
            ),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      widget.controller.setCreateMode('polygon');
                    },
                    icon: const Icon(Icons.add_circle_outline, size: 22),
                    label: const Text('Создать полигон'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: AppPadding.small),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      widget.controller.setCreateMode('camera');
                    },
                    icon: const Icon(Icons.videocam_outlined, size: 22),
                    label: const Text('Добавить камеру'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPolygonCard(
    Polygon polygon,
    List<Camera> cameras,
    bool isSelected,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppPadding.small),
      color: isSelected
          ? AppColors.primary.withOpacity(0.1)
          : AppColors.cardBackground,
      child: InkWell(
        onTap: () => widget.controller.selectPolygon(polygon.id),
        child: Padding(
          padding: const EdgeInsets.all(AppPadding.normal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                polygon.name,
                style: AppTextStyles.title2.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (polygon.address != null) ...[
                const SizedBox(height: AppPadding.small),
                Text(
                  polygon.address!,
                  style: AppTextStyles.caption,
                ),
              ],
              const SizedBox(height: AppPadding.small),
              Row(
                children: [
                  Chip(
                    label: Text('${cameras.length} камер'),
                    labelStyle: AppTextStyles.caption,
                  ),
                  const SizedBox(width: AppPadding.small),
                  Chip(
                    label: Text(polygon.isActive ? 'Активен' : 'Неактивен'),
                    labelStyle: AppTextStyles.caption.copyWith(
                      color: polygon.isActive ? Colors.green : Colors.grey,
                    ),
                    backgroundColor: (polygon.isActive
                            ? Colors.green
                            : Colors.grey)
                        .withOpacity(0.1),
                  ),
                ],
              ),
              // Список камер полигона
              if (cameras.isNotEmpty) ...[
                const SizedBox(height: AppPadding.small),
                ...cameras.map((camera) => Padding(
                      padding: const EdgeInsets.only(
                        left: AppPadding.normal,
                        top: AppPadding.small,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.videocam,
                            size: 16,
                            color: camera.isActive
                                ? Colors.purple
                                : Colors.grey,
                          ),
                          const SizedBox(width: AppPadding.small),
                          Expanded(
                            child: Text(
                              camera.name,
                              style: AppTextStyles.caption,
                            ),
                          ),
                          Chip(
                            label: Text(camera.type.toString().split('.').last),
                            labelStyle: AppTextStyles.caption.copyWith(
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

