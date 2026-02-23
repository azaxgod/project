# Анализ проблемы: Маршруты техники для KGU_ZKH_ADMIN

## 📋 Вопрос

Пользователь с ролью `KGU_ZKH_ADMIN` может создавать полигоны и участки, но не видит маршруты машин и водителей. Должны ли они отображаться и почему не отображаются?

---

## ✅ Что реализовано правильно

### 1. Права на создание полигонов и участков

**Файл:** `lib/modules/dashboard/src/ui/screen/monitoring/widgets/monitoring_sidebar.dart`

```dart
bool _canEdit() {
  return state.role == UserRole.akimatAdmin ||
      state.role == UserRole.kguZkhAdmin ||  // ✅ KGU_ZKH_ADMIN может создавать
      state.role == UserRole.tooAdmin;
}
```

**Вывод:** ✅ KGU_ZKH_ADMIN **может** создавать полигоны и участки - это правильно.

---

### 2. Видимость техники

**Файл:** `lib/modules/dashboard/src/controller/monitoring_controller.dart:284-303`

```dart
List<VehicleMonitoring> _filterVehiclesByRole(List<VehicleMonitoring> vehicles) {
  switch (state.role) {
    case UserRole.akimatAdmin:
    case UserRole.kguZkhAdmin:
      return vehicles; // ✅ Видят всю технику
    // ...
  }
}
```

**Вывод:** ✅ KGU_ZKH_ADMIN **видит всю технику** - это правильно.

---

### 3. Загрузка треков техники

**Файл:** `lib/modules/dashboard/src/controller/monitoring_controller.dart:366-385`

```dart
Future<void> selectVehicle(String? vehicleId) async {
  state = state.copyWith(selectedVehicleId: vehicleId);
  
  if (vehicleId == null) {
    state = state.copyWith(selectedVehicleTrack: null);
    return;
  }

  try {
    final track = await _operationsRepository.getVehicleTrack(
      vehicleId,
      from: DateTime.now().subtract(const Duration(hours: 1)), // ⚠️ За последний час
      to: DateTime.now(),
    );
    state = state.copyWith(selectedVehicleTrack: track);
  } catch (e) {
    // Игнорируем ошибки
  }
}
```

**Вывод:** ✅ Трек **загружается** при клике на технику.

---

### 4. Отображение треков на карте

**Файл:** `lib/modules/dashboard/src/ui/screen/monitoring/widgets/monitoring_map_widget.dart:157-168`

```dart
// Трек выбранной техники
if (widget.selectedVehicleTrack != null && widget.selectedVehicleTrack!.points.isNotEmpty)
  PolylineLayer(
    polylines: [
      Polyline(
        points: widget.selectedVehicleTrack!.points
            .map((p) => LatLng(p.lat, p.lon))
            .toList(),
        strokeWidth: 3,
        color: Colors.red,
      ),
    ],
  ),
```

**Вывод:** ✅ Трек **отображается** на карте, если он загружен.

---

## 🔴 Проблемы и почему треки могут не отображаться

### Проблема 1: Трек загружается только при клике на технику

**Текущее поведение:**
- Трек загружается **только** когда пользователь кликает на маркер техники
- Если пользователь не кликает, трек не загружается

**Решение:**
- Это **правильное поведение** - треки должны загружаться по требованию, чтобы не перегружать систему

---

### Проблема 2: Трек загружается только за последний час

**Код:** `lib/modules/dashboard/src/controller/monitoring_controller.dart:378`

```dart
from: DateTime.now().subtract(const Duration(hours: 1)), // ⚠️ Только последний час
to: DateTime.now(),
```

**Проблема:**
- Если машина не двигалась в последний час, трек будет пустым
- Если нужно увидеть более длинный маршрут, нужно увеличить период

**Решение:**
- Можно добавить выбор периода (1 час, 6 часов, 24 часа) или загружать за весь день

---

### Проблема 3: Ошибки загрузки трека игнорируются

**Код:** `lib/modules/dashboard/src/controller/monitoring_controller.dart:382-384`

```dart
} catch (e) {
  // Игнорируем ошибки ⚠️
}
```

**Проблема:**
- Если API возвращает ошибку, пользователь не узнает об этом
- Трек просто не отобразится без объяснения

**Решение:**
- Добавить логирование ошибок
- Показывать сообщение пользователю, если трек не удалось загрузить

---

### Проблема 4: Нет индикации загрузки трека

**Проблема:**
- Когда пользователь кликает на технику, нет визуальной индикации, что трек загружается
- Пользователь может не понять, что нужно подождать

**Решение:**
- Добавить индикатор загрузки при клике на технику
- Показывать спиннер или сообщение "Загрузка маршрута..."

---

### Проблема 5: Трек может быть пустым

**Проблема:**
- Если `selectedVehicleTrack.points.isEmpty`, трек не отобразится
- Это может быть, если:
  - Машина не двигалась в выбранный период
  - GPS данные не записывались
  - API вернул пустой трек

**Решение:**
- Проверить, что API возвращает данные
- Добавить сообщение "Маршрут за выбранный период отсутствует"

---

## 🔍 Диагностика проблемы

### Шаги для проверки:

1. **Проверить, что техника отображается:**
   - Откройте мониторинг
   - Убедитесь, что видны маркеры техники на карте

2. **Проверить клик на технику:**
   - Кликните на маркер техники
   - Должна появиться панель с информацией о машине справа
   - В консоли должны быть логи загрузки трека

3. **Проверить загрузку трека:**
   - Откройте DevTools → Network
   - Кликните на технику
   - Должен быть запрос: `GET /monitoring/vehicles/{id}/track?from=...&to=...`
   - Проверьте ответ - должен содержать массив точек

4. **Проверить отображение трека:**
   - Если трек загружен, на карте должна появиться красная линия
   - Проверьте, что `selectedVehicleTrack.points.isNotEmpty`

---

## ✅ Рекомендации по исправлению

### 1. Добавить логирование загрузки трека

**Файл:** `lib/modules/dashboard/src/controller/monitoring_controller.dart`

```dart
Future<void> selectVehicle(String? vehicleId) async {
  state = state.copyWith(selectedVehicleId: vehicleId);
  
  if (vehicleId == null) {
    state = state.copyWith(selectedVehicleTrack: null);
    return;
  }

  debugPrint('MonitoringController.selectVehicle: Loading track for vehicle $vehicleId');
  try {
    final track = await _operationsRepository.getVehicleTrack(
      vehicleId,
      from: DateTime.now().subtract(const Duration(hours: 1)),
      to: DateTime.now(),
    );
    debugPrint('MonitoringController.selectVehicle: Track loaded, points: ${track.points.length}');
    state = state.copyWith(selectedVehicleTrack: track);
  } catch (e, stackTrace) {
    debugPrint('MonitoringController.selectVehicle: Error loading track: $e');
    debugPrint('MonitoringController.selectVehicle: Stack: $stackTrace');
    // Показываем ошибку пользователю
    state = state.copyWith(selectedVehicleTrack: null);
  }
}
```

---

### 2. Увеличить период загрузки трека

**Вариант 1:** Загружать за весь день

```dart
final track = await _operationsRepository.getVehicleTrack(
  vehicleId,
  from: DateTime.now().subtract(const Duration(hours: 24)), // Весь день
  to: DateTime.now(),
);
```

**Вариант 2:** Добавить выбор периода

```dart
// В MonitoringState добавить:
final Duration? trackPeriod; // null = 1 час, Duration(hours: 6) = 6 часов, и т.д.

// В selectVehicle:
final period = state.trackPeriod ?? const Duration(hours: 1);
final track = await _operationsRepository.getVehicleTrack(
  vehicleId,
  from: DateTime.now().subtract(period),
  to: DateTime.now(),
);
```

---

### 3. Добавить индикатор загрузки

**Файл:** `lib/modules/dashboard/src/controller/monitoring_state.dart`

```dart
final bool isLoadingTrack; // Добавить в состояние

// В selectVehicle:
state = state.copyWith(
  selectedVehicleId: vehicleId,
  isLoadingTrack: true, // Показываем загрузку
);

try {
  final track = await _operationsRepository.getVehicleTrack(...);
  state = state.copyWith(
    selectedVehicleTrack: track,
    isLoadingTrack: false,
  );
} catch (e) {
  state = state.copyWith(
    selectedVehicleTrack: null,
    isLoadingTrack: false,
  );
}
```

**В UI:**

```dart
if (state.isLoadingTrack)
  Center(child: CircularProgressIndicator())
else if (state.selectedVehicleTrack == null)
  Text('Маршрут не загружен')
else if (state.selectedVehicleTrack!.points.isEmpty)
  Text('Маршрут за выбранный период отсутствует')
```

---

### 4. Проверить API endpoint

**Файл:** `lib/services/operations/collection/operations_collection.dart:626-651`

Убедитесь, что:
- Endpoint правильный: `/monitoring/vehicles/:id/track`
- Формат дат правильный: RFC 3339
- Ответ содержит массив точек в формате `{lat, lon}`

---

## 📊 Выводы

### ✅ KGU_ZKH_ADMIN ДОЛЖЕН видеть маршруты техники

**Причины:**
1. KGU_ZKH_ADMIN видит всю технику (строка 287 в monitoring_controller.dart)
2. Треки загружаются при клике на технику (строка 366-385)
3. Треки отображаются на карте (строка 157-168 в monitoring_map_widget.dart)

### ⚠️ Почему треки могут не отображаться:

1. **Пользователь не кликает на технику** - трек загружается только по клику
2. **Трек пустой** - машина не двигалась в последний час
3. **Ошибка API** - запрос к `/monitoring/vehicles/:id/track` возвращает ошибку
4. **Нет GPS данных** - бэкенд не записывает треки техники
5. **Период слишком короткий** - загружается только последний час

### 🔧 Рекомендации:

1. Добавить логирование для диагностики
2. Увеличить период загрузки трека (весь день вместо 1 часа)
3. Добавить индикатор загрузки
4. Показывать сообщения об ошибках
5. Проверить, что бэкенд возвращает данные треков

---

## 🔗 Связанные файлы

- `lib/modules/dashboard/src/controller/monitoring_controller.dart` - загрузка треков
- `lib/modules/dashboard/src/ui/screen/monitoring/widgets/monitoring_map_widget.dart` - отображение треков
- `lib/modules/dashboard/src/ui/screen/monitoring/widgets/monitoring_sidebar.dart` - права на создание
- `lib/services/operations/collection/operations_collection.dart` - API запросы
- `lib/modules/dashboard/src/repository/operations_repository_impl.dart` - репозиторий






