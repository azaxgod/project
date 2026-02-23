# Исправление проблемы "Connecting to the VM Service" на iOS

## Проблема
Flutter не может подключиться к VM Service на iOS симуляторе, приложение может крашиться при запуске.

## Решения (попробуйте по порядку):

### 1. Перезапустите симулятор
```bash
# Закройте все симуляторы
killall Simulator

# Откройте симулятор заново
open -a Simulator
```

### 2. Очистите и пересоберите проект
```bash
flutter clean
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter pub get
```

### 3. Запустите с указанным портом
```bash
flutter run --host-vmservice-port 8888
```

### 4. Запустите в release режиме (для проверки, что приложение работает)
```bash
flutter run --release
```

### 5. Проверьте логи симулятора
```bash
# Откройте Console.app и смотрите логи симулятора
# Или используйте:
xcrun simctl spawn booted log stream --level=debug --predicate 'processImagePath contains "Runner"'
```

### 6. Проверьте, что приложение запускается
- Откройте Xcode
- Выберите симулятор iPhone 16 Plus
- Запустите приложение через Xcode (Product → Run)
- Смотрите логи в консоли Xcode

### 7. Удалите и переустановите приложение на симуляторе
```bash
# Удалите приложение с симулятора
xcrun simctl uninstall booted com.example.akimatProject

# Запустите заново
flutter run
```

### 8. Проверьте настройки сети
- Убедитесь, что нет блокировки портов файрволом
- Проверьте, что localhost доступен

### 9. Используйте другой симулятор
```bash
# Посмотрите доступные симуляторы
flutter devices

# Запустите на другом симуляторе
flutter run -d <device-id>
```

### 10. Обновите Flutter и зависимости
```bash
flutter upgrade
flutter pub upgrade
cd ios && pod update && cd ..
```

## Если ничего не помогает:

1. **Проверьте логи в Xcode:**
   - Откройте Xcode
   - Window → Devices and Simulators
   - Выберите симулятор
   - View Device Logs
   - Найдите ошибки при запуске

2. **Проверьте, нет ли ошибок в коде:**
   - Запустите `flutter analyze`
   - Проверьте, что все зависимости установлены

3. **Попробуйте запустить на реальном устройстве:**
   - Подключите iPhone
   - Запустите `flutter run`

## Частые причины:

- **Приложение крашится при запуске** - проверьте логи
- **Проблемы с портом** - используйте `--host-vmservice-port`
- **Проблемы с симулятором** - перезапустите симулятор
- **Проблемы с зависимостями** - переустановите pods

