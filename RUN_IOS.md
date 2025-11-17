# Запуск приложения на iOS после исправления архитектуры

## Шаги для запуска:

### 1. Убедитесь, что симулятор запущен:
```bash
# Проверьте, что симулятор запущен
xcrun simctl list devices | grep "Booted"

# Если нет, запустите:
open -a Simulator
```

### 2. Запустите приложение:
```bash
cd /Users/admin/Documents/FlutterProjects/akimat_project
flutter run
```

### 3. Если не работает, попробуйте через Xcode:
```bash
open ios/Runner.xcworkspace
```

В Xcode:
1. Выберите симулятор **iPhone 16 Plus** в верхней панели
2. Нажмите **Product → Run** (или Cmd+R)
3. Смотрите логи в консоли Xcode

### 4. Если все еще не работает, проверьте архитектуру в Xcode:
1. Откройте `ios/Runner.xcworkspace`
2. Выберите проект **Runner** в навигаторе
3. Выберите target **Runner**
4. Перейдите на вкладку **Build Settings**
5. Найдите **Architectures**
6. Убедитесь, что:
   - **Architectures**: `arm64` (для Apple Silicon Mac)
   - **Build Active Architecture Only**: `Yes` (для Debug)

### 5. Если проблема с архитектурой, добавьте в Build Settings:
- **Excluded Architectures**: (пусто для Debug, добавьте `arm64` только если нужно исключить)
- **Valid Architectures**: `arm64`

## Проверка:

После запуска приложение должно открыться на симуляторе без ошибки "не поддерживается этим компьютером Mac".

