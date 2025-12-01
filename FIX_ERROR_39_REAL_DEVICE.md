# Исправление ошибки 39 на реальном устройстве

## Проблема:
На реальном устройстве при попытке получить SMS код возникает ошибка:
```
Firebase error: an internal error has occurred. Error code 39
```

## Основные причины на реальном устройстве:

### 1. ⚠️ App Check включен (самая частая причина)
### 2. ⚠️ Проблемы с Play Integrity API (Android)
### 3. ⚠️ Неправильные SHA отпечатки для release build
### 4. ⚠️ Проблемы с reCAPTCHA на реальном устройстве

## ✅ Решение 1: Отключить App Check (ПРИОРИТЕТ)

### Шаги:

1. **Откройте Firebase Console:**
   ```
   https://console.firebase.google.com/project/smsakimat/appcheck
   ```

2. **Отключите App Check:**
   - Перейдите в **App Check** → **APIs**
   - Найдите **"Phone Authentication"** или **"Identity Toolkit API"**
   - Нажмите на настройки (шестеренка)
   - Выберите **"Unenforced"** (не принудительно)

3. **Или отключите полностью:**
   - **App Check** → **Settings**
   - Выключите **"Enforce App Check"** для всех API

4. **Сохраните и перезапустите приложение**

## ✅ Решение 2: Проверить SHA отпечатки для release build

### Для Android:

Если используете release build, нужны SHA отпечатки release keystore:

```bash
# Получить SHA от release keystore
keytool -list -v -keystore /path/to/your/release.keystore -alias your-key-alias
```

**Важно:** SHA отпечатки для debug и release разные!

1. **Получите SHA-1 и SHA-256** от вашего release keystore
2. **Добавьте их в Firebase Console:**
   - Firebase Console → Project settings → Your apps → Android app
   - Добавьте SHA-1 и SHA-256 отпечатки
3. **Пересоберите приложение**

### Текущие SHA отпечатки (debug):
- **SHA-1:** `7B:A9:E4:14:1B:04:38:A0:1A:A0:8B:A7:94:67:35:17:71:12:4E:4A`
- **SHA-256:** `43:A4:D1:55:A8:F6:DD:D0:D0:2A:38:43:26:75:3B:8F:FA:63:78:FD:C5:B9:F7:78:3A:9C:04:BE:C9:15:A9:B7`

**Убедитесь, что они добавлены в Firebase Console!**

## ✅ Решение 3: Проверить Play Integrity API (Android)

### Для Android на реальном устройстве:

1. **Google Play Console:**
   - Убедитесь, что приложение зарегистрировано в Google Play Console
   - Или используйте debug build для тестирования

2. **Play Integrity API:**
   - Firebase Console → Project settings → Your apps → Android app
   - Убедитесь, что Play Integrity API включен
   - Проверьте, что SHA отпечатки правильные

3. **Для тестирования:**
   - Используйте debug build: `flutter run --debug`
   - Или добавьте debug SHA отпечатки в Firebase Console

## ✅ Решение 4: Проверить биллинг Firebase

1. **Firebase Console → Usage and billing:**
   - Убедитесь, что биллинг включен
   - Проверьте лимиты SMS (10 бесплатных SMS в день)
   - Если лимит превышен, включите платный план

## ✅ Решение 5: Проверить конфигурацию

### Android:

1. **Проверьте `google-services.json`:**
   - Должен быть в `android/app/google-services.json`
   - Должен быть скачан из Firebase Console
   - Package name должен совпадать: `com.example.akimat_project`

2. **Проверьте `build.gradle.kts`:**
   ```kotlin
   plugins {
       id("com.google.gms.google-services")
   }
   ```

### iOS:

1. **Проверьте `GoogleService-Info.plist`:**
   - Должен быть в `ios/Runner/GoogleService-Info.plist`
   - Bundle ID должен совпадать: `com.example.akimatProject`

## ✅ Решение 6: Диагностика

### Добавьте логирование:

В `phone_login_widget.dart` уже есть логирование ошибок. Проверьте логи:

```bash
# Android
adb logcat | grep "FIREBASE PHONE AUTH ERROR"

# iOS
# Смотрите логи в Xcode Console
```

### Проверьте детали ошибки:

В диалоге ошибки будут показаны:
- Код ошибки
- Сообщение об ошибке
- Детали ошибки

## ✅ Быстрая проверка:

1. ✅ **App Check отключен?** → Firebase Console → App Check → APIs → Phone Auth → Unenforced
2. ✅ **SHA отпечатки добавлены?** → Firebase Console → Project settings → Android app
3. ✅ **Биллинг включен?** → Firebase Console → Usage and billing
4. ✅ **Конфигурация правильная?** → Проверьте `google-services.json` и `GoogleService-Info.plist`
5. ✅ **Используете debug build?** → `flutter run --debug` для тестирования

## ✅ Рекомендуемый порядок действий:

1. **Сначала отключите App Check** (самая частая причина)
2. **Проверьте SHA отпечатки** в Firebase Console
3. **Убедитесь, что биллинг включен**
4. **Попробуйте debug build** для тестирования
5. **Проверьте логи** для деталей ошибки

## Примечания:

- Ошибка 39 часто связана с App Check на реальных устройствах
- Для production нужно правильно настроить App Check с Play Integrity
- Для разработки можно отключить App Check полностью
- SHA отпечатки для debug и release разные - добавьте оба








