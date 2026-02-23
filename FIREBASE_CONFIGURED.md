# Firebase конфигурация завершена ✅

## Что было настроено:

### ✅ Web (web/index.html)
- Добавлена конфигурация Firebase с вашими данными
- Инициализированы Firebase App, Analytics и Auth
- Конфигурация доступна через `window.firebaseApp` и `window.firebaseAuth`

### ✅ Android (android/app/build.gradle.kts)
- Обновлена версия Google Services plugin: `4.4.4`
- Обновлена версия Firebase BoM: `34.5.0`
- Добавлены зависимости: `firebase-analytics` и `firebase-auth`
- **Следующий шаг**: Добавьте файл `google-services.json` в `android/app/`

### ✅ iOS (ios/Runner/AppDelegate.swift)
- Добавлен импорт `FirebaseCore`
- Добавлена инициализация Firebase: `FirebaseApp.configure()`
- **Следующий шаг**: Добавьте файл `GoogleService-Info.plist` в `ios/Runner/`

## Следующие шаги:

### 1. Для Android:
1. Скачайте `google-services.json` из Firebase Console
2. Поместите файл в `android/app/google-services.json`
3. Убедитесь, что файл добавлен в проект

### 2. Для iOS:
1. Скачайте `GoogleService-Info.plist` из Firebase Console
2. Откройте `ios/Runner.xcworkspace` в Xcode
3. Перетащите `GoogleService-Info.plist` в папку `Runner`
4. Убедитесь, что файл добавлен в target "Runner"

### 3. Установите зависимости:
```bash
flutter pub get
cd ios && pod install && cd ..
```

### 4. Запустите приложение:
```bash
# Для веба
flutter run -d chrome

# Для Android
flutter run

# Для iOS
flutter run
```

## Проверка работы:

1. Откройте приложение
2. Перейдите на страницу логина
3. Выберите таб "По номеру телефона"
4. Введите номер телефона в формате +7XXXXXXXXXX
5. Нажмите "Отправить код"
6. Введите код из SMS
7. Нажмите "Подтвердить"

## Важно:

- **Для тестирования**: Добавьте тестовые номера телефонов в Firebase Console → Authentication → Settings → Phone numbers for testing
- **Для веба**: При первом использовании появится reCAPTCHA
- **Лимиты**: Firebase Phone Auth имеет лимиты на количество SMS в день

## Конфигурация проекта:

- **Project ID**: smsakimat
- **Auth Domain**: smsakimat.firebaseapp.com
- **Web App ID**: 1:1056160130840:web:d977b411f03d870199a06d

Все готово к использованию! 🚀

