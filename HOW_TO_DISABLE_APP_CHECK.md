# Как отключить App Check для Phone Authentication

## Быстрое решение:

### 1. Откройте Firebase Console:
https://console.firebase.google.com/project/smsakimat/appcheck

### 2. Отключите App Check для Phone Authentication:

**Вариант A: Отключить для Phone Authentication только**
1. Перейдите в **App Check** → **APIs**
2. Найдите **"Phone Authentication"** или **"Identity Toolkit API"**
3. Нажмите на настройки (шестеренка) рядом с API
4. Выберите **"Unenforced"** (не принудительно)

**Вариант B: Отключить App Check полностью (для разработки)**
1. Перейдите в **App Check** → **Settings**
2. Найдите переключатель **"Enforce App Check"**
3. Выключите его для всех API

### 3. Сохраните изменения и перезапустите приложение

## Альтернатива: Настроить Debug Tokens (для разработки)

Если нужно оставить App Check включенным:

1. **Firebase Console → App Check → Settings**
2. Включите **"Debug tokens"**
3. Для Android: получите debug token из логов:
   ```bash
   adb logcat | grep "FirebaseAppCheck"
   ```
4. Добавьте debug token в Firebase Console

## Проверка:

После отключения:
1. Перезапустите приложение: `flutter run`
2. Попробуйте отправить SMS код
3. Ошибка 39 должна исчезнуть

## Примечание:

- App Check - это защита от злоупотреблений
- Для разработки можно отключить
- Для production рекомендуется правильно настроить App Check

