# Решение проблемы с iOS приложением в Firebase

## Проблема:
FlutterFire CLI не может автоматически создать iOS приложение в Firebase проекте `smsakimat`.

## Решение: Создайте iOS приложение вручную в Firebase Console

### Шаг 1: Откройте Firebase Console
1. Перейдите на https://console.firebase.google.com/
2. Выберите проект `smsakimat`

### Шаг 2: Добавьте iOS приложение
1. Нажмите на иконку **⚙️ (Settings)** → **Project settings**
2. Прокрутите вниз до раздела **Your apps**
3. Нажмите **"Add app"** → выберите **iOS**
4. Введите:
   - **iOS bundle ID**: `com.example.akimatProject`
   - **App nickname** (опционально): `akimat_project iOS`
   - **App Store ID** (опционально): оставьте пустым
5. Нажмите **"Register app"**

### Шаг 3: Скачайте GoogleService-Info.plist
1. После регистрации скачайте `GoogleService-Info.plist`
2. Скопируйте его в: `ios/Runner/GoogleService-Info.plist`
3. **Замените** существующий файл (если есть)

### Шаг 4: Продолжите настройку FlutterFire
После создания iOS приложения в Firebase Console, запустите снова:

```bash
export PATH="$PATH:$HOME/.pub-cache/bin"
flutterfire configure --project=smsakimat
```

Теперь FlutterFire CLI найдет существующее iOS приложение и настроит его автоматически.

## Альтернатива: Настройте только Android и Web

Если хотите продолжить без iOS сейчас:

1. Запустите `flutterfire configure` снова
2. Выберите только **Android** и **Web** (не выбирайте iOS)
3. iOS можно настроить позже вручную

---

**Рекомендация:** Создайте iOS приложение в Firebase Console (шаги 1-3), затем запустите `flutterfire configure` снова.

