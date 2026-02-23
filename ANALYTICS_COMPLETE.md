# ✅ Модуль Аналитики создан и интегрирован

## 📁 Структура:

```
lib/
├── services/analytics/          # Сервис для работы с API
│   ├── collection/
│   │   └── analytics_collection.dart    # API методы
│   ├── model/
│   │   └── analytics_response.dart       # Модели данных
│   ├── module.dart                       # DI провайдеры
│   └── services.dart                     # Обертка сервисов
│
└── modules/analytics/            # Модуль аналитики
    └── src/
        ├── repository/
        │   ├── i_analytics_repository.dart        # Интерфейс
        │   └── analytics_repository_impl.dart     # Реализация
        ├── controller/
        │   ├── analytics_state.dart                # Состояние
        │   ├── analytics_controller.dart          # Контроллер
        │   └── analytics_providers.dart           # Providers
        └── ui/screen/
            ├── analytics_dashboard_page.dart        # Главный дашборд
            ├── analytics_trips_page.dart           # Рейсы
            ├── analytics_violations_page.dart       # Нарушения
            ├── analytics_performance_page.dart      # Эффективность
            ├── analytics_contracts_page.dart       # Контракты
            ├── analytics_areas_page.dart           # Участки
            ├── analytics_drivers_page.dart          # Водители
            ├── analytics_vehicles_page.dart         # Транспорт
            └── analytics_technical_page.dart       # Техническая (TOO)
```

## 🔗 Интеграция:

### 1. DI (`lib/core/di.dart`)
- ✅ Добавлен `iAnalyticsRepositoryProvider`

### 2. Роуты (`lib/core/routes/app_routes.dart`)
- ✅ `/analytics` - главный дашборд
- ✅ `/analytics/trips` - аналитика рейсов
- ✅ `/analytics/violations` - аналитика нарушений
- ✅ `/analytics/performance` - аналитика эффективности
- ✅ `/analytics/contracts` - аналитика контрактов
- ✅ `/analytics/areas` - аналитика участков
- ✅ `/analytics/drivers` - аналитика водителей
- ✅ `/analytics/vehicles` - аналитика транспорта
- ✅ `/analytics/technical` - техническая аналитика

## ⚙️ Настройка:

### 1. URL сервиса

В `lib/services/analytics/module.dart` замените:
```dart
baseUrl: 'https://snowops-analytics-service.onrender.com', // TODO: заменить
```

На реальный URL вашего analytics-service.

### 2. Добавьте навигацию

Добавьте пункт "Аналитика" в меню приложения с ссылкой на `/analytics`.

## 📊 API Endpoints:

Все endpoints поддерживают:
- Query параметры: `from`, `to` (RFC 3339 timestamps)
- Фильтры: `contractor_id`, `driver_id`, `violation_type`, `group_by`
- Авторизация: `Authorization: Bearer <jwt>`

## 🎯 Использование:

### Загрузка данных:

```dart
final controller = ref.read(analyticsControllerProvider.notifier);

// Дашборд
await controller.loadDashboard(
  from: DateTime.now().subtract(const Duration(days: 7)),
  to: DateTime.now(),
);

// Рейсы
await controller.loadTripsAnalytics(
  from: from,
  to: to,
  groupBy: 'day', // или 'week', 'month'
);

// Нарушения
await controller.loadViolationsAnalytics(
  from: from,
  to: to,
  violationType: 'ROUTE_VIOLATION',
);
```

### Отображение данных:

```dart
final state = ref.watch(analyticsControllerProvider);

state.dashboard?.when(
  data: (data) {
    // Показать данные
    final stats = data.data.stats;
    return Text('Активных рейсов: ${stats.activeTrips}');
  },
  loading: () => CircularProgressIndicator(),
  error: (error, stack) => Text('Ошибка: $error'),
);
```

## ✅ Готово!

Модуль аналитики полностью интегрирован в проект и готов к использованию.

**Следующие шаги:**
1. Указать URL analytics-service
2. Доработать UI (графики, карты, таблицы)
3. Добавить навигацию в меню








