# Пошаговая инструкция: Создание нового iOS приложения в Firebase

## Шаг 1: Откройте Firebase Console
1. Перейдите на https://console.firebase.google.com/
2. Войдите в аккаунт
3. Выберите проект **smsakimat**

## Шаг 2: Перейдите в настройки проекта
1. Нажмите на иконку **⚙️ (Settings)** в левом верхнем углу
2. Выберите **Project settings**

## Шаг 3: Найдите раздел "Your apps"
1. Прокрутите страницу вниз
2. Найдите раздел **Your apps**
3. Там будет список ваших приложений (iOS, Android, Web)

## Шаг 4: Создайте новое iOS приложение
1. Нажмите кнопку **Add app** (или иконку **+**)
2. Выберите платформу **iOS** (иконка яблока 🍎)

## Шаг 5: Заполните форму регистрации
1. **Bundle ID**: Введите точно:
   ```
   com.example.akimatProject
   ```
   ⚠️ **ВАЖНО:** С буквой 't' на конце! Не `akimatProjec`, а `akimatProject`!

2. **App nickname** (опционально): 
   ```
   Akimat Project iOS
   ```
   (можно оставить пустым)

3. **App Store ID**: Оставьте пустым (если нет в App Store)

4. Нажмите **Register app**

## Шаг 6: Скачайте GoogleService-Info.plist
1. После регистрации вы увидите страницу с инструкциями
2. Найдите кнопку **Download GoogleService-Info.plist**
3. Нажмите на неё и сохраните файл на компьютер

## Шаг 7: Замените файл в проекте

### Вариант A: Через Finder (проще)
1. Откройте Finder
2. Перейдите в: `/Users/admin/Documents/FlutterProjects/akimat_project/ios/Runner/`
3. Найдите файл `GoogleService-Info.plist`
4. Переименуйте его в `GoogleService-Info.plist.old` (backup)
5. Скопируйте новый скачанный `GoogleService-Info.plist` в эту папку

### Вариант B: Через терминал
```bash
cd /Users/admin/Documents/FlutterProjects/akimat_project

# Сделайте backup старого файла
mv ios/Runner/GoogleService-Info.plist ios/Runner/GoogleService-Info.plist.old

# Скопируйте новый файл (замените путь на ваш)
cp ~/Downloads/GoogleService-Info.plist ios/Runner/GoogleService-Info.plist
```

## Шаг 8: Проверьте Bundle ID в новом файле
```bash
cd /Users/admin/Documents/FlutterProjects/akimat_project
grep -A 1 "BUNDLE_ID" ios/Runner/GoogleService-Info.plist
```

Должно показать:
```
<key>BUNDLE_ID</key>
<string>com.example.akimatProject</string>
```
(с буквой 't' на конце!)

## Шаг 9: Пересоберите проект
```bash
cd /Users/admin/Documents/FlutterProjects/akimat_project

# Очистите проект
flutter clean

# Обновите зависимости
flutter pub get

# Обновите iOS зависимости
cd ios
export LANG=en_US.UTF-8
pod install
cd ..

# Запустите приложение
flutter run
```

## Готово! ✅

После этих шагов:
- ✅ Новое приложение с правильным Bundle ID создано
- ✅ GoogleService-Info.plist обновлен
- ✅ Phone Authentication должен работать
- ✅ Приложение должно запускаться без ошибок

## Если что-то пошло не так:

1. **Проверьте Bundle ID в файле:**
   ```bash
   plutil -p ios/Runner/GoogleService-Info.plist | grep BUNDLE_ID
   ```

2. **Убедитесь, что файл на месте:**
   ```bash
   ls -la ios/Runner/GoogleService-Info.plist
   ```

3. **Проверьте, что Bundle ID совпадает с проектом:**
   ```bash
   grep "PRODUCT_BUNDLE_IDENTIFIER" ios/Runner.xcodeproj/project.pbxproj | head -1
   ```

Оба должны быть: `com.example.akimatProject` (с 't'!)

