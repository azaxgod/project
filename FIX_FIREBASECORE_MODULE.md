# Исправление ошибки "No such module 'FirebaseCore'"

## Проблема
Ошибка "No such module 'FirebaseCore'" означает, что Xcode не может найти модуль Firebase.

## ✅ Что было исправлено:

1. **AppDelegate.swift** - убрана условная компиляция (не нужна для Flutter)
2. **Pods переустановлены** - все зависимости установлены заново

## ⚠️ ВАЖНО: Открывайте .xcworkspace, а не .xcodeproj!

### Правильно:
```bash
open ios/Runner.xcworkspace
```

### Неправильно:
```bash
open ios/Runner.xcodeproj  # ❌ НЕ используйте это!
```

## Что делать дальше:

### 1. Закройте Xcode (если открыт)

### 2. Откройте правильный файл:
```bash
open ios/Runner.xcworkspace
```

### 3. В Xcode:
1. Подождите, пока Xcode загрузит проект (может занять минуту)
2. Выберите симулятор **iPhone 16 Plus**
3. Нажмите **Product → Clean Build Folder** (Shift+Cmd+K)
4. Нажмите **Product → Run** (Cmd+R)

### 4. Если ошибка сохраняется:

#### Вариант A: Пересоберите проект в Xcode
1. В Xcode: **Product → Clean Build Folder** (Shift+Cmd+K)
2. Закройте Xcode
3. В терминале:
   ```bash
   cd ios
   export LANG=en_US.UTF-8
   pod install
   cd ..
   ```
4. Откройте Xcode снова: `open ios/Runner.xcworkspace`
5. Запустите: **Product → Run**

#### Вариант B: Проверьте настройки проекта в Xcode
1. Откройте `ios/Runner.xcworkspace`
2. Выберите проект **Runner** в навигаторе
3. Выберите target **Runner**
4. Перейдите на вкладку **Build Settings**
5. Найдите **Framework Search Paths**
6. Убедитесь, что там есть путь к Pods:
   ```
   $(inherited)
   ${PODS_CONFIGURATION_BUILD_DIR}
   ```

## Альтернатива: Запуск через Flutter

Если Xcode не работает, попробуйте через Flutter:

```bash
flutter clean
flutter pub get
cd ios && export LANG=en_US.UTF-8 && pod install && cd ..
flutter run
```

## Проверка:

После открытия `Runner.xcworkspace` в Xcode:
- ✅ Должен быть виден проект Runner
- ✅ Должны быть видны Pods в навигаторе
- ✅ Не должно быть ошибок "No such module"

## Если проблема сохраняется:

1. **Убедитесь, что используете .xcworkspace:**
   ```bash
   # Проверьте, что файл существует
   ls -la ios/Runner.xcworkspace
   ```

2. **Переустановите pods:**
   ```bash
   cd ios
   rm -rf Pods Podfile.lock
   export LANG=en_US.UTF-8
   pod install
   cd ..
   ```

3. **Проверьте, что Firebase установлен:**
   ```bash
   ls -la ios/Pods/FirebaseCore/
   ```

