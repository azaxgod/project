# Интеграция с Snowops Analytics Service

## 📋 Обзор

Flutter приложение уже интегрировано с **Snowops Analytics Service** (Go-сервис, реализующий EPIC 6). Все API методы реализованы, модели данных готовы. Осталось только доработать UI компоненты.

## 🔌 Текущая интеграция

### Архитектура

```
Flutter App
    ↓
AnalyticsController (StateNotifier)
    ↓
IAnalyticsRepository (интерфейс)
    ↓
AnalyticsRepositoryImpl (реализация)
    ↓
AnalyticsCollection (HTTP клиент)
    ↓
Dio (с JWT авторизацией)
    ↓
Snowops Analytics Service (Go)
```

### Файлы интеграции

- **`lib/services/analytics/collection/analytics_collection.dart`** - HTTP клиент для всех endpoints
- **`lib/services/analytics/model/analytics_response.dart`** - Модели данных API
- **`lib/modules/analytics/src/repository/analytics_repository_impl.dart`** - Реализация репозитория
- **`lib/modules/analytics/src/controller/analytics_controller.dart`** - State management

### Реализованные endpoints

✅ Все endpoints из документации реализованы:

- `GET /analytics/dashboard` - Дашборд
- `GET /analytics/trips` - Аналитика рейсов
- `GET /analytics/trips/{id}` - Детали рейса
- `GET /analytics/violations` - Аналитика нарушений
- `GET /analytics/performance` - Эффективность
- `GET /analytics/contracts` - Контракты
- `GET /analytics/areas` - Участки
- `GET /analytics/drivers` - Водители
- `GET /analytics/vehicles` - Транспорт
- `GET /analytics/technical` - Техническая аналитика (TOO)

## ⚙️ Конфигурация

### Текущая настройка

В `lib/core/di.dart` используется единый `Dio` instance:

```dart
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://snowops-auth-service.onrender.com',
      // ...
    ),
  );
  // JWT авторизация добавляется через interceptor
});
```

### Настройка для Analytics Service

**Важно:** Analytics Service должен быть доступен по тому же base URL или через прокси.

#### Вариант 1: Отдельный baseUrl для Analytics

Если Analytics Service работает на отдельном порту/домене, нужно создать отдельный Dio instance:

```dart
// lib/services/analytics/module.dart
final analyticsDioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'http://localhost:7085', // или ваш analytics service URL
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // Добавляем JWT interceptor
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await TokenStorage.getAccessToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ),
  );

  return dio;
});
```

Затем обновить `AnalyticsCollection`:

```dart
// lib/services/analytics/collection/analytics_collection.dart
class AnalyticsCollection {
  final Dio dio; // Использует analyticsDioProvider
  
  AnalyticsCollection({required this.dio});
  // ...
}
```

#### Вариант 2: Единый baseUrl с роутингом

Если все сервисы доступны через один домен (например, через API Gateway), текущая конфигурация подойдет.

### Переменные окружения

Рекомендуется использовать переменные окружения для конфигурации:

```dart
// lib/core/config.dart
class AppConfig {
  static const String analyticsBaseUrl = 
    String.fromEnvironment('ANALYTICS_BASE_URL', 
      defaultValue: 'http://localhost:7085');
}
```

## 🔐 Авторизация

### JWT токены

Analytics Service требует JWT токен в заголовке:

```
Authorization: Bearer <jwt>
```

Токен автоматически добавляется через `InterceptorsWrapper` в `lib/core/di.dart`:

```dart
dio.interceptors.add(
  InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await TokenStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
  ),
);
```

### RLS (Row Level Security)

Analytics Service автоматически применяет RLS на основе JWT токена:

- **AKIMAT_ADMIN** - видит все данные города
- **KGU_ZKH_ADMIN** - видит данные своих подрядчиков
- **CONTRACTOR_ADMIN** - видит только свои данные
- **TOO_ADMIN** - видит техническую телеметрию
- **DRIVER** - доступ запрещен (403)

Flutter приложение не должно дополнительно фильтровать данные - это делает бэкенд.

## 📊 Формат данных

### Дата и время

Все даты передаются в формате **RFC 3339** (UTC с Z):

```dart
String _formatDateTime(DateTime dateTime) {
  final utc = dateTime.toUtc();
  return '${utc.year.toString().padLeft(4, '0')}-'
      '${utc.month.toString().padLeft(2, '0')}-'
      '${utc.day.toString().padLeft(2, '0')}T'
      '${utc.hour.toString().padLeft(2, '0')}:'
      '${utc.minute.toString().padLeft(2, '0')}:'
      '${utc.second.toString().padLeft(2, '0')}Z';
}
```

Пример: `2025-01-10T18:55:00Z`

### Query параметры

Все параметры опциональны и передаются как query strings:

```dart
GET /analytics/trips?from=2025-01-01T00:00:00Z&to=2025-01-31T23:59:59Z&group_by=week
```

## 🚀 Быстрый старт

### 1. Запуск Analytics Service

```bash
cd deploy
docker compose up -d

cd ..
APP_ENV=development \
DB_DSN="postgres://postgres:postgres@localhost:5440/analytics_db?sslmode=disable" \
JWT_ACCESS_SECRET="secret-key" \
go run ./cmd/analytics-service
```

Сервис будет доступен на `http://localhost:7085`

### 2. Настройка Flutter приложения

Если Analytics Service на отдельном порту, обновите `lib/services/analytics/module.dart`:

```dart
final analyticsDioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'http://localhost:7085', // или ваш URL
      // ...
    ),
  );
  // Добавить JWT interceptor
  return dio;
});
```

### 3. Тестирование

Откройте приложение и перейдите в раздел "Аналитика". Дашборд должен загрузить данные.

## 📝 Примеры использования

### Загрузка дашборда

```dart
final controller = ref.read(analyticsControllerProvider.notifier);
await controller.loadDashboard(
  from: DateTime.now().subtract(Duration(days: 7)),
  to: DateTime.now(),
);

final state = ref.watch(analyticsControllerProvider);
final dashboard = state.dashboard?.value;
```

### Загрузка аналитики рейсов

```dart
await controller.loadTripsAnalytics(
  from: DateTime.now().subtract(Duration(days: 30)),
  to: DateTime.now(),
  groupBy: 'week',
  contractorId: 'contractor-id', // опционально
);
```

### Загрузка деталей рейса

```dart
await controller.loadTripDetail('trip-id');
final tripDetail = state.tripDetail?.value;
```

## 🐛 Обработка ошибок

Все ошибки обрабатываются в `AnalyticsCollection._handleError()`:

- **400** - Bad Request
- **401** - Unauthorized (нужно обновить токен)
- **403** - Forbidden (нет доступа для роли)
- **404** - Not Found
- **500+** - Server Error

Пример обработки в UI:

```dart
state.dashboard?.when(
  data: (data) => _buildDashboard(data),
  loading: () => CircularProgressIndicator(),
  error: (error, stack) => ErrorWidget(error),
);
```

## 🔍 Отладка

### Логирование запросов

В `AnalyticsCollection` уже есть debug логи:

```dart
debugPrint('Analytics Dashboard - Request URL: /analytics/dashboard');
debugPrint('Analytics Dashboard - Query params: $queryParams');
debugPrint('Analytics Dashboard - Response status: ${response.statusCode}');
```

### Проверка JWT токена

Убедитесь, что токен передается:

```dart
final token = await TokenStorage.getAccessToken();
print('JWT Token: ${token?.substring(0, 20)}...');
```

### Проверка baseUrl

```dart
print('Base URL: ${dio.options.baseUrl}');
```

## 📚 Дополнительные ресурсы

- [Snowops Analytics Service README](../deploy/README.md) - документация сервиса
- [ANALYTICS_EPIC_IMPLEMENTATION_PLAN.md](./ANALYTICS_EPIC_IMPLEMENTATION_PLAN.md) - план реализации UI
- [EPIC 6 Requirements](./EPIC_6_ANALYTICS.md) - требования к аналитике

## ✅ Чеклист интеграции

- [x] API методы реализованы в `AnalyticsCollection`
- [x] Модели данных определены в `analytics_response.dart`
- [x] Repository реализован
- [x] Controller реализован
- [x] JWT авторизация настроена
- [ ] Base URL настроен для Analytics Service
- [ ] UI компоненты реализованы (см. план)
- [ ] Тестирование на всех ролях
- [ ] Обработка ошибок в UI

## 🎯 Следующие шаги

1. **Настроить baseUrl** для Analytics Service (если отдельный)
2. **Реализовать UI компоненты** согласно `ANALYTICS_EPIC_IMPLEMENTATION_PLAN.md`
3. **Протестировать** все endpoints с реальными данными
4. **Добавить обработку ошибок** в UI
5. **Оптимизировать** загрузку данных (кэширование, пагинация)

