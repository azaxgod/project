import 'dart:html' as html;
import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/core/ui/app_textstyle.dart';
import 'package:akimat_project/modules/dashboard/src/controller/monitoring_controller.dart';
import 'package:akimat_project/modules/dashboard/src/controller/monitoring_state.dart';
import 'package:akimat_project/modules/dashboard/src/model/areas/cleaning_area.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/user_role.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MonitoringAreasTab extends ConsumerStatefulWidget {
  final MonitoringState state;
  final MonitoringData data;
  final MonitoringController controller;
  final bool canEdit;

  const MonitoringAreasTab({
    super.key,
    required this.state,
    required this.data,
    required this.controller,
    required this.canEdit,
  });

  @override
  ConsumerState<MonitoringAreasTab> createState() => _MonitoringAreasTabState();
}

class _MonitoringAreasTabState extends ConsumerState<MonitoringAreasTab> {
  int _currentPage = 0;
  static const int _itemsPerPage = 5;
  String? _lastTab; // Отслеживаем последнюю вкладку
  static const String _storageKey = 'monitoring_areas_page';

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
  void didUpdateWidget(MonitoringAreasTab oldWidget) {
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
    if (oldWidget.data.areas.length != widget.data.areas.length) {
      // Проверяем, что текущая страница не выходит за границы
      final totalPages = (widget.data.areas.length / _itemsPerPage).ceil();
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
    final isCreating = currentState.createMode == 'area';
    
    // Пагинация
    final totalPages = (widget.data.areas.length / _itemsPerPage).ceil();
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, widget.data.areas.length);
    final displayedAreas = widget.data.areas.sublist(startIndex, endIndex);
    
    return Column(
      children: [
        // Список участков с пагинацией
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: displayedAreas.isEmpty
                    ? Center(
                        child: Text(
                          'Нет участков',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppPadding.normal),
                        itemCount: displayedAreas.length,
                        itemBuilder: (context, index) {
                          final area = displayedAreas[index];
                          final isSelected = area.id == currentState.selectedAreaId;
                          return _buildAreaCard(area, isSelected);
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
        // Кнопка создания участка снизу (только если не в режиме создания)
        // KGU_ZKH_ADMIN может создавать участки, LANDFILL_ADMIN и AKIMAT_ADMIN - нет
        if (widget.canEdit && 
            !isCreating &&
            widget.state.role != UserRole.landfillAdmin &&
            widget.state.role != UserRole.akimatAdmin)
          Container(
            padding: const EdgeInsets.all(AppPadding.normal),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.divider, width: 0.5),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  widget.controller.setCreateMode('area');
                },
                icon: const Icon(Icons.add_circle_outline, size: 22),
                label: const Text('Создать участок'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAreaCard(CleaningArea area, bool isSelected) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppPadding.small),
      color: isSelected
          ? AppColors.primary.withOpacity(0.1)
          : AppColors.cardBackground,
      child: InkWell(
        onTap: () => widget.controller.selectArea(area.id),
        child: Padding(
          padding: const EdgeInsets.all(AppPadding.normal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                area.name,
                style: AppTextStyles.title2.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (area.description != null) ...[
                const SizedBox(height: AppPadding.small),
                Text(
                  area.description!,
                  style: AppTextStyles.caption,
                ),
              ],
              const SizedBox(height: AppPadding.small),
              Row(
                children: [
                  _buildStatusChip(area.status),
                  const SizedBox(width: AppPadding.small),
                  Chip(
                    label: Text(area.city),
                    labelStyle: AppTextStyles.caption,
                  ),
                ],
              ),
              // Подрядчик по умолчанию
              if (area.defaultContractorId != null) ...[
                const SizedBox(height: AppPadding.small),
                _buildContractorChip(area.defaultContractorId!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(CleaningAreaStatus status) {
    Color color;
    String label;
    switch (status) {
      case CleaningAreaStatus.active:
        color = Colors.green;
        label = 'Активен';
        break;
      case CleaningAreaStatus.inactive:
        color = Colors.grey;
        label = 'Неактивен';
        break;
      default:
        color = Colors.orange;
        label = 'Неизвестно';
    }
    return Chip(
      label: Text(label),
      labelStyle: AppTextStyles.caption.copyWith(color: color),
      backgroundColor: color.withOpacity(0.1),
    );
  }

  Widget _buildContractorChip(String contractorId) {
    // Находим подрядчика по ID
    final contractor = widget.data.contractors.where(
      (org) => org.id == contractorId,
    ).firstOrNull;
    
    if (contractor == null) {
      return const SizedBox.shrink();
    }
    
    return Row(
      children: [
        Icon(Icons.business, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            'Подрядчик: ${contractor.name}',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

