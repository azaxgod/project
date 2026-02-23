# Настройка Firebase для Flutter проектов

## ⚠️ ВАЖНО: Инструкция из Firebase Console НЕ для Flutter!

Инструкция про Swift Package Manager из Firebase Console предназначена для **нативных iOS проектов**, а не для Flutter.

## ✅ Для Flutter проектов Firebase настраивается по-другому:

### 1. Firebase уже настроен в вашем проекте! ✅

Проверьте:
- ✅ `pubspec.yaml` содержит `firebase_core` и `firebase_auth`
- ✅ `AppDelegate.swift` инициализирует Firebase
- ✅ `Podfile` автоматически устанавливает Firebase через CocoaPods

### 2. Что нужно сделать:

#### Шаг 1: Убедитесь, что Bundle ID правильный в Firebase

1. Откройте Firebase Console
2. Создайте **новое iOS приложение** с Bundle ID: `com.example.akimatProject` (с 't'!)
3. Скачайте `GoogleService-Info.plist`
4. Замените файл `ios/Runner/GoogleService-Info.plist`

#### Шаг 2: Проверьте Bundle ID в файле

```bash
grep -A 1 "BUNDLE_ID" ios/Runner/GoogleService-Info.plist
```

Должно быть: `com.example.akimatProject` (с 't' на конце!)

#### Шаг 3: Пересоберите проект

```bash
flutter clean
flutter pub get
cd ios
export LANG=en_US.UTF-8
pod install
cd ..
flutter run
```

## ❌ НЕ нужно делать:

- ❌ НЕ добавляйте Firebase через Swift Package Manager в Xcode
- ❌ НЕ следуйте инструкции из Firebase Console про Swift Package Manager
- ❌ НЕ изменяйте AppDelegate.swift (он уже правильный)

## ✅ Что уже правильно настроено:

1. **pubspec.yaml:**
   ```yaml
   firebase_core: ^3.6.0
   firebase_auth: ^5.3.1
   ```

2. **AppDelegate.swift:**
   ```swift
   import FirebaseCore
   FirebaseApp.configure()
   ```

3. **Podfile:**
   - Использует `flutter_install_all_ios_pods` который автоматически устанавливает Firebase

## Главное:

**Единственное, что нужно исправить - это Bundle ID в Firebase Console и заменить GoogleService-Info.plist!**

Всё остальное уже настроено правильно для Flutter проекта.

