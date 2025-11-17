# Быстрое исправление Bundle ID в Firebase

## Проблема
В Firebase Console указан bundle ID `123456` вместо правильного.

## Правильные значения:

- **iOS Bundle ID**: `com.example.akimatProject`
- **Android Package**: `com.example.akimat_project`

## Что нужно сделать (5 минут):

### 1. Откройте Firebase Console
https://console.firebase.google.com/ → проект **smsakimat**

### 2. Исправьте iOS приложение:
1. **Settings** (⚙️) → **Project settings**
2. Раздел **Your apps** → найдите **iOS app**
3. Нажмите **✏️ Edit**
4. Измените **Bundle ID** с `123456` на: `com.example.akimatProject`
5. **Save**

### 3. Исправьте Android приложение:
1. В том же разделе найдите **Android app**
2. Нажмите **✏️ Edit**
3. Измените **Package name** с `123456` на: `com.example.akimat_project`
4. **Save**

### 4. Скачайте обновленные конфигурационные файлы:

#### Для iOS:
1. После изменения bundle ID нажмите **Download GoogleService-Info.plist**
2. Замените файл `ios/Runner/GoogleService-Info.plist`

#### Для Android:
1. После изменения package name нажмите **Download google-services.json**
2. Замените файл `android/app/google-services.json`

### 5. Пересоберите проект:
```bash
flutter clean
flutter pub get
flutter run
```

## Если приложения еще нет в Firebase:

### Создайте iOS приложение:
1. **Add app** → **iOS**
2. **Bundle ID**: `com.example.akimatProject`
3. **Register app**
4. Скачайте `GoogleService-Info.plist` → `ios/Runner/`

### Создайте Android приложение:
1. **Add app** → **Android**
2. **Package name**: `com.example.akimat_project`
3. **Register app**
4. Скачайте `google-services.json` → `android/app/`

## После исправления:

- ✅ Phone Authentication будет работать
- ✅ Приложение будет запускаться
- ✅ Firebase сервисы будут подключены правильно

**Важно:** Bundle ID должен точно совпадать с проектом!

