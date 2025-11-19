# Модуль "Нарушения и обжалования"

## ✅ Структура модуля

### Services (API клиент)
- `lib/services/violations/module.dart` - Riverpod providers для Dio и Collection
- `lib/services/violations/services.dart` - Facade для ViolationsCollection
- `lib/services/violations/collection/violations_collection.dart` - API клиент для violations-service
- `lib/services/violations/model/violation.dart` - Модели Violation, ViolationType, ViolationStatus, etc.
- `lib/services/violations/model/appeal.dart` - Модели Appeal, AppealStatus, AppealAttachment, AppealComment
- `lib/services/violations/model/violation_response.dart` - DTO для API ответов

### Module (Repository, Controller, UI)
- `lib/modules/violations/src/repository/i_violations_repository.dart` - Интерфейс репозитория
- `lib/modules/violations/src/repository/violations_repository_impl.dart` - Реализация репозитория
- `lib/modules/violations/src/controller/violations_state.dart` - State для Riverpod
- `lib/modules/violations/src/controller/violations_controller.dart` - StateNotifier контроллер
- `lib/modules/violations/src/controller/violations_providers.dart` - Riverpod providers
- `lib/modules/violations/src/ui/screen/violations_page.dart` - Основная UI страница

## ✅ Интеграция

### DI (Dependency Injection)
- Добавлен `iViolationsRepositoryProvider` в `lib/core/di.dart`
- Использует `violationsCollectionProvider` из `lib/services/violations/module.dart`

### Роуты
- Добавлен роут `/violations` в `lib/core/routes/app_routes.dart`
- Роут доступен для всех авторизованных пользователей

### Навигация
- **Веб**: Добавлена кнопка "Нарушения" в `lib/core/navbar/navbar_widgets_provider.dart`
- **Мобилка**: Добавлен пункт меню в `lib/core/navbar/drawer_mobile.dart`
- Иконка: `Icons.gavel`

### Локализация
- Ключ `violations` уже существует в локализации (ru: "Нарушения", en: "Violations", kk: "Бұзушылықтар")

## 📋 API Endpoints

Все запросы требуют `Authorization: Bearer <jwt>` токен.

### Violations
- `GET /violations` - Список нарушений (с фильтрами)
- `GET /violations/:id` - Детали нарушения
- `POST /violations` - Создать нарушение (KGU/Akimat)
- `PUT /violations/:id/status` - Изменить статус нарушения

### Appeals
- `GET /appeals` - Список апелляций (с фильтрами)
- `GET /appeals/:id` - Детали апелляции
- `POST /violations/:id/appeals` - Создать апелляцию (Driver/Contractor)
- `POST /appeals/:id/comments` - Добавить комментарий
- `POST /appeals/:id/actions` - Выполнить действие (KGU/Akimat)

## 🔧 Использование

### В UI компонентах

```dart
// Получить контроллер
final controller = ref.read(violationsControllerProvider.notifier);

// Загрузить список нарушений
await controller.loadViolations(
  status: ViolationStatus.open,
  dateFrom: DateTime.now().subtract(Duration(days: 7)),
);

// Получить состояние
final state = ref.watch(violationsControllerProvider);
state.violations?.when(
  data: (data) => /* показать данные */,
  loading: () => CircularProgressIndicator(),
  error: (error, stack) => /* показать ошибку */,
);
```

## 📝 Следующие шаги

1. ✅ Базовая структура создана
2. ⏳ Детальная страница нарушения (с апелляциями)
3. ⏳ Форма создания апелляции
4. ⏳ Карточка апелляции с комментариями и вложениями
5. ⏳ Фильтры и поиск
6. ⏳ Роль-специфичные UI (Driver, Contractor, KGU, Akimat, TOO)


