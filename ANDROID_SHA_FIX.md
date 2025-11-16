# Быстрое исправление: "missing a valid app identifier" на Android

## Ваши SHA отпечатки (уже получены):

**SHA-1:**
```
7B:A9:E4:14:1B:04:38:A0:1A:A0:8B:A7:94:67:35:17:71:12:4E:4A
```

**SHA-256:**
```
43:A4:D1:55:A8:F6:DD:D0:D0:2A:38:43:26:75:3B:8F:FA:63:78:FD:C5:B9:F7:78:3A:9C:04:BE:C9:15:A9:B7
```

## Что нужно сделать (2 минуты):

### 1. Откройте Firebase Console
- Перейдите на https://console.firebase.google.com/
- Выберите проект **smsakimat**

### 2. Добавьте SHA отпечатки
1. Нажмите **⚙️** (Settings) → **Project settings**
2. Прокрутите вниз до раздела **Your apps**
3. Найдите ваше **Android app** с package name `com.example.akimat_project`
   - Если приложения нет, нажмите **Add app** → **Android** → создайте с package `com.example.akimat_project`
4. Нажмите на иконку **карандаша** (✏️) рядом с приложением
5. В разделе **SHA certificate fingerprints**:
   - Нажмите **Add fingerprint**
   - Вставьте SHA-1: `7B:A9:E4:14:1B:04:38:A0:1A:A0:8B:A7:94:67:35:17:71:12:4E:4A`
   - Нажмите **Save**
   - Нажмите **Add fingerprint** еще раз
   - Вставьте SHA-256: `43:A4:D1:55:A8:F6:DD:D0:D0:2A:38:43:26:75:3B:8F:FA:63:78:FD:C5:B9:F7:78:3A:9C:04:BE:C9:15:A9:B7`
   - Нажмите **Save**

### 3. Скачайте google-services.json
1. После добавления отпечатков нажмите **Download google-services.json**
2. Поместите файл в `android/app/google-services.json`
3. Убедитесь, что файл добавлен в проект

### 4. Пересоберите приложение
```bash
flutter clean
flutter pub get
flutter run
```

## Готово! ✅

После этих шагов:
- ✅ Ошибка "missing a valid app identifier" исчезнет
- ✅ Phone Authentication будет работать на Android
- ✅ Play Integrity проверки будут проходить успешно

## Если приложения Android еще нет в Firebase:

1. В Firebase Console → **Project settings** → **Your apps**
2. Нажмите **Add app** → выберите **Android**
3. Package name: `com.example.akimat_project`
4. App nickname (опционально): `Akimat Project Android`
5. Нажмите **Register app**
6. Скачайте `google-services.json` → поместите в `android/app/`
7. Добавьте SHA-1 и SHA-256 отпечатки (см. выше)

Подробная инструкция: `FIREBASE_ANDROID_SHA.md`

