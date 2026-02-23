# Исправление "No such module 'Flutter'" в Xcode

## ⚠️ КРИТИЧЕСКИ ВАЖНО:

### 1. ВСЕГДА используйте `.xcworkspace`, НЕ `.xcodeproj`!

```bash
# ✅ ПРАВИЛЬНО:
open ios/Runner.xcworkspace

# ❌ НЕПРАВИЛЬНО:
open ios/Runner.xcodeproj
```

### 2. Перед открытием Xcode выполните:

```bash
cd /Users/admin/Documents/FlutterProjects/akimat_project
flutter pub get
cd ios
export LANG=en_US.UTF-8
pod install
cd ..
```

### 3. В Xcode:

1. **Закройте Xcode полностью** (если открыт)
2. Откройте: `open ios/Runner.xcworkspace`
3. Подождите, пока Xcode загрузит проект (30-60 секунд)
4. **Product → Clean Build Folder** (Shift+Cmd+K)
5. Подождите завершения очистки
6. **Product → Run** (Cmd+R)

## Если ошибка сохраняется:

### Вариант 1: Пересоберите через Flutter

```bash
flutter clean
flutter pub get
cd ios
export LANG=en_US.UTF-8
pod install
cd ..
flutter build ios --debug --no-codesign --simulator
```

Затем откройте Xcode:
```bash
open ios/Runner.xcworkspace
```

### Вариант 2: Используйте Flutter вместо Xcode

**Это самый простой способ:**

```bash
flutter run
```

Flutter автоматически:
- Соберет проект
- Установит зависимости  
- Запустит на симуляторе
- Подключится к VM Service

**Рекомендую использовать `flutter run` вместо Xcode!**

## Проверка в Xcode:

После открытия `Runner.xcworkspace`:
1. В навигаторе слева должны быть видны:
   - ✅ Runner (проект)
   - ✅ Pods (зависимости)
   - ✅ Flutter (framework)

2. Если не видно Pods или Flutter:
   - Закройте Xcode
   - Выполните `pod install` снова
   - Откройте `.xcworkspace` снова

## Почему возникает ошибка:

- Открыт `.xcodeproj` вместо `.xcworkspace`
- Flutter framework не сгенерирован
- Xcode не видит зависимости из Pods

## Решение:

**Просто используйте `flutter run` - это проще и надежнее!**

