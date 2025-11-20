# Настройка модуля Аналитики

## ✅ Что создано:

### 1. Сервис аналитики
- ✅ `lib/services/analytics/collection/analytics_collection.dart` - работа с API
- ✅ `lib/services/analytics/model/analytics_response.dart` - модели данных
- ✅ `lib/services/analytics/module.dart` - DI провайдеры

### 2. Модуль аналитики
- ✅ `lib/modules/analytics/src/repository/` - репозитории
- ✅ `lib/modules/analytics/src/controller/` - контроллеры и состояние
- ✅ `lib/modules/analytics/src/ui/screen/` - UI страницы

### 3. Интеграция
- ✅ Добавлены провайдеры в `lib/core/di.dart`
- ✅ Добавлены роуты в `lib/core/routes/app_routes.dart`

## ⚙️ Настройка:

### 1. Укажите URL analytics-service

Откройте `lib/services/analytics/module.dart` и замените:

```dart
baseUrl: 'https://snowops-analytics-service.onrender.com', // TODO: заменить на реальный URL
```

На реальный URL вашего analytics-service.

### 2. Добавьте навигацию в меню

Добавьте пункт "Аналитика" в меню приложения (drawer/navbar) с ссылкой на `/analytics`.

## 📊 Доступные endpoints:

Все endpoints требуют `Authorization: Bearer <jwt>` заголовок.

- `GET /analytics/dashboard` - главный дашборд
- `GET /analytics/trips` - аналитика рейсов
- `GET /analytics/trips/{id}` - детали рейса
- `GET /analytics/violations` - аналитика нарушений
- `GET /analytics/performance` - аналитика эффективности
- `GET /analytics/contracts` - аналитика контрактов
- `GET /analytics/areas` - аналитика участков
- `GET /analytics/drivers` - аналитика водителей
- `GET /analytics/vehicles` - аналитика транспорта
- `GET /analytics/technical` - техническая аналитика (TOO)

## 🎯 Использование:

### Пример загрузки дашборда:

```dart
final controller = ref.read(analyticsControllerProvider.notifier);
await controller.loadDashboard(
  from: DateTime.now().subtract(const Duration(days: 7)),
  to: DateTime.now(),
);
```

### Пример отображения данных:

```dart
final state = ref.watch(analyticsControllerProvider);
state.dashboard?.when(
  data: (data) => Text('Активных рейсов: ${data.data.stats.activeTrips}'),
  loading: () => CircularProgressIndicator(),
  error: (error, stack) => Text('Ошибка: $error'),
);
```

## 📝 Следующие шаги:

1. ✅ Указать URL analytics-service
2. ⏳ Доработать UI компоненты (графики, карты, таблицы)
3. ⏳ Добавить навигацию в меню
4. ⏳ Реализовать фильтры и поиск
5. ⏳ Добавить экспорт данных

## 🔗 Связанные файлы:

- `lib/services/analytics/` - сервис для работы с API
- `lib/modules/analytics/` - модуль аналитики
- `lib/core/di.dart` - DI провайдеры
- `lib/core/routes/app_routes.dart` - роуты



