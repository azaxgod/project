# Решение "No such module 'Flutter'" в Xcode

## ⚠️ КРИТИЧЕСКИ ВАЖНО:

### Проблема:
Xcode не может найти модуль Flutter, потому что:
1. Открыт `.xcodeproj` вместо `.xcworkspace`
2. Flutter framework не сгенерирован
3. Xcode не видит пути к Flutter

## ✅ Решение:

### Шаг 1: Закройте Xcode полностью

### Шаг 2: Соберите проект через Flutter (обязательно!)
```bash
cd /Users/admin/Documents/FlutterProjects/akimat_project
flutter build ios --debug --no-codesign --simulator
```

Это сгенерирует Flutter framework, который нужен Xcode.

### Шаг 3: Откройте ПРАВИЛЬНЫЙ файл:
```bash
open ios/Runner.xcworkspace
```

**НЕ используйте:** `ios/Runner.xcodeproj` ❌

### Шаг 4: В Xcode:

1. Подождите, пока проект загрузится (30-60 секунд)
2. В навигаторе слева должны быть видны:
   - ✅ Runner (проект)
   - ✅ Pods (зависимости)
3. **Product → Clean Build Folder** (Shift+Cmd+K)
4. Подождите завершения
5. **Product → Run** (Cmd+R)

## Альтернатива: Используйте Flutter вместо Xcode

**Это проще и надежнее:**

```bash
flutter run
```

Flutter автоматически:
- ✅ Сгенерирует Flutter framework
- ✅ Соберет проект
- ✅ Запустит на симуляторе
- ✅ Подключится к VM Service

## Проверка:

После открытия `Runner.xcworkspace`:
- ✅ Должен быть виден проект Runner
- ✅ Должны быть видны Pods в навигаторе
- ✅ Не должно быть ошибок "No such module"

## Если ошибка сохраняется:

1. **Убедитесь, что используете .xcworkspace:**
   ```bash
   # Проверьте, что файл существует
   ls -la ios/Runner.xcworkspace
   ```

2. **Пересоберите через Flutter:**
   ```bash
   flutter clean
   flutter pub get
   flutter build ios --debug --no-codesign --simulator
   ```

3. **Откройте Xcode снова:**
   ```bash
   open ios/Runner.xcworkspace
   ```

## Рекомендация:

**Просто используйте `flutter run` - это проще и надежнее!**

Xcode нужен только для:
- Настройки подписи кода
- Настройки capabilities
- Отладки нативных iOS проблем

Для обычной разработки используйте `flutter run`.

