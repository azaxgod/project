# Структура модуля Аналитики (EPIC 6)

## ✅ Созданная структура:

### 1. Сервис аналитики (`lib/services/analytics/`)

#### `collection/analytics_collection.dart`
- `AnalyticsCollection` - класс для работы с API аналитики
- Методы для всех endpoints:
  - `getDashboard()` - GET /analytics/dashboard
  - `getTripsAnalytics()` - GET /analytics/trips
  - `getTripDetail()` - GET /analytics/trips/{id}
  - `getViolationsAnalytics()` - GET /analytics/violations
  - `getPerformanceAnalytics()` - GET /analytics/performance
  - `getContractsAnalytics()` - GET /analytics/contracts
  - `getAreasAnalytics()` - GET /analytics/areas
  - `getDriversAnalytics()` - GET /analytics/drivers
  - `getVehiclesAnalytics()` - GET /analytics/vehicles
  - `getTechnicalAnalytics()` - GET /analytics/technical

#### `model/analytics_response.dart`
- Все модели ответов API:
  - `DashboardResponse`, `DashboardData`, `DashboardStats`, и т.д.
  - `TripsAnalyticsResponse`, `TripsAnalyticsData`
  - `ViolationsAnalyticsResponse`, `ViolationsAnalyticsData`
  - `PerformanceAnalyticsResponse`, `PerformanceAnalyticsData`
  - `ContractsAnalyticsResponse`, `ContractsAnalyticsData`
  - `AreasAnalyticsResponse`, `AreasAnalyticsData`
  - `DriversAnalyticsResponse`, `DriversAnalyticsData`
  - `VehiclesAnalyticsResponse`, `VehiclesAnalyticsData`
  - `TechnicalAnalyticsResponse`, `TechnicalAnalyticsData`
  - `TripDetailResponse`, `TripDetailData`

#### `services.dart`
- `AnalyticsServices` - обертка для коллекций

#### `module.dart`
- `analyticsDioProvider` - Dio с настройкой для analytics-service
- `analyticsCollectionProvider` - Provider для AnalyticsCollection
- `analyticsServicesProvider` - Provider для AnalyticsServices

### 2. Модуль аналитики (`lib/modules/analytics/`)

#### `src/repository/`
- `i_analytics_repository.dart` - интерфейс репозитория
- `analytics_repository_impl.dart` - реализация репозитория

#### `src/controller/`
- `analytics_state.dart` - состояние аналитики (AnalyticsState)
- `analytics_controller.dart` - контроллер (AnalyticsController)
- `analytics_providers.dart` - Riverpod providers

#### `src/ui/screen/`
- `analytics_dashboard_page.dart` - Главный дашборд
- `analytics_trips_page.dart` - Аналитика рейсов
- `analytics_violations_page.dart` - Аналитика нарушений
- `analytics_performance_page.dart` - Аналитика эффективности
- `analytics_contracts_page.dart` - Аналитика контрактов
- `analytics_areas_page.dart` - Аналитика участков
- `analytics_drivers_page.dart` - Аналитика водителей
- `analytics_vehicles_page.dart` - Аналитика транспорта
- `analytics_technical_page.dart` - Техническая аналитика (TOO)

### 3. Интеграция

#### `lib/core/di.dart`
- Добавлен `iAnalyticsRepositoryProvider`

#### `lib/core/routes/app_routes.dart`
- Добавлены роуты:
  - `/analytics` - главный дашборд
  - `/analytics/trips` - аналитика рейсов
  - `/analytics/violations` - аналитика нарушений
  - `/analytics/performance` - аналитика эффективности
  - `/analytics/contracts` - аналитика контрактов
  - `/analytics/areas` - аналитика участков
  - `/analytics/drivers` - аналитика водителей
  - `/analytics/vehicles` - аналитика транспорта
  - `/analytics/technical` - техническая аналитика

## 📋 Что нужно настроить:

### 1. URL сервиса аналитики

В `lib/services/analytics/module.dart` указан URL:
```dart
baseUrl: 'https://snowops-analytics-service.onrender.com', // TODO: заменить на реальный URL
```

**Замените на реальный URL вашего analytics-service!**

### 2. Доработка UI

Сейчас созданы базовые страницы. Нужно доработать:
- Графики и диаграммы (используйте `fl_chart` или `syncfusion_flutter_charts`)
- Карты (используйте `flutter_map` как в других модулях)
- Таблицы с данными
- Фильтры и поиск
- Экспорт в Excel/CSV/PDF

### 3. RLS (Row Level Security)

RLS реализован на бэкенде через JWT токены. Flutter автоматически передает токен в заголовке `Authorization: Bearer <token>`.

## 🎯 Использование:

### Загрузка дашборда:

```dart
final controller = ref.read(analyticsControllerProvider.notifier);
await controller.loadDashboard(
  from: DateTime.now().subtract(const Duration(days: 7)),
  to: DateTime.now(),
);
```

### Просмотр данных:

```dart
final state = ref.watch(analyticsControllerProvider);
state.dashboard?.when(
  data: (data) => // показать данные
  loading: () => // показать загрузку
  error: (error, stack) => // показать ошибку
);
```

## 📁 Структура файлов:

```
lib/
├── services/
│   └── analytics/
│       ├── collection/
│       │   └── analytics_collection.dart
│       ├── model/
│       │   └── analytics_response.dart
│       ├── module.dart
│       └── services.dart
└── modules/
    └── analytics/
        └── src/
            ├── controller/
            │   ├── analytics_controller.dart
            │   ├── analytics_providers.dart
            │   └── analytics_state.dart
            ├── repository/
            │   ├── analytics_repository_impl.dart
            │   └── i_analytics_repository.dart
            └── ui/
                └── screen/
                    ├── analytics_dashboard_page.dart
                    ├── analytics_trips_page.dart
                    ├── analytics_violations_page.dart
                    ├── analytics_performance_page.dart
                    ├── analytics_contracts_page.dart
                    ├── analytics_areas_page.dart
                    ├── analytics_drivers_page.dart
                    ├── analytics_vehicles_page.dart
                    └── analytics_technical_page.dart
```

## ✅ Готово к использованию!

Модуль аналитики создан и интегрирован в проект. Осталось:
1. Указать правильный URL analytics-service
2. Доработать UI компоненты (графики, карты, таблицы)
3. Добавить навигацию в меню приложения





