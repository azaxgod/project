# Исправление ошибки подключения к VM Service на iOS

## Проблема
Приложение собирается успешно, но Flutter не может подключиться к VM Service для отладки.

## Быстрые решения (попробуйте по порядку):

### 1. Запустите с указанным портом:
```bash
flutter run --host-vmservice-port 8888
```

### 2. Запустите через Xcode (для диагностики):
```bash
open ios/Runner.xcworkspace
```
В Xcode:
- Выберите симулятор iPhone 16 Plus
- Product → Run (Cmd+R)
- Смотрите логи в консоли Xcode - там будет видна причина краша

### 3. Проверьте логи симулятора:
В отдельном терминале:
```bash
xcrun simctl spawn booted log stream --level=error --predicate 'processImagePath contains "Runner"'
```
Затем в другом терминале запустите `flutter run` и смотрите ошибки.

### 4. Запустите в release режиме (чтобы проверить, что приложение работает):
```bash
flutter run --release
```
Если в release режиме работает, проблема в debug подключении.

### 5. Удалите приложение и пересоберите:
```bash
# Удалите приложение
xcrun simctl uninstall booted com.example.akimatProject

# Очистите проект
flutter clean
flutter pub get

# Пересоберите
flutter run
```

### 6. Перезапустите симулятор:
```bash
killall Simulator
sleep 3
open -a Simulator
# Подождите 10-15 секунд пока симулятор загрузится
flutter run
```

### 7. Используйте другой симулятор:
```bash
# Посмотрите доступные симуляторы
flutter devices

# Запустите на другом
flutter run -d <device-id>
```

## Диагностика через Xcode (рекомендуется):

1. Откройте проект:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. В Xcode:
   - Выберите симулятор **iPhone 16 Plus**
   - Нажмите **Product → Run** (Cmd+R)
   - Смотрите логи в консоли внизу

3. Если приложение крашится, в логах будет видна причина:
   - Ошибки Firebase
   - Проблемы с Bundle ID
   - Другие ошибки

## Частые причины:

1. **Приложение крашится при запуске** - проверьте логи в Xcode
2. **Проблема с Firebase** - проверьте GoogleService-Info.plist
3. **Проблема с Bundle ID** - убедитесь, что Bundle ID правильный
4. **Проблема с портом** - используйте `--host-vmservice-port`
5. **Проблема с симулятором** - перезапустите симулятор

## Если ничего не помогает:

1. **Перезагрузите Mac** (иногда помогает)
2. **Обновите Flutter:**
   ```bash
   flutter upgrade
   ```
3. **Попробуйте на реальном устройстве:**
   - Подключите iPhone
   - Запустите `flutter run`

## Проверка после исправления Bundle ID:

Если вы только что исправили Bundle ID в Firebase:
1. Убедитесь, что новый `GoogleService-Info.plist` на месте
2. Проверьте Bundle ID в файле:
   ```bash
   grep -A 1 "BUNDLE_ID" ios/Runner/GoogleService-Info.plist
   ```
   Должно быть: `com.example.akimatProject` (с 't'!)
3. Очистите и пересоберите:
   ```bash
   flutter clean
   flutter pub get
   cd ios && pod install && cd ..
   flutter run
   ```

