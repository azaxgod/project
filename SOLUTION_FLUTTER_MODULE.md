# Решение ошибки "No such module 'Flutter'" в Xcode

## ⚠️ ВАЖНО: Используйте Flutter, а не Xcode!

**Для Flutter проектов НЕ нужно открывать Xcode вручную!**

### Просто используйте:
```bash
flutter run
```

Flutter автоматически:
- ✅ Соберет проект
- ✅ Установит зависимости
- ✅ Запустит на симуляторе
- ✅ Подключится к VM Service

## Если все же нужно использовать Xcode:

### 1. Убедитесь, что проект собран через Flutter:
```bash
flutter build ios --debug --no-codesign --simulator
```

### 2. Закройте Xcode полностью

### 3. Откройте ПРАВИЛЬНЫЙ файл:
```bash
open ios/Runner.xcworkspace
```

**НЕ используйте:** `ios/Runner.xcodeproj` ❌

### 4. В Xcode:

1. Подождите, пока проект загрузится (может занять минуту)
2. В навигаторе слева должны быть видны:
   - Runner (проект)
   - Pods (зависимости)
3. Если не видно Pods:
   - Закройте Xcode
   - Выполните: `cd ios && pod install && cd ..`
   - Откройте снова: `open ios/Runner.xcworkspace`
4. **Product → Clean Build Folder** (Shift+Cmd+K)
5. Подождите завершения
6. **Product → Run** (Cmd+R)

## Почему возникает ошибка:

Flutter framework генерируется **динамически** при сборке через Flutter. Xcode может не видеть его до первой успешной сборки.

## Решение:

**Просто используйте `flutter run` - это проще и надежнее!**

Xcode нужен только для:
- Настройки подписи кода (code signing)
- Настройки capabilities
- Отладки нативных iOS проблем

Для обычной разработки используйте `flutter run`.

