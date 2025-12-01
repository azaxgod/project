# Отключение App Check для Firebase Phone Authentication

## Проблема:
App Check может блокировать запросы Phone Authentication, вызывая ошибки типа "error code 39" или "internal error".

## Решение 1: Отключить App Check в Firebase Console (Рекомендуется)

### Шаги:

1. **Откройте Firebase Console:**
   - https://console.firebase.google.com/
   - Выберите проект `smsakimat`

2. **Перейдите в App Check:**
   - В левом меню найдите **"App Check"** или **"Build" → "App Check"**

3. **Отключите App Check для Phone Authentication:**
   - Найдите **"Phone Authentication"** в списке API
   - Нажмите на настройки (шестеренка)
   - Выберите **"Unenforced"** (не принудительно) или **"Off"** (выключено)

4. **Или отключите App Check полностью:**
   - В настройках App Check выберите **"Disable App Check"** для всех API

## Решение 2: Настроить App Check в debug режиме (Для разработки)

Если нужно оставить App Check включенным, но разрешить запросы в debug режиме:

### Для Android:

1. **Добавьте в `android/app/build.gradle.kts`:**
   ```kotlin
   android {
       buildTypes {
           debug {
               // Разрешить App Check в debug режиме
           }
       }
   }
   ```

2. **В Firebase Console:**
   - App Check → Settings
   - Включите **"Debug tokens"**
   - Добавьте debug token вашего устройства

### Для iOS:

1. **В Firebase Console:**
   - App Check → Settings
   - Включите **"Debug tokens"** для iOS
   - Добавьте debug token вашего устройства

## Решение 3: Настроить App Check в коде (Если используется)

Если App Check инициализирован в коде, можно настроить его:

### Добавьте в `lib/main.dart`:

```dart
import 'package:firebase_app_check/firebase_app_check.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Настройка App Check для debug режима
  await FirebaseAppCheck.instance.activate(
    // Для Android - используйте DebugAppCheckProvider в debug режиме
    androidProvider: kDebugMode 
        ? AndroidProvider.debug 
        : AndroidProvider.playIntegrity,
    // Для iOS - используйте DebugAppCheckProvider в debug режиме
    appleProvider: kDebugMode 
        ? AppleProvider.debug 
        : AppleProvider.appAttest,
  );
  
  runApp(const ProviderScope(child: AkimatApp()));
}
```

**Но для полного отключения лучше использовать Решение 1.**

## Решение 4: Проверить настройки Phone Authentication

1. **Firebase Console → Authentication → Settings:**
   - Убедитесь, что Phone Authentication включена
   - Проверьте, что нет ограничений по App Check

2. **Firebase Console → App Check → APIs:**
   - Найдите "Phone Authentication"
   - Убедитесь, что она не принудительно защищена App Check

## Рекомендация:

**Для разработки и тестирования:**
- Отключите App Check полностью в Firebase Console
- Или настройте debug tokens

**Для production:**
- Настройте App Check правильно с debug tokens для тестирования
- Используйте правильные провайдеры (Play Integrity для Android, App Attest для iOS)

## Проверка:

После отключения App Check:
1. Перезапустите приложение
2. Попробуйте отправить SMS код
3. Ошибка 39 должна исчезнуть

## Примечания:

- App Check - это функция безопасности Firebase
- Отключение App Check снижает защиту, но упрощает разработку
- Для production рекомендуется правильно настроить App Check вместо полного отключения








