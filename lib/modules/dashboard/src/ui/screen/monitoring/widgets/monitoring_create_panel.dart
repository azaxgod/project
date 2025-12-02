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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Компактный заголовок
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Row(
            children: [
              Icon(
                widget.mode == 'area' 
                    ? Icons.map_rounded
                    : widget.mode == 'polygon'
                        ? Icons.location_city_rounded
                        : Icons.videocam_rounded,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _getTitle(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _handleClose,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
          // Компактный контент
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Инструкция (до начала рисования)
                    if (drawingGeometry.isEmpty)
                      _buildDrawingInstructions(),
                    // Счетчик точек (во время рисования)
                    if (drawingGeometry.isNotEmpty && widget.mode != 'camera')
                      _buildPointsCounter(drawingGeometry.length),
                    // Точка выбрана (для камеры)
                    if (widget.mode == 'camera' && drawingGeometry.isNotEmpty)
                      _buildCameraPointSelected(),
                    // Форма заполнения
                    if (_shouldShowForm(drawingGeometry))
                      ...[
                        const SizedBox(height: 12),
                        _buildFormFields(),
                      ],
                    // Кнопки действий
                    if (_shouldShowActions(drawingGeometry, state.isEditingGeometry))
                      ...[
                        const SizedBox(height: 12),
                        _buildCompactActionButtons(),
                      ],
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    
  }

  bool _shouldShowForm(List<List<double>> geometry) {
    if (widget.mode == 'camera') return geometry.isNotEmpty;
    return geometry.length >= 3;
  }

  bool _shouldShowActions(List<List<double>> geometry, bool isEditing) {
    if (widget.mode == 'camera') return geometry.isNotEmpty;
    return geometry.length >= 3 && !isEditing;
  }

  Widget _buildDrawingInstructions() {
    final isCamera = widget.mode == 'camera';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCamera ? Icons.place_rounded : Icons.touch_app_rounded,
            size: 28,
            color: AppColors.primary,
          ),
          const SizedBox(height: 6),
          Text(
            isCamera ? 'Кликните на карту' : 'Добавьте точки на карте',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isCamera 
                ? 'Выберите место для камеры'
                : 'Минимум 3 точки для ${widget.mode == "area" ? "участка" : "полигона"}',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPointsCounter(int count) {
    final isEnough = count >= 3;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: (isEnough ? AppColors.success : AppColors.warning).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isEnough ? AppColors.success : AppColors.warning),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isEnough ? Icons.check_circle : Icons.edit_location_alt,
            size: 16,
            color: isEnough ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(width: 6),
          Text(
            isEnough ? 'Точек: $count ✓' : 'Точек: $count / 3',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isEnough ? AppColors.success : AppColors.warning,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPointSelected() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.success),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, size: 16, color: AppColors.success),
          const SizedBox(width: 6),
          Text(
            'Место выбрано ✓',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.success,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _handleClose,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              side: BorderSide(color: AppColors.divider),
            ),
            child: const Text('Отмена', style: TextStyle(fontSize: 12)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            onPressed: _canSave() ? _handleSave : null,
            icon: const Icon(Icons.check, size: 16),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10),
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.divider,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            label: const Text('Сохранить', style: TextStyle(fontSize: 12)),
          ),
        ),
      ],
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
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCompactTextField(
          controller: _nameController,
          label: 'Название',
          icon: Icons.label_outline,
          isRequired: true,
        ),
        const SizedBox(height: 8),
        if (widget.mode == 'area') ...[
          _buildCompactTextField(
            controller: _cityController,
            label: 'Город',
            icon: Icons.location_city_outlined,
            isRequired: true,
          ),
          const SizedBox(height: 8),
        ],
        if (widget.mode == 'polygon') ...[
          _buildCompactTextField(
            controller: _addressController,
            label: 'Адрес',
            icon: Icons.place_outlined,
          ),
          const SizedBox(height: 8),
        ],
        if (widget.mode == 'camera') ...[
          _buildPolygonDropdown(),
          const SizedBox(height: 8),
          _buildCameraTypeDropdown(),
          const SizedBox(height: 8),
        ],
        _buildCompactTextField(
          controller: _descriptionController,
          label: 'Описание',
          icon: Icons.notes_outlined,
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildCompactTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isRequired = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        labelStyle: const TextStyle(fontSize: 12),
        prefixIcon: Icon(icon, size: 18),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      validator: isRequired
          ? (value) => value == null || value.isEmpty ? 'Обязательно' : null
          : null,
    );
  }

  Widget _buildPolygonDropdown() {
    final monitoringState = ref.watch(monitoringControllerProvider);
    final polygons = monitoringState.data.valueOrNull?.polygons ?? [];
    
    return DropdownButtonFormField<String>(
      value: _selectedPolygonId,
      isDense: true,
      style: const TextStyle(fontSize: 13, color: Colors.black87),
      decoration: InputDecoration(
        labelText: 'Полигон *',
        labelStyle: const TextStyle(fontSize: 12),
        prefixIcon: const Icon(Icons.location_city_outlined, size: 18),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.divider),
        ),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('Выберите', style: TextStyle(fontSize: 13))),
        ...polygons.map((p) => DropdownMenuItem(
          value: p.id, 
          child: Text(p.name, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
        )),
      ],
      onChanged: (value) => setState(() => _selectedPolygonId = value),
      validator: (value) => value == null ? 'Выберите' : null,
    );
  }

  Widget _buildCameraTypeDropdown() {
    return DropdownButtonFormField<CameraType>(
      value: _cameraType,
      isDense: true,
      style: const TextStyle(fontSize: 13, color: Colors.black87),
      decoration: InputDecoration(
        labelText: 'Тип камеры',
        labelStyle: const TextStyle(fontSize: 12),
        prefixIcon: const Icon(Icons.videocam_outlined, size: 18),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.divider),
        ),
      ),
      items: const [
        DropdownMenuItem(value: CameraType.lpr, child: Text('LPR (Номера)', style: TextStyle(fontSize: 13))),
        DropdownMenuItem(value: CameraType.volume, child: Text('VOLUME', style: TextStyle(fontSize: 13))),
      ],
      onChanged: (value) {
        if (value != null) setState(() => _cameraType = value);
      },
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

