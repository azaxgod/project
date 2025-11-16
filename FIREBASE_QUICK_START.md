# Быстрый старт: Firebase SMS-авторизация

## Что было реализовано

✅ Два варианта авторизации на странице логина:
- **Слева (Таб 1)**: Авторизация по логину/паролю (Акимат)
- **Справа (Таб 2)**: Авторизация по номеру телефона через Firebase

✅ Интеграция Firebase для:
- Web (через Flutter Firebase SDK)
- Android (через google-services.json)
- iOS (через GoogleService-Info.plist)

## Следующие шаги для настройки

### 1. Создайте проект Firebase

1. Перейдите на https://console.firebase.google.com/
2. Создайте новый проект
3. Включите **Authentication** → **Phone** провайдер

### 2. Для Android

1. В Firebase Console: **Project Settings** → **Your apps** → **Add Android app**
2. Package name: `com.example.akimat_project`
3. Скачайте `google-services.json`
4. Поместите в `android/app/google-services.json`

### 3. Для iOS

1. В Firebase Console: **Project Settings** → **Your apps** → **Add iOS app**
2. Bundle ID: ваш Bundle ID
3. Скачайте `GoogleService-Info.plist`
4. Откройте `ios/Runner.xcworkspace` в Xcode
5. Перетащите `GoogleService-Info.plist` в папку `Runner`

### 4. Для Web

Firebase SDK автоматически инициализируется. Для продакшена может потребоваться добавить конфигурацию в `web/index.html` (см. комментарии в файле).

## Использование

1. Запустите приложение
2. На странице логина выберите таб "По номеру телефона"
3. Введите номер телефона в формате +7XXXXXXXXXX
4. Нажмите "Отправить код"
5. Введите код из SMS
6. Нажмите "Подтвердить"

После успешной верификации Firebase, приложение автоматически авторизует пользователя через ваш API (`/auth/verify-code`).

## Важно

- Для тестирования можно добавить тестовые номера в Firebase Console
- На вебе при первом использовании появится reCAPTCHA
- На Android/iOS SMS отправляется автоматически через Firebase

Подробная инструкция: см. `FIREBASE_SETUP.md`

