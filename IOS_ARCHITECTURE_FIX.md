# Исправление ошибки "Нельзя открыть программу «Runner»" на macOS

## Проблема
Ошибка "Нельзя открыть программу «Runner», так как она не поддерживается этим компьютером Mac" означает, что приложение было собрано для неправильной архитектуры.

## Решение:

### 1. Полная очистка проекта:
```bash
cd /Users/admin/Documents/FlutterProjects/akimat_project

# Очистка Flutter
flutter clean

# Удаление iOS зависимостей
rm -rf ios/Pods ios/Podfile.lock ios/.symlinks
rm -rf ios/Flutter/Flutter.framework ios/Flutter/Flutter.podspec

# Обновление зависимостей
flutter pub get
```

### 2. Установка pods с правильной кодировкой:
```bash
cd ios
export LANG=en_US.UTF-8
pod install --repo-update
cd ..
```

### 3. Убедитесь, что симулятор правильной архитектуры:
```bash
# Проверьте архитектуру симулятора
xcrun simctl list devices | grep "iPhone 16 Plus"

# Если нужно, создайте новый симулятор для Apple Silicon
xcrun simctl create "iPhone 16 Plus ARM64" "iPhone 16 Plus" "iOS18.5"
```

### 4. Пересоберите проект:
```bash
# Запустите через Flutter
flutter run

# ИЛИ через Xcode (рекомендуется для диагностики)
open ios/Runner.xcworkspace
```

### 5. В Xcode проверьте настройки архитектуры:
1. Откройте `ios/Runner.xcworkspace` в Xcode
2. Выберите проект `Runner` в навигаторе
3. Выберите target `Runner`
4. Перейдите на вкладку **Build Settings**
5. Найдите **Architectures**
6. Убедитесь, что выбрано:
   - **Architectures**: `arm64` (для Apple Silicon)
   - **Valid Architectures**: `arm64`
   - **Build Active Architecture Only**: `Yes` (для Debug)

### 6. Если проблема сохраняется, удалите приложение с симулятора:
```bash
# Удалите приложение
xcrun simctl uninstall booted com.example.akimatProject

# Перезапустите симулятор
killall Simulator
open -a Simulator

# Запустите заново
flutter run
```

### 7. Альтернатива: Используйте другой симулятор
```bash
# Посмотрите доступные симуляторы
flutter devices

# Запустите на другом симуляторе
flutter run -d <device-id>
```

## Проверка архитектуры:

```bash
# Проверьте архитектуру Mac
uname -m
# Должно быть: arm64 (для Apple Silicon) или x86_64 (для Intel)

# Проверьте архитектуру симулятора
xcrun simctl list devices | grep -A 5 "iPhone 16 Plus"
```

## Если ничего не помогает:

1. **Перезагрузите Mac** (иногда помогает)
2. **Обновите Xcode:**
   ```bash
   sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
   ```
3. **Попробуйте запустить на реальном устройстве:**
   - Подключите iPhone
   - Запустите `flutter run`

