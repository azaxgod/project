# Пошаговая инструкция: Настройка Firebase через FlutterFire CLI

## ✅ Шаг 1: Авторизация в Firebase CLI

Выполните в терминале:

```bash
firebase login
```

Откроется браузер - войдите в свой Google аккаунт, который используется для Firebase проекта `smsakimat`.

## ✅ Шаг 2: Настройка FlutterFire

После успешной авторизации выполните:

```bash
export PATH="$PATH:$HOME/.pub-cache/bin"
cd /Users/admin/Documents/FlutterProjects/akimat_project
flutterfire configure --project=smsakimat
```

FlutterFire CLI спросит:
- Какие платформы настроить? (выберите: iOS, Android, Web)
- Для iOS: выберите существующее приложение или создайте новое
- Для Android: выберите существующее приложение или создайте новое
- Для Web: выберите существующее приложение или создайте новое

**Важно:** Выберите существующие приложения с правильными Bundle ID/Package Name:
- iOS: `com.example.akimatProject`
- Android: `com.example.akimat_project`
- Web: существующее веб-приложение

## ✅ Шаг 3: Обновление main.dart

После создания `lib/firebase_options.dart`, я обновлю `lib/main.dart` автоматически.

## ✅ Шаг 4: Проверка

```bash
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter run
```

## Что делает FlutterFire CLI:

1. ✅ Создает `lib/firebase_options.dart` с конфигурацией для всех платформ
2. ✅ Обновляет `android/app/google-services.json`
3. ✅ Обновляет `ios/Runner/GoogleService-Info.plist`
4. ✅ Синхронизирует конфигурацию с Firebase Console

## Преимущества:

- ✅ Единый источник конфигурации
- ✅ Автоматическая синхронизация
- ✅ Правильные Bundle ID и Package Name
- ✅ Упрощенная поддержка

---

**После выполнения шагов 1-2, сообщите мне - я обновлю main.dart автоматически!**

