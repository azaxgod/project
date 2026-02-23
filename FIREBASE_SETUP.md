# Настройка Firebase для SMS-авторизации

## Шаг 1: Создание проекта Firebase

1. Перейдите на [Firebase Console](https://console.firebase.google.com/)
2. Создайте новый проект или выберите существующий
3. Включите **Authentication** в меню слева
4. В разделе Authentication включите **Phone** провайдер

## Шаг 2: Настройка для Web

1. В Firebase Console перейдите в **Project Settings** → **General**
2. В разделе **Your apps** добавьте **Web app** (если еще не добавлен)
3. Скопируйте конфигурацию Firebase (firebaseConfig)
4. Обновите файл `web/index.html` с вашей конфигурацией

Пример конфигурации в `web/index.html`:
```html
<script type="module">
  import { initializeApp } from 'https://www.gstatic.com/firebasejs/10.7.1/firebase-app.js';
  import { getAuth } from 'https://www.gstatic.com/firebasejs/10.7.1/firebase-auth.js';
  
  const firebaseConfig = {
    apiKey: "YOUR_API_KEY",
    authDomain: "YOUR_PROJECT_ID.firebaseapp.com",
    projectId: "YOUR_PROJECT_ID",
    storageBucket: "YOUR_PROJECT_ID.appspot.com",
    messagingSenderId: "YOUR_MESSAGING_SENDER_ID",
    appId: "YOUR_APP_ID"
  };
  
  const app = initializeApp(firebaseConfig);
  const auth = getAuth(app);
</script>
```

## Шаг 3: Настройка для Android

1. В Firebase Console перейдите в **Project Settings** → **General**
2. В разделе **Your apps** добавьте **Android app**
3. Укажите package name: `com.example.akimat_project` (или ваш package name)
4. Скачайте файл `google-services.json`
5. Поместите `google-services.json` в папку `android/app/`
6. Обновите `android/app/build.gradle.kts`:

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // Добавьте эту строку
}

dependencies {
    // ... другие зависимости
    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))
    implementation("com.google.firebase:firebase-auth")
}
```

7. Обновите `android/build.gradle.kts`:

```kotlin
buildscript {
    dependencies {
        classpath("com.google.gms:google-services:4.4.0") // Добавьте эту строку
    }
}
```

## Шаг 4: Настройка для iOS

1. В Firebase Console перейдите в **Project Settings** → **General**
2. В разделе **Your apps** добавьте **iOS app**
3. Укажите Bundle ID: `com.example.akimatProject` (или ваш Bundle ID)
4. Скачайте файл `GoogleService-Info.plist`
5. Откройте `ios/Runner.xcworkspace` в Xcode
6. Перетащите `GoogleService-Info.plist` в папку `Runner` в Xcode
7. Убедитесь, что файл добавлен в target "Runner"

## Шаг 5: Настройка Phone Authentication

1. В Firebase Console перейдите в **Authentication** → **Sign-in method**
2. Включите **Phone** провайдер
3. Для тестирования добавьте тестовые номера телефонов (опционально)

## Шаг 6: Настройка reCAPTCHA для Web

Для веб-версии Firebase Phone Auth требует reCAPTCHA:
1. В Firebase Console перейдите в **Authentication** → **Settings** → **Authorized domains**
2. Добавьте ваш домен (для localhost уже добавлен)
3. При первом использовании на вебе появится reCAPTCHA

## Важные замечания

- **Для продакшена**: Настройте App Check для защиты от злоупотреблений
- **Лимиты**: Firebase Phone Auth имеет лимиты на количество SMS в день
- **Стоимость**: Проверьте тарифы Firebase для Phone Authentication
- **Безопасность**: Используйте Firebase App Check для дополнительной защиты

## Проверка настройки

После настройки запустите приложение:
- **Web**: `flutter run -d chrome`
- **Android**: `flutter run`
- **iOS**: `flutter run`

При первом использовании SMS-авторизации:
- На вебе появится reCAPTCHA
- На Android/iOS SMS будет отправлено автоматически

