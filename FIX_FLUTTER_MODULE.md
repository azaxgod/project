# Исправление ошибки "No such module 'Flutter'" в Xcode

## Проблема
Xcode не может найти модуль Flutter, хотя сборка через `flutter build ios` работает.

## ✅ Решение:

### 1. Закройте Xcode полностью

### 2. Убедитесь, что открываете .xcworkspace, а не .xcodeproj:

```bash
# Правильно:
open ios/Runner.xcworkspace

# НЕПРАВИЛЬНО:
# open ios/Runner.xcodeproj  ❌
```

### 3. В Xcode выполните:

1. **Product → Clean Build Folder** (Shift+Cmd+K)
2. Подождите, пока очистка завершится
3. **File → Close Project** (закройте проект)
4. Откройте снова: `open ios/Runner.xcworkspace`
5. Подождите, пока Xcode загрузит проект (может занять минуту)
6. **Product → Run** (Cmd+R)

### 4. Если ошибка сохраняется:

#### Вариант A: Пересоберите через Flutter
```bash
flutter clean
flutter pub get
cd ios
export LANG=en_US.UTF-8
pod install
cd ..
flutter build ios --debug --no-codesign
```

Затем откройте Xcode:
```bash
open ios/Runner.xcworkspace
```

#### Вариант B: Проверьте настройки проекта в Xcode

1. Откройте `ios/Runner.xcworkspace`
2. Выберите проект **Runner** в навигаторе
3. Выберите target **Runner**
4. Перейдите на вкладку **Build Settings**
5. Найдите **Framework Search Paths**
6. Убедитесь, что там есть:
   ```
   $(inherited)
   ${PODS_CONFIGURATION_BUILD_DIR}
   ```
7. Найдите **Import Paths** (Swift)
8. Убедитесь, что там есть:
   ```
   $(inherited)
   ```

### 5. Альтернатива: Используйте Flutter для запуска

Если Xcode не работает, просто используйте Flutter:

```bash
flutter run
```

Flutter автоматически соберет проект и запустит на симуляторе.

## Важно:

- ✅ **Всегда используйте `.xcworkspace`**, а не `.xcodeproj`
- ✅ **Сначала запустите `flutter pub get`** перед открытием Xcode
- ✅ **Если сомневаетесь, используйте `flutter run`** вместо Xcode

## Проверка:

После открытия `Runner.xcworkspace`:
- ✅ Должен быть виден проект Runner
- ✅ Должны быть видны Pods в навигаторе
- ✅ Не должно быть ошибок "No such module"

## Если ничего не помогает:

Просто используйте Flutter для запуска - это проще и надежнее:

```bash
flutter run
```

Flutter автоматически:
- Соберет проект
- Установит зависимости
- Запустит на симуляторе
- Подключится к VM Service

