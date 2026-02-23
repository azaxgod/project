# Создание нового iOS приложения в Firebase с правильным Bundle ID

## Проблема
Bundle ID нельзя изменить после создания приложения в Firebase. Нужно создать новое приложение.

## Решение: Создать новое iOS приложение

### Шаг 1: Создайте новое iOS приложение в Firebase

1. Откройте Firebase Console: https://console.firebase.google.com/
2. Выберите проект **smsakimat**
3. Перейдите в **⚙️ Settings** → **Project settings**
4. Прокрутите вниз до раздела **Your apps**
5. Нажмите **Add app** (или иконку **+**)
6. Выберите **iOS** (яблоко)
7. Заполните форму:
   - **Bundle ID**: `com.example.akimatProject` (с буквой 't'!)
   - **App nickname** (опционально): `Akimat Project iOS Correct`
   - **App Store ID**: оставьте пустым (если нет)
8. Нажмите **Register app**

### Шаг 2: Скачайте GoogleService-Info.plist

1. После регистрации нажмите **Download GoogleService-Info.plist**
2. Сохраните файл на компьютер

### Шаг 3: Замените файл в проекте

```bash
cd /Users/admin/Documents/FlutterProjects/akimat_project

# Удалите старый файл (или сделайте backup)
mv ios/Runner/GoogleService-Info.plist ios/Runner/GoogleService-Info.plist.old

# Поместите новый файл
# Скопируйте скачанный GoogleService-Info.plist в:
# ios/Runner/GoogleService-Info.plist
```

### Шаг 4: Проверьте Bundle ID в новом файле

```bash
# Проверьте, что Bundle ID правильный
grep -A 1 "BUNDLE_ID" ios/Runner/GoogleService-Info.plist
# Должно быть: com.example.akimatProject (с 't')
```

### Шаг 5: Пересоберите проект

```bash
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter run
```

## Важно:

- **Старое приложение** с Bundle ID `com.example.akimatProjec` можно оставить (не мешает)
- **Новое приложение** с Bundle ID `com.example.akimatProject` будет использоваться
- Убедитесь, что используете **новый** `GoogleService-Info.plist`

## Альтернатива: Удалить старое приложение

Если хотите удалить старое приложение:

1. В Firebase Console → **Project settings** → **Your apps**
2. Найдите старое iOS приложение с Bundle ID `com.example.akimatProjec`
3. Нажмите на **три точки** (⋮) рядом с приложением
4. Выберите **Delete app** (удаление необратимо!)

**Рекомендация:** Просто создайте новое приложение, старое можно оставить.

