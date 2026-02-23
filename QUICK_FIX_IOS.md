# Быстрое исправление проблемы VM Service на iOS

## Попробуйте эти команды по порядку:

### 1. Перезапустите симулятор и запустите с указанным портом:
```bash
# Закройте симулятор
killall Simulator

# Подождите 2 секунды и откройте заново
sleep 2
open -a Simulator

# Подождите пока симулятор загрузится, затем запустите:
flutter run --host-vmservice-port 8888
```

### 2. Если не помогло, попробуйте запустить через Xcode:
```bash
# Откройте проект в Xcode
open ios/Runner.xcworkspace

# В Xcode:
# 1. Выберите симулятор iPhone 16 Plus
# 2. Product → Run (или Cmd+R)
# 3. Смотрите логи в консоли Xcode
```

### 3. Удалите приложение с симулятора и запустите заново:
```bash
# Удалите приложение
xcrun simctl uninstall booted com.example.akimatProject

# Запустите заново
flutter run
```

### 4. Запустите в release режиме (чтобы проверить, что приложение работает):
```bash
flutter run --release
```

### 5. Если приложение запускается, но не подключается VM Service:
```bash
# Попробуйте запустить с verbose режимом
flutter run -v
```

## Проверьте логи симулятора:

```bash
# В отдельном терминале запустите:
xcrun simctl spawn booted log stream --level=debug --predicate 'processImagePath contains "Runner"'
```

Затем в другом терминале запустите `flutter run` и смотрите логи.

## Если ничего не помогает:

1. **Перезагрузите Mac** (иногда помогает)
2. **Обновите Xcode Command Line Tools:**
   ```bash
   sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
   sudo xcodebuild -runFirstLaunch
   ```
3. **Попробуйте другой симулятор:**
   ```bash
   flutter devices
   flutter run -d <другой-device-id>
   ```

