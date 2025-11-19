import 'package:akimat_project/core/di.dart';
import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/core/ui/app_textstyle.dart';
import 'package:akimat_project/modules/dashboard/src/controller/monitoring_controller.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/organization.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/organization_type.dart';
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

    return Container(
      width: 450,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppSize.cardRadius),
          bottomLeft: Radius.circular(AppSize.cardRadius),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(-4, 0),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // Заголовок с градиентом
          Container(
            padding: const EdgeInsets.all(AppPadding.normal),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.1),
                  AppColors.primary.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border(
                bottom: BorderSide(color: AppColors.divider, width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.mode == 'area' 
                        ? Icons.map_outlined
                        : widget.mode == 'polygon'
                            ? Icons.location_city_outlined
                            : Icons.videocam_outlined,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppPadding.normal),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getTitle(),
                        style: AppTextStyles.title1.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
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
                  child: InkWell(
                    onTap: () {
                      // Убираем фокус с полей ввода
                      FocusScope.of(context).unfocus();
                      _resetForm();
                      widget.controller.clearDrawingGeometry();
                      widget.controller.setCreateMode(null);
                      widget.onClose?.call();
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.divider.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Контент
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppPadding.normal),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Поля формы
                    _buildFormFields(),
                    const SizedBox(height: AppPadding.large),
                    // Кнопка начала рисования
                    if (!isDrawing && drawingGeometry.isEmpty)
                      _buildStartDrawingButton(),
                    // Информация о рисовании
                    if (isDrawing || drawingGeometry.isNotEmpty)
                      _buildDrawingInfo(drawingGeometry),
                    const SizedBox(height: AppPadding.large),
                    // Кнопки действий
                    _buildActionButtons(),
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
          child: FilledButton(
            onPressed: _canSave() ? _handleSave : null,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSize.smallRadius),
              ),
            ),
            child: const Text(
              'Сохранить',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: AppPadding.small),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              // Убираем фокус с полей ввода
              FocusScope.of(context).unfocus();
              _resetForm();
              widget.controller.clearDrawingGeometry();
              widget.controller.setCreateMode(null);
              widget.onClose?.call();
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: AppColors.divider),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSize.smallRadius),
              ),
            ),
            child: const Text(
              'Отмена',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
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
    return true;
  }

  Future<void> _handleSave() async {
    if (!_canSave()) return;

    final state = ref.read(monitoringControllerProvider);
    final geometry = state.drawingGeometry;

    // Проверка минимального количества точек
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

    try {
      if (widget.mode == 'area') {
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
    widget.controller.clearDrawingGeometry();
  }

  Future<List<Organization>> _loadContractors() async {
    final orgRepo = ref.read(organizationsRepositoryProvider);
    final organizations = await orgRepo.loadOrganizations();
    return organizations
        .where((org) => org.type == OrganizationType.contractor)
        .toList();
  }
}

