# Исправление Bundle ID в Firebase Console

## Проблема
В Firebase Console указан неправильный bundle ID `123456`, что вызывает проблемы с авторизацией и запуском приложения.

## Правильные Bundle ID:

- **iOS**: `com.example.akimatProject`
- **Android**: `com.example.akimat_project`

## Как исправить в Firebase Console:

### 1. Откройте Firebase Console
- Перейдите на https://console.firebase.google.com/
- Выберите проект **smsakimat**

### 2. Для iOS приложения:

1. Перейдите в **⚙️ Settings** → **Project settings**
2. Прокрутите вниз до раздела **Your apps**
3. Найдите ваше **iOS app** (или создайте, если еще нет)
4. Нажмите на иконку **✏️ (Edit)** рядом с приложением
5. В поле **Bundle ID** измените `123456` на:
   ```
   com.example.akimatProject
   ```
6. Нажмите **Save**

### 3. Для Android приложения:

1. В том же разделе **Your apps** найдите ваше **Android app**
2. Нажмите на иконку **✏️ (Edit)** рядом с приложением
3. В поле **Package name** измените `123456` на:
   ```
   com.example.akimat_project
   ```
4. Нажмите **Save**

### 4. Если приложения еще нет, создайте их:

#### Создание iOS приложения:
1. В разделе **Your apps** нажмите **Add app** → **iOS**
2. **Bundle ID**: `com.example.akimatProject`
3. **App nickname** (опционально): `Akimat Project iOS`
4. Нажмите **Register app**
5. Скачайте `GoogleService-Info.plist`
6. Поместите файл в `ios/Runner/GoogleService-Info.plist`

#### Создание Android приложения:
1. В разделе **Your apps** нажмите **Add app** → **Android**
2. **Package name**: `com.example.akimat_project`
3. **App nickname** (опционально): `Akimat Project Android`
4. Нажмите **Register app**
5. Скачайте `google-services.json`
6. Поместите файл в `android/app/google-services.json`

### 5. После исправления:

1. **Удалите старое приложение** с симулятора/устройства:
   ```bash
   # iOS
   xcrun simctl uninstall booted com.example.akimatProject
   
   # Android (если нужно)
   adb uninstall com.example.akimat_project
   ```

2. **Очистите проект:**
   ```bash
   flutter clean
   flutter pub get
   ```

3. **Пересоберите и запустите:**
   ```bash
   flutter run
   ```

## Важно:

- Bundle ID должен **точно совпадать** с тем, что в проекте
- После изменения bundle ID в Firebase нужно **пересобрать** приложение
- Убедитесь, что файлы `GoogleService-Info.plist` (iOS) и `google-services.json` (Android) соответствуют правильному bundle ID

## Проверка:

После исправления:
- ✅ Phone Authentication будет работать
- ✅ Приложение будет запускаться без ошибок
- ✅ Firebase сервисы будут правильно подключены

