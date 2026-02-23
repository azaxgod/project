import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_textstyle.dart';
import 'package:akimat_project/core/ui/app_padding.dart';

/// Безопасный DropdownButtonFormField, который правильно обрабатывает
/// асинхронную загрузку данных с бэкенда и предотвращает ошибки валидации
class SafeDropdownButtonFormField<T> extends StatefulWidget {
  const SafeDropdownButtonFormField({
    super.key,
    required this.items,
    this.value,
    this.onChanged,
    this.decoration,
    this.validator,
    this.isExpanded = false,
    this.isDense = false,
  });

  final List<DropdownMenuItem<T>> items;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final InputDecoration? decoration;
  final String? Function(T?)? validator;
  final bool isExpanded;
  final bool isDense;

  @override
  State<SafeDropdownButtonFormField<T>> createState() => _SafeDropdownButtonFormFieldState<T>();
}

class _SafeDropdownButtonFormFieldState<T> extends State<SafeDropdownButtonFormField<T>> {

  /// Проверяет, что значение существует в списке items
  T? _getValidValue() {
    if (widget.value == null) return null;
    
    // Проверяем, что значение есть в списке items
    final matchingItems = widget.items.where((item) => item.value == widget.value).toList();
    
    // Должен быть ровно один элемент с таким значением
    if (matchingItems.length == 1) {
      return widget.value;
    }
    
    // Если 0 или больше 1 элемента - значение невалидно
    return null;
  }

  /// Удаляет дубликаты из items, оставляя только первое вхождение
  List<DropdownMenuItem<T>> _removeDuplicates(List<DropdownMenuItem<T>> itemsList) {
    final seen = <T>{};
    final result = <DropdownMenuItem<T>>[];
    
    for (final item in itemsList) {
      if (item.value == null || !seen.contains(item.value)) {
        if (item.value != null) {
          seen.add(item.value!);
        }
        result.add(item);
      }
    }
    
    return result;
  }

  @override
  void didUpdateWidget(SafeDropdownButtonFormField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Принудительно обновляем состояние при изменении value
    if (oldWidget.value != widget.value) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // Если items пустой, показываем disabled TextFormField
    if (widget.items.isEmpty) {
      final localValidator = widget.validator;
      return TextFormField(
        enabled: false,
        decoration: widget.decoration?.copyWith(
          hintText: widget.decoration?.hintText ?? 'Нет данных',
        ),
        validator: localValidator != null
            ? (value) => localValidator(value as T?)
            : null,
      );
    }

    // Удаляем дубликаты значений
    final uniqueItems = _removeDuplicates(widget.items);

    // Убеждаемся, что в items есть элемент с null значением для возможности сброса
    final hasNullItem = uniqueItems.any((item) => item.value == null);
    final safeItems = hasNullItem
        ? uniqueItems
        : [
            DropdownMenuItem<T>(
              value: null,
              child: Text(widget.decoration?.hintText ?? 'Выберите...'),
            ),
            ...uniqueItems,
          ];

    // Получаем валидное значение
    final validValue = _getValidValue();
    
    // Финальная проверка: значение должно существовать в safeItems и быть уникальным
    T? finalValue;
    if (validValue != null) {
      final matchingItems = safeItems.where((item) => item.value == validValue).toList();
      if (matchingItems.length == 1) {
        finalValue = validValue;
      } else {
        finalValue = null;
      }
    } else {
      finalValue = null;
    }

    // Для веба используем PopupMenuButton
    if (kIsWeb) {
      return _buildWebDropdown(context, finalValue, safeItems);
    }

    // Для мобильных устройств используем DropdownButton, который работает лучше
    return _buildMobileDropdown(context, finalValue, safeItems);
  }

  /// Строит dropdown для веба с использованием PopupMenuButton (более надежный для веба)
  Widget _buildWebDropdown(
    BuildContext context,
    T? finalValue,
    List<DropdownMenuItem<T>> safeItems,
  ) {
    // Находим выбранный элемент для отображения
    final selectedItem = safeItems.firstWhere(
      (item) => item.value == finalValue,
      orElse: () => safeItems.firstWhere(
        (item) => item.value == null,
        orElse: () => safeItems.first,
      ),
    );

    // Извлекаем текст из выбранного элемента, чтобы избежать наложения
    String selectedText = '';
    if (selectedItem.child is Text) {
      selectedText = (selectedItem.child as Text).data ?? '';
    } else if (selectedItem.child is DefaultTextStyle) {
      // Если это обернутый текст, пытаемся извлечь
      final defaultTextStyle = selectedItem.child as DefaultTextStyle;
      if (defaultTextStyle.child is Text) {
        selectedText = (defaultTextStyle.child as Text).data ?? '';
      }
    }

    return FormField<T?>(
      key: ValueKey('form_field_${widget.value}'),
      initialValue: finalValue,
      validator: widget.validator,
      builder: (field) {
        return InputDecorator(
          decoration: (widget.decoration ?? const InputDecoration()).copyWith(
            errorText: field.errorText,
            isDense: widget.isDense,
          ),
          isEmpty: finalValue == null,
          child: StatefulBuilder(
            builder: (context, setStateLocal) {
              return PopupMenuButton<T?>(
                key: ValueKey('popup_${widget.value}_${finalValue}'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 16,
                shadowColor: Colors.black.withOpacity(0.15),
                color: AppColors.cardBackground,
                offset: const Offset(0, 8),
                padding: EdgeInsets.zero,
                child: _AnimatedDropdownButton(
                  selectedText: selectedText.isEmpty 
                      ? (widget.decoration?.hintText ?? 'Выберите...')
                      : selectedText,
                  hasValue: finalValue != null,
                  isExpanded: widget.isExpanded,
                ),
                // Используем onSelected как основной механизм
                onSelected: (selectedValue) {
                  debugPrint('SafeDropdownButton: onSelected called with value: $selectedValue');
                  debugPrint('SafeDropdownButton: Current widget.value: ${widget.value}');
                  
                  // ВАЖНО: Всегда вызываем callback, даже если значение не изменилось
                  if (widget.onChanged != null) {
                    widget.onChanged!(selectedValue);
                  }
                  
                  // Обновляем поле формы
                  field.didChange(selectedValue);
                  
                  // Обновляем локальное состояние
                  setStateLocal(() {});
                  
                  // Обновляем состояние виджета
                  setState(() {});
                },
            itemBuilder: (context) {
              return safeItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                
                // Извлекаем текст из item.child для правильного отображения
                String itemText = '';
                if (item.child is Text) {
                  itemText = (item.child as Text).data ?? '';
                } else if (item.child is DefaultTextStyle) {
                  final defaultTextStyle = item.child as DefaultTextStyle;
                  if (defaultTextStyle.child is Text) {
                    itemText = (defaultTextStyle.child as Text).data ?? '';
                  }
                }
                
                final isSelected = item.value == finalValue;
                final isLast = index == safeItems.length - 1;
                
                return PopupMenuItem<T?>(
                  value: item.value,
                  padding: EdgeInsets.zero,
                  // Используем красивый кастомный виджет для веба
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _CustomDropdownMenuItem(
                        text: itemText.isEmpty 
                            ? (widget.decoration?.hintText ?? 'Выберите...')
                            : itemText,
                        isSelected: isSelected,
                        onTap: () {
                          // Закрываем меню
                          Navigator.of(context).pop();
                          
                          debugPrint('SafeDropdownButton: CustomMenuItem onTap called for value: ${item.value}');
                          debugPrint('SafeDropdownButton: Current widget.value: ${widget.value}');
                          
                          // ВАЖНО: Всегда вызываем callback, даже если значение не изменилось
                          // Это позволяет пользователю повторно выбрать "Все" для сброса фильтра
                          if (widget.onChanged != null) {
                            widget.onChanged!(item.value);
                          }
                          
                          // Обновляем поле формы
                          field.didChange(item.value);
                          
                          // Обновляем состояние
                          setState(() {});
                        },
                      ),
                      if (!isLast)
                        Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: AppPadding.normal + 8,
                            vertical: 2,
                          ),
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                AppColors.divider.withOpacity(0.2),
                                AppColors.divider.withOpacity(0.4),
                                AppColors.divider.withOpacity(0.2),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }).toList();
            },
              );
            }
          ),
        );
      },
    );
  }

  /// Строит dropdown для мобильных устройств с использованием DropdownButtonFormField
  Widget _buildMobileDropdown(
    BuildContext context,
    T? finalValue,
    List<DropdownMenuItem<T>> safeItems,
  ) {
    return FormField<T?>(
      key: ValueKey('form_field_${widget.value}'),
      initialValue: finalValue,
      validator: widget.validator,
      builder: (field) {
        return DropdownButtonFormField<T?>(
          value: finalValue,
          decoration: (widget.decoration ?? const InputDecoration()).copyWith(
            errorText: field.errorText,
            isDense: widget.isDense,
          ),
          isExpanded: widget.isExpanded,
          items: safeItems,
          onChanged: (value) {
            debugPrint('SafeDropdownButton: DropdownButtonFormField onChanged called with value: $value');
            debugPrint('SafeDropdownButton: Current widget.value: ${widget.value}');
            
            // ВАЖНО: Всегда вызываем callback, даже если значение не изменилось
            // Это позволяет пользователю повторно выбрать "Все" для сброса фильтра
            if (widget.onChanged != null) {
              widget.onChanged!(value);
            }
            
            // Обновляем поле формы
            field.didChange(value);
            
            // Обновляем состояние виджета
            setState(() {});
          },
        );
      },
    );
  }
}

/// Анимированная кнопка dropdown с красивым дизайном
class _AnimatedDropdownButton extends StatefulWidget {
  const _AnimatedDropdownButton({
    required this.selectedText,
    required this.hasValue,
    required this.isExpanded,
  });

  final String selectedText;
  final bool hasValue;
  final bool isExpanded;

  @override
  State<_AnimatedDropdownButton> createState() => _AnimatedDropdownButtonState();
}

class _AnimatedDropdownButtonState extends State<_AnimatedDropdownButton>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _borderColorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _borderColorAnimation = ColorTween(
      begin: AppColors.divider.withOpacity(0.5),
      end: AppColors.primary.withOpacity(0.6),
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppPadding.normal,
                vertical: AppPadding.small + 2,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.cardBackground,
                    _isHovered
                        ? AppColors.primary.withOpacity(0.03)
                        : AppColors.cardBackground.withOpacity(0.95),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _borderColorAnimation.value ?? AppColors.divider.withOpacity(0.5),
                  width: _isHovered ? 1.8 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _isHovered
                        ? AppColors.primary.withOpacity(0.1)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: _isHovered ? 12 : 8,
                    offset: Offset(0, _isHovered ? 4 : 2),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: widget.isExpanded ? MainAxisSize.max : MainAxisSize.min,
                children: [
                  Expanded(
                    child: Text(
                      widget.selectedText,
                      overflow: TextOverflow.ellipsis,
                      style: widget.hasValue
                          ? AppTextStyles.body.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            )
                          : AppTextStyles.body.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w400,
                            ),
                    ),
                  ),
                  const SizedBox(width: AppPadding.small),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: _isHovered ? 0.5 : 0,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 22,
                      color: _isHovered
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Красивый кастомный виджет для элементов меню dropdown на вебе
class _CustomDropdownMenuItem extends StatefulWidget {
  const _CustomDropdownMenuItem({
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_CustomDropdownMenuItem> createState() => _CustomDropdownMenuItemState();
}

class _CustomDropdownMenuItemState extends State<_CustomDropdownMenuItem>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _borderWidthAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutCubic,
      ),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
    _colorAnimation = ColorTween(
      begin: Colors.transparent,
      end: AppColors.primary.withOpacity(0.12),
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
    _borderWidthAnimation = Tween<double>(begin: 1.5, end: 2.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final backgroundColor = _isHovered
                ? _colorAnimation.value
                : widget.isSelected
                    ? AppColors.primary.withOpacity(0.12)
                    : Colors.transparent;

            return Transform.scale(
              scale: _scaleAnimation.value,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppPadding.normal,
                  vertical: AppPadding.small + 8,
                ),
                decoration: BoxDecoration(
                  gradient: _isHovered || widget.isSelected
                      ? LinearGradient(
                          colors: [
                            AppColors.primary.withOpacity(_isHovered ? 0.15 : 0.1),
                            AppColors.primary.withOpacity(_isHovered ? 0.1 : 0.06),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: !(_isHovered || widget.isSelected) ? Colors.transparent : null,
                  borderRadius: BorderRadius.circular(12),
                  border: widget.isSelected
                      ? Border.all(
                          color: AppColors.primary.withOpacity(0.4),
                          width: _borderWidthAnimation.value,
                        )
                      : _isHovered
                          ? Border.all(
                              color: AppColors.primary.withOpacity(0.2),
                              width: 1.5,
                            )
                          : null,
                  boxShadow: _isHovered
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                            spreadRadius: 0,
                          ),
                        ]
                      : widget.isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.1),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                                spreadRadius: 0,
                              ),
                            ]
                          : null,
                ),
                child: Row(
                  children: [
                    // Иконка для выбранного элемента с анимацией
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, animation) {
                        return ScaleTransition(
                          scale: animation,
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                      child: widget.isSelected
                          ? Container(
                              key: const ValueKey('selected'),
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    AppColors.primary.withOpacity(0.8),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.4),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                            )
                          : Container(
                              key: const ValueKey('unselected'),
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.divider.withOpacity(0.6),
                                  width: 1.5,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(width: AppPadding.small),
                    Expanded(
                      child: Text(
                        widget.text,
                        style: widget.isSelected
                            ? AppTextStyles.body.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.2,
                              )
                            : AppTextStyles.body.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w400,
                              ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
