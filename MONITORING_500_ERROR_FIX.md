# Исправление ошибки 500 при загрузке мониторинга

## Проблема

При заходе на страницу мониторинга возникает ошибка:
```
GET https://snowops-operations-service.onrender.com/cleaning-areas?only_active=true
Status Code: 500 Internal Server Error
Response: {"error": "internal error"}
```

## Причина

Ошибка 500 Internal Server Error указывает на проблему на стороне бэкенда (Operations Service). Возможные причины:
1. Проблема с базой данных (PostgreSQL/PostGIS)
2. Неправильная обработка параметра `only_active` на бэкенде
3. Проблема с JWT авторизацией
4. Временная недоступность сервиса

## Решение

Добавлена **устойчивость к ошибкам** на фронтенде:

### 1. Fallback для загрузки участков

Если запрос с `only_active=true` падает с ошибкой 500:
- Автоматически повторяется запрос **без параметра** `only_active`
- Фильтрация активных участков выполняется **на клиенте**

**Файл:** `lib/modules/dashboard/src/controller/monitoring_controller.dart:123-152`

```dart
List<CleaningArea> areas = [];
try {
  // Пробуем сначала с onlyActive=true
  areas = await _operationsRepository.loadCleaningAreas(
    status: state.statusFilter,
    onlyActive: true,
  );
} catch (e) {
  // Fallback: пробуем без onlyActive
  try {
    areas = await _operationsRepository.loadCleaningAreas(
      status: state.statusFilter,
      onlyActive: null,
    );
    // Фильтруем на клиенте
    if (state.statusFilter == null) {
      areas = areas.where((area) => area.isActive).toList();
    }
  } catch (e2) {
    // Продолжаем с пустым списком
    areas = [];
  }
}
```

### 2. Fallback для загрузки полигонов

Аналогичная логика для полигонов:

**Файл:** `lib/modules/dashboard/src/controller/monitoring_controller.dart:154-173`

### 3. Обработка ошибок загрузки камер

Если не удалось загрузить камеры для полигона:
- Продолжаем с пустым списком камер для этого полигона
- Не ломаем загрузку остальных данных

**Файл:** `lib/modules/dashboard/src/controller/monitoring_controller.dart:175-186`

### 4. Обработка ошибок загрузки техники

Если не удалось загрузить технику:
- Продолжаем с пустым списком техники
- Страница мониторинга все равно открывается

**Файл:** `lib/modules/dashboard/src/controller/monitoring_controller.dart:188-199`

### 5. Улучшенные сообщения об ошибках

Добавлены понятные сообщения для разных типов ошибок:

**Файл:** `lib/modules/dashboard/src/ui/screen/monitoring/monitoring_page.dart:119-140`

- **500 / internal error:** "Ошибка сервера при загрузке данных. Пожалуйста, попробуйте позже или обратитесь к администратору."
- **401 / 403:** "Ошибка авторизации. Пожалуйста, войдите заново."
- **Network errors:** "Ошибка подключения к серверу. Проверьте интернет-соединение."

### 6. Детальное логирование

Добавлено логирование для диагностики 500 ошибок:

**Файл:** `lib/services/operations/collection/operations_collection.dart:114-120`

```dart
// Для 500 ошибок выводим более детальную информацию
if (e.response?.statusCode == 500) {
  final errorData = e.response?.data;
  if (errorData is Map<String, dynamic> && errorData.containsKey('error')) {
    debugPrint('OperationsCollection.getCleaningAreas: Server error: ${errorData['error']}');
  }
}
```

## Результат

Теперь страница мониторинга:
1. ✅ **Не падает** при ошибке 500 на бэкенде
2. ✅ **Автоматически пытается** загрузить данные без проблемного параметра
3. ✅ **Показывает понятные сообщения** об ошибках
4. ✅ **Продолжает работу** даже если часть данных не загрузилась

## Рекомендации для бэкенда

Для полного решения проблемы нужно исправить бэкенд:

1. **Проверить логи** Operations Service на Render
2. **Проверить обработку параметра** `only_active` в Go коде
3. **Проверить подключение к БД** (PostgreSQL/PostGIS)
4. **Проверить JWT авторизацию**

Возможные проблемы в Go коде:
- Неправильный парсинг булевого параметра из query string
- Проблема с SQL запросом при фильтрации по `is_active`
- Отсутствие обработки ошибок БД

## Тестирование

После исправлений:
1. Страница мониторинга должна открываться даже при ошибке 500
2. Участки и полигоны должны загружаться (с фильтрацией на клиенте, если нужно)
3. Пользователь видит понятное сообщение об ошибке, если что-то не загрузилось
4. Кнопка "Повторить" позволяет попробовать загрузить данные снова







