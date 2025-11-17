# Настройка Firebase через FlutterFire CLI

## Шаг 1: Авторизация в Firebase CLI

Выполните команду (откроется браузер для входа):

```bash
firebase login
```

После успешной авторизации переходите к следующему шагу.

## Шаг 2: Настройка FlutterFire

```bash
export PATH="$PATH:$HOME/.pub-cache/bin"
flutterfire configure --project=smsakimat
```

FlutterFire CLI автоматически:
- ✅ Найдет ваши приложения в Firebase Console
- ✅ Создаст `lib/firebase_options.dart` с конфигурацией для всех платформ
- ✅ Обновит `android/app/google-services.json` (если нужно)
- ✅ Обновит `ios/Runner/GoogleService-Info.plist` (если нужно)

## Шаг 3: Обновление main.dart

После создания `firebase_options.dart`, обновите `lib/main.dart`:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Инициализация Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ProviderScope(child: AkimatApp()));
}
```

## Преимущества FlutterFire CLI:

1. ✅ Автоматическая синхронизация конфигурации
2. ✅ Единый файл `firebase_options.dart` для всех платформ
3. ✅ Автоматическое обновление при изменении в Firebase Console
4. ✅ Правильные Bundle ID и Package Name

## Если нужно обновить конфигурацию:

Просто запустите снова:
```bash
flutterfire configure --project=smsakimat
```

