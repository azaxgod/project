# Примеры использования глобальной системы уведомлений

## Базовое использование

### 1. Показать успешное уведомление
```dart
context.showSuccessNotification('Операция выполнена успешно');
```

### 2. Показать ошибку
```dart
context.showErrorNotification('Произошла ошибка');
```

### 3. Показать ошибку из исключения (автоматический парсинг)
```dart
try {
  await someOperation();
} catch (e) {
  context.showErrorNotificationFromException(e);
}
```

### 4. Показать уведомление с задержкой перед перезагрузкой
```dart
await context.showSuccessWithReload(
  'Данные успешно сохранены',
  () {
    // Перезагрузка данных
    ref.read(controllerProvider.notifier).loadData();
  },
);
```

### 5. Использование через NotificationHelper (без контекста)
```dart
NotificationHelper.showSuccess('Успешно!');
NotificationHelper.showErrorFromException(error);
```

## Примеры в реальном коде

### Обновление пользователя
```dart
try {
  await controller.updateUser(user.id, ...);
  
  if (context.mounted) {
    Navigator.of(context).pop();
    context.showSuccessNotification('Пользователь успешно обновлен');
  }
} catch (e) {
  context.showErrorNotificationFromException(e);
}
```

### Создание с перезагрузкой
```dart
try {
  await controller.createItem(...);
  
  if (context.mounted) {
    Navigator.of(context).pop();
    await context.showSuccessWithReload(
      'Элемент успешно создан',
      () => ref.read(controllerProvider.notifier).refresh(),
    );
  }
} catch (e) {
  context.showErrorNotificationFromException(e);
}
```

### Обработка ошибок валидации
```dart
if (formKey.currentState!.validate()) {
  try {
    await saveData();
    context.showSuccessNotification('Данные сохранены');
  } catch (e) {
    context.showErrorNotificationFromException(e);
  }
} else {
  context.showWarningNotification('Проверьте правильность заполнения полей');
}
```



