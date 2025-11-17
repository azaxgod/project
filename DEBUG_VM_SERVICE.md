# Диагностика проблемы VM Service на iOS

## Проблема
Приложение собирается, но Flutter не может подключиться к VM Service. Это обычно означает, что приложение крашится при запуске.

## Решение: Запустите через Xcode для диагностики

### Шаг 1: Откройте проект в Xcode
```bash
open ios/Runner.xcworkspace
```

### Шаг 2: Запустите через Xcode
1. В Xcode выберите симулятор **iPhone 16 Plus**
2. Нажмите **Product → Run** (или Cmd+R)
3. **Смотрите консоль внизу** - там будут видны ошибки

### Шаг 3: Проверьте логи
В консоли Xcode вы увидите:
- ✅ Если приложение запустилось - проблема только в подключении VM Service
- ❌ Если приложение крашится - будет видна точная ошибка

## Возможные причины краша:

### 1. Проблема с Firebase инициализацией
- Проверьте, что `GoogleService-Info.plist` на месте
- Проверьте Bundle ID в файле

### 2. Проблема с зависимостями
```bash
cd ios
export LANG=en_US.UTF-8
pod install
cd ..
```

### 3. Проблема с кодом при запуске
- Проверьте `main.dart` - нет ли ошибок при инициализации
- Проверьте, что все зависимости загружены

## Альтернативные решения:

### 1. Запустите в release режиме:
```bash
flutter run --release
```
Если в release работает, проблема в debug подключении.

### 2. Запустите с указанным портом:
```bash
flutter run --host-vmservice-port 8888
```

### 3. Проверьте логи симулятора:
```bash
xcrun simctl spawn booted log stream --level=error --predicate 'processImagePath contains "Runner"'
```

### 4. Полная очистка и пересборка:
```bash
flutter clean
rm -rf ios/Pods ios/Podfile.lock
flutter pub get
cd ios && export LANG=en_US.UTF-8 && pod install && cd ..
flutter run
```

## Самое важное:

**Запустите через Xcode** - это покажет точную причину проблемы в логах!

