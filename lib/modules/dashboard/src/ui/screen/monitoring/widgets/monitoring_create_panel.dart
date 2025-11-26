import 'package:akimat_project/core/di.dart';
import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/core/ui/app_textstyle.dart';
import 'package:akimat_project/modules/dashboard/src/controller/monitoring_controller.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/organization.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/organization_type.dart';
import 'package:akimat_project/modules/dashboard/src/model/polygons/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Боковая панель справа для создания/редактирования участков и полигонов
class MonitoringCreatePanel extends ConsumerStatefulWidget {
  final MonitoringController controller;
  final String? mode; // 'area', 'polygon', 'camera', null
  final Function()? onClose;

  const MonitoringCreatePanel({
    super.key,
    required this.controller,
    this.mode,
    this.onClose,
  });

  @override
  ConsumerState<MonitoringCreatePanel> createState() => _MonitoringCreatePanelState();
}

class _MonitoringCreatePanelState extends ConsumerState<MonitoringCreatePanel> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController(text: 'Петропавловск');
  
  String? _selectedContractorId;
  bool _isActive = true;
  bool _isCloseHovered = false;
  // Поля для камеры
  String? _selectedPolygonId;
  CameraType _cameraType = CameraType.lpr;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(monitoringControllerProvider);
    final drawingGeometry = state.drawingGeometry;
    final isDrawing = drawingGeometry.isNotEmpty;

    debugPrint('MonitoringCreatePanel: build called, mode=${widget.mode}');
    debugPrint('MonitoringCreatePanel: drawingGeometry.length=${drawingGeometry.length}');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.cardBackground,
            AppColors.cardBackground.withValues(alpha: 0.98),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, -8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Заголовок с градиентом
          Container(
            padding: const EdgeInsets.all(AppPadding.normal + 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.15),
                  AppColors.primary.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.divider.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.mode == 'area' 
                        ? Icons.map_rounded
                        : widget.mode == 'polygon'
                            ? Icons.location_city_rounded
                            : Icons.videocam_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: AppPadding.normal),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getTitle(),
                        style: AppTextStyles.title2.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Нарисуйте геометрию на карте',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: MouseRegion(
                    onEnter: (_) => setState(() => _isCloseHovered = true),
                    onExit: (_) => setState(() => _isCloseHovered = false),
                    child: InkWell(
                      onTap: () {
                        _handleClose();
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _isCloseHovered
                              ? AppColors.error.withOpacity(0.1)
                              : AppColors.divider.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: _isCloseHovered
                              ? AppColors.error
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Контент
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppPadding.normal),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Поля формы (показываем для камеры, до начала рисования, или после завершения рисования)
                    if (widget.mode == 'camera' || 
                        drawingGeometry.isEmpty || 
                        (drawingGeometry.length >= 3 && !state.isEditingGeometry))
                      _buildFormFields(),
                    // Кнопка начала рисования (только если еще не начали рисовать)
                    if (drawingGeometry.isEmpty && widget.mode != 'camera')
                      ...[
                        if (widget.mode != 'camera') const SizedBox(height: AppPadding.large),
                        _buildStartDrawingButton(),
                      ],
                    // Информация о рисовании для участков/полигонов (3 точки минимум)
                    if (drawingGeometry.isNotEmpty && 
                        drawingGeometry.length < 3 && 
                        !state.isEditingGeometry &&
                        widget.mode != 'camera')
                      ...[
                        const SizedBox(height: AppPadding.normal),
                        Container(
                          padding: const EdgeInsets.all(AppPadding.small),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppSize.smallRadius),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.edit_location_alt, size: 20, color: AppColors.primary),
                              const SizedBox(width: AppPadding.small),
                              Text(
                                'Точек: ${drawingGeometry.length} / 3 минимум',
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    // Информация о рисовании для камеры (1 точка)
                    if (drawingGeometry.isNotEmpty && 
                        widget.mode == 'camera' &&
                        !state.isEditingGeometry)
                      ...[
                        const SizedBox(height: AppPadding.normal),
                        Container(
                          padding: const EdgeInsets.all(AppPadding.small),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppSize.smallRadius),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.location_on, size: 20, color: AppColors.success),
                              const SizedBox(width: AppPadding.small),
                              Text(
                                'Точка выбрана: ${drawingGeometry.length}',
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    // Информация в режиме редактирования
                    if (state.isEditingGeometry)
                      ...[
                        const SizedBox(height: AppPadding.normal),
                        Container(
                          padding: const EdgeInsets.all(AppPadding.normal),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppSize.smallRadius),
                            border: Border.all(color: Colors.orange, width: 1),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.edit, size: 20, color: Colors.orange),
                                  const SizedBox(width: AppPadding.small),
                                  Text(
                                    'Режим редактирования',
                                    style: AppTextStyles.body.copyWith(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppPadding.small),
                              Text(
                                'Кликните на красную точку на карте для удаления',
                                style: AppTextStyles.caption.copyWith(
                                  color: Colors.orange,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    // Кнопки действий
                    // Для камеры: когда выбрана хотя бы 1 точка
                    // Для участков/полигонов: когда выбрано минимум 3 точки
                    if ((widget.mode == 'camera' && drawingGeometry.isNotEmpty) ||
                        (widget.mode != 'camera' && drawingGeometry.isNotEmpty && drawingGeometry.length >= 3 && !state.isEditingGeometry))
                      ...[
                        const SizedBox(height: AppPadding.large),
                        _buildActionButtons(),
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

  String _getTitle() {
    switch (widget.mode) {
      case 'area':
        return 'Создать участок';
      case 'polygon':
        return 'Создать полигон';
      case 'camera':
        return 'Добавить камеру';
      default:
        return 'Создание';
    }
  }

  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Название*',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSize.cardRadius),
            ),
          ),
          style: AppTextStyles.body,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Введите название';
            }
            return null;
          },
        ),
        const SizedBox(height: AppPadding.normal),
        if (widget.mode == 'area') ...[
          TextFormField(
            controller: _cityController,
            decoration: InputDecoration(
              labelText: 'Город*',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSize.cardRadius),
              ),
            ),
            style: AppTextStyles.body,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Введите город';
              }
              return null;
            },
          ),
          const SizedBox(height: AppPadding.normal),
          FutureBuilder<List<Organization>>(
            future: _loadContractors(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox.shrink();
              }
              final contractors = snapshot.data!
                  .where((org) => org.type == OrganizationType.contractor)
                  .toList();
              return DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Подрядчик по умолчанию',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSize.cardRadius),
                  ),
                ),
                initialValue: _selectedContractorId,
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Не выбран'),
                  ),
                  ...contractors.map((org) => DropdownMenuItem<String>(
                        value: org.id,
                        child: Text(org.name),
                      )),
                ],
                onChanged: (value) {
                  setState(() => _selectedContractorId = value);
                },
              );
            },
          ),
        ],
        if (widget.mode == 'polygon') ...[
          TextFormField(
            controller: _addressController,
            decoration: InputDecoration(
              labelText: 'Адрес',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSize.cardRadius),
              ),
            ),
            style: AppTextStyles.body,
          ),
          const SizedBox(height: AppPadding.normal),
          CheckboxListTile(
            title: const Text('Активен'),
            value: _isActive,
            onChanged: (value) {
              setState(() => _isActive = value ?? true);
            },
          ),
        ],
        const SizedBox(height: AppPadding.normal),
        TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(
            labelText: 'Описание',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSize.cardRadius),
            ),
          ),
          style: AppTextStyles.body,
          maxLines: 3,
        ),
        if (widget.mode == 'camera') ...[
          const SizedBox(height: AppPadding.normal),
          // Выбор полигона для камеры
          Builder(
            builder: (context) {
              final monitoringState = ref.watch(monitoringControllerProvider);
              final polygons = monitoringState.data.valueOrNull?.polygons ?? [];
              
              return DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Полигон*',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSize.cardRadius),
                  ),
                ),
                value: _selectedPolygonId,
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Выберите полигон'),
                  ),
                  ...polygons.map((polygon) => DropdownMenuItem<String>(
                        value: polygon.id,
                        child: Text(polygon.name),
                      )),
                ],
                onChanged: (value) {
                  setState(() => _selectedPolygonId = value);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Выберите полигон';
                  }
                  return null;
                },
              );
            },
          ),
          const SizedBox(height: AppPadding.normal),
          // Тип камеры
          DropdownButtonFormField<CameraType>(
            decoration: InputDecoration(
              labelText: 'Тип камеры*',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSize.cardRadius),
              ),
            ),
            value: _cameraType,
            items: const [
              DropdownMenuItem<CameraType>(
                value: CameraType.lpr,
                child: Text('LPR (Распознавание номеров)'),
              ),
              DropdownMenuItem<CameraType>(
                value: CameraType.volume,
                child: Text('VOLUME (Объем)'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _cameraType = value);
              }
            },
          ),
          const SizedBox(height: AppPadding.normal),
          CheckboxListTile(
            title: const Text('Активна'),
            value: _isActive,
            onChanged: (value) {
              setState(() => _isActive = value ?? true);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildStartDrawingButton() {
    return Container(
      padding: const EdgeInsets.all(AppPadding.normal),
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground,
        borderRadius: BorderRadius.circular(AppSize.smallRadius),
        border: Border.all(color: AppColors.primary, width: 2, style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          Icon(Icons.edit_location_alt, size: 48, color: AppColors.primary),
          const SizedBox(height: AppPadding.small),
          Text(
            'Нажмите на карту, чтобы начать рисование',
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppPadding.small),
          Text(
            'Кликните на карте для добавления точек. Двойной клик или кнопка "Завершить" для завершения.',
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawingInfo(List<List<double>> drawingGeometry) {
    return Container(
      padding: const EdgeInsets.all(AppPadding.normal),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSize.smallRadius),
        border: Border.all(color: AppColors.success, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.success, size: 20),
              const SizedBox(width: AppPadding.small),
              Text(
                'Режим рисования активен',
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppPadding.small),
          Text(
            'Точек: ${drawingGeometry.length}',
            style: AppTextStyles.caption,
          ),
          if (drawingGeometry.length >= 3)
            Text(
              'Минимум 3 точки для полигона',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.success,
              ),
            ),
          const SizedBox(height: AppPadding.small),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: drawingGeometry.length >= 3
                      ? () => widget.controller.finishDrawing()
                      : null,
                  icon: const Icon(Icons.check),
                  label: const Text('Завершить'),
                ),
              ),
              const SizedBox(width: AppPadding.small),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => widget.controller.clearDrawingGeometry(),
                  icon: const Icon(Icons.clear),
                  label: const Text('Очистить'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _canSave() ? _handleSave : null,
            icon: const Icon(Icons.check_circle_rounded, size: 20),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: _canSave() ? 4 : 0,
              shadowColor: AppColors.primary.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            label: const Text(
              'Сохранить',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppPadding.small),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              _handleClose();
            },
            icon: const Icon(Icons.close_rounded, size: 18),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(
                color: AppColors.divider.withOpacity(0.5),
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            label: const Text(
              'Отмена',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool _canSave() {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return false;
    final state = ref.read(monitoringControllerProvider);
    if (widget.mode == 'area' || widget.mode == 'polygon') {
      return state.drawingGeometry.length >= 3;
    }
    if (widget.mode == 'camera') {
      // Для камеры нужна хотя бы 1 точка
      return state.drawingGeometry.isNotEmpty && _selectedPolygonId != null;
    }
    return true;
  }

  Future<void> _handleSave() async {
    if (!_canSave()) return;

    final state = ref.read(monitoringControllerProvider);
    final geometry = state.drawingGeometry;

    try {
      if (widget.mode == 'area') {
        // Проверка минимального количества точек для участка
        if (geometry.length < 3) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Необходимо минимум 3 точки для создания участка'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
        await widget.controller.createCleaningArea(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          geometry: geometry,
          city: _cityController.text.trim(),
          defaultContractorId: _selectedContractorId,
        );
      } else if (widget.mode == 'polygon') {
        // Проверка минимального количества точек для полигона
        if (geometry.length < 3) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Необходимо минимум 3 точки для создания полигона'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
        await widget.controller.createPolygon(
          name: _nameController.text.trim(),
          address: _addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          geometry: geometry,
          isActive: _isActive,
        );
      } else if (widget.mode == 'camera') {
        // Для камеры используем первую точку как location
        if (geometry.isEmpty || _selectedPolygonId == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Выберите точку на карте и полигон'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
        // Берем первую точку: [longitude, latitude]
        final location = geometry.first;
        await widget.controller.createCamera(
          polygonId: _selectedPolygonId!,
          type: _cameraType,
          name: _nameController.text.trim(),
          location: location, // [lon, lat]
          isActive: _isActive,
        );
      }

      // После успешного создания данные уже обновлены через refresh() в контроллере
      // Закрываем панель и очищаем форму
      if (mounted) {
        _resetForm();
        widget.controller.setCreateMode(null);
        widget.onClose?.call();
        
        // Показываем сообщение об успехе
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_getTitle()} успешно создан. Список обновлен.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Ошибка при создании: $e';
        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('500') || errorStr.contains('internal error')) {
          errorMessage = 'Ошибка сервера при создании. Пожалуйста, попробуйте позже или обратитесь к администратору.';
        } else if (errorStr.contains('401') || errorStr.contains('403')) {
          errorMessage = 'Ошибка авторизации. Пожалуйста, войдите заново.';
        } else if (errorStr.contains('400')) {
          errorMessage = 'Некорректные данные. Проверьте заполнение всех полей.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _resetForm() {
    _nameController.clear();
    _descriptionController.clear();
    _addressController.clear();
    _cityController.text = 'Петропавловск';
    _selectedContractorId = null;
    _isActive = true;
    _selectedPolygonId = null;
    _cameraType = CameraType.lpr;
    widget.controller.clearDrawingGeometry();
  }

  Future<List<Organization>> _loadContractors() async {
    final orgRepo = ref.read(organizationsRepositoryProvider);
    final organizations = await orgRepo.loadOrganizations();
    return organizations
        .where((org) => org.type == OrganizationType.contractor)
        .toList();
  }

  void _handleClose() {
    debugPrint('MonitoringCreatePanel._handleClose: Called');
    
    try {
      // Убираем фокус с полей ввода
      FocusScope.of(context).unfocus();
      debugPrint('MonitoringCreatePanel._handleClose: Focus unfocused');
      
      // Сбрасываем форму
      _resetForm();
      debugPrint('MonitoringCreatePanel._handleClose: Form reset');
      
      // Очищаем геометрию рисования
      widget.controller.clearDrawingGeometry();
      debugPrint('MonitoringCreatePanel._handleClose: Drawing geometry cleared');
      
      // Закрываем панель через контроллер
      widget.controller.setCreateMode(null);
      debugPrint('MonitoringCreatePanel._handleClose: setCreateMode(null) called');
      
      // Вызываем callback, если он есть
      if (widget.onClose != null) {
        widget.onClose!();
        debugPrint('MonitoringCreatePanel._handleClose: onClose callback called');
      }
      
      debugPrint('MonitoringCreatePanel._handleClose: Completed successfully');
    } catch (e, stack) {
      debugPrint('MonitoringCreatePanel._handleClose: ERROR - $e');
      debugPrint('MonitoringCreatePanel._handleClose: Stack - $stack');
      
      // В случае ошибки все равно пытаемся закрыть панель
      try {
        widget.controller.setCreateMode(null);
        widget.onClose?.call();
      } catch (_) {
        // Игнорируем ошибки при попытке закрыть
      }
    }
  }
}

