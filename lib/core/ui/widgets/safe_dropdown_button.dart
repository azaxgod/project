import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Безопасный DropdownButtonFormField, который правильно обрабатывает
/// асинхронную загрузку данных с бэкенда и предотвращает ошибки валидации
class SafeDropdownButtonFormField<T> extends StatelessWidget {
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

  /// Проверяет, что значение существует в списке items
  T? _getValidValue() {
    if (value == null) return null;
    
    // Проверяем, что значение есть в списке items
    final matchingItems = items.where((item) => item.value == value).toList();
    
    // Должен быть ровно один элемент с таким значением
    if (matchingItems.length == 1) {
      return value;
    }
    
    // Если 0 или больше 1 элемента - значение невалидно
    return null;
  }

  /// Удаляет дубликаты из items, оставляя только первое вхождение
  List<DropdownMenuItem<T>> _removeDuplicates(List<DropdownMenuItem<T>> items) {
    final seen = <T>{};
    final result = <DropdownMenuItem<T>>[];
    
    for (final item in items) {
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
  Widget build(BuildContext context) {
    // Если items пустой, показываем disabled TextFormField
    if (items.isEmpty) {
      final localValidator = validator;
      return TextFormField(
        enabled: false,
        decoration: decoration?.copyWith(
          hintText: decoration?.hintText ?? 'Нет данных',
        ),
        validator: localValidator != null
            ? (value) => localValidator(value as T?)
            : null,
      );
    }

    // Удаляем дубликаты значений
    final uniqueItems = _removeDuplicates(items);

    // Убеждаемся, что в items есть элемент с null значением для возможности сброса
    final hasNullItem = uniqueItems.any((item) => item.value == null);
    final safeItems = hasNullItem
        ? uniqueItems
        : [
            DropdownMenuItem<T>(
              value: null,
              child: Text(decoration?.hintText ?? 'Выберите...'),
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

    // Для веба используем PopupMenuButton как более надежную альтернативу
    if (kIsWeb) {
      return _buildWebDropdown(context, finalValue, safeItems);
    }

    return DropdownButtonFormField<T>(
      value: finalValue,
      decoration: decoration,
      items: safeItems,
      onChanged: onChanged,
      validator: validator,
      isExpanded: isExpanded,
      isDense: isDense,
    );
  }

  /// Строит dropdown для веба с использованием PopupMenuButton (более надежный для веба)
  Widget _buildWebDropdown(
    BuildContext context,
    T? finalValue,
    List<DropdownMenuItem<T>> safeItems,
  ) {
    final selectedItem = safeItems.firstWhere(
      (item) => item.value == finalValue,
      orElse: () => safeItems.firstWhere(
        (item) => item.value == null,
        orElse: () => safeItems.first,
      ),
    );

    return FormField<T?>(
      initialValue: finalValue,
      validator: validator,
      builder: (field) {
        return InputDecorator(
          decoration: (decoration ?? const InputDecoration()).copyWith(
            errorText: field.errorText,
            isDense: isDense,
          ),
          isEmpty: finalValue == null,
          child: PopupMenuButton<T?>(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
              children: [
                Expanded(
                  child: selectedItem.child,
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ],
            ),
            onSelected: (value) {
              field.didChange(value);
              onChanged?.call(value);
            },
            itemBuilder: (context) {
              return safeItems.map((item) {
                return PopupMenuItem<T?>(
                  value: item.value,
                  child: item.child,
                );
              }).toList();
            },
          ),
        );
      },
    );
  }
}
