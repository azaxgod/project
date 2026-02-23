# ✅ Миграция на Firebase Phone Authentication

## Что было сделано:

### 1. ✅ Обновлен `phone_login_widget.dart`
- Уже использовал Firebase Phone Authentication для отправки SMS и верификации
- Теперь передает `UserCredential` вместо `phone` и `code` в callback `onVerified`

### 2. ✅ Обновлен `login_page.dart`
- Использует новый метод `loginWithFirebasePhone` вместо `verifySms`
- После успешной верификации Firebase, получает `UserCredential` и авторизуется через Firebase

### 3. ✅ Обновлен `auth_notifier.dart`
- Добавлен метод `loginWithFirebasePhone(UserCredential, String phoneNumber)`
- Получает Firebase ID Token после успешной верификации
- Пытается отправить Firebase ID Token на бэкенд (`/auth/firebase-login`)
- Если бэкенд не поддерживает Firebase token (404), создает `User` из Firebase User с дефолтными значениями

### 4. ✅ Обновлен `i_auth_repository.dart`
- Добавлен метод `loginWithFirebaseToken(String firebaseIdToken, String phoneNumber)`

### 5. ✅ Обновлен `auth_repository_impl.dart`
- Реализован метод `loginWithFirebaseToken`
- Сохраняет токены после успешной авторизации

### 6. ✅ Обновлен `auth_collection.dart`
- Добавлен метод `loginWithFirebaseToken` для отправки Firebase ID Token на бэкенд
- Endpoint: `POST /auth/firebase-login`
- Если endpoint не найден (404), выбрасывает исключение для fallback на создание User из Firebase User

## Как это работает:

### Поток авторизации:

1. **Пользователь вводит номер телефона** → `PhoneLoginWidget`
2. **Отправка SMS через Firebase** → `FirebaseAuth.verifyPhoneNumber()`
3. **Пользователь вводит код из SMS** → `PhoneAuthProvider.credential()`
4. **Верификация через Firebase** → `FirebaseAuth.signInWithCredential()`
5. **Получение Firebase ID Token** → `firebaseUser.getIdToken()`
6. **Авторизация через бэкенд** (если поддерживается):
   - Отправка Firebase ID Token на `/auth/firebase-login`
   - Получение `User` и токенов от бэкенда
7. **Fallback** (если бэкенд не поддерживает):
   - Создание `User` из Firebase User с дефолтными значениями
   - `role: 'user'`, `isActive: true`

## Преимущества:

✅ **Полная интеграция с Firebase Phone Authentication**
- Использует Firebase для отправки SMS
- Использует Firebase для верификации кода
- Работает на Android, iOS и Web

✅ **Гибкая интеграция с бэкендом**
- Если бэкенд поддерживает Firebase auth, использует его
- Если нет, создает User из Firebase User

✅ **Безопасность**
- Использует Firebase ID Token для авторизации
- Не нужно хранить SMS коды на бэкенде

## Настройка бэкенда (опционально):

Если хотите использовать Firebase ID Token на бэкенде:

1. Создайте endpoint: `POST /auth/firebase-login`
2. Принимайте параметры:
   - `firebase_id_token`: Firebase ID Token
   - `phone`: номер телефона
3. Верифицируйте Firebase ID Token на бэкенде
4. Создайте/найдите пользователя в вашей БД
5. Верните `AuthResponse` с `User` и токенами

## Тестирование:

```bash
flutter run
```

1. Выберите вкладку "По номеру телефона"
2. Введите номер телефона
3. Нажмите "Отправить код"
4. Введите код из SMS
5. Нажмите "Подтвердить"
6. Должна произойти авторизация через Firebase

## Примечания:

- Старые методы `sendSms` и `verifySms` остались для обратной совместимости
- Если бэкенд не поддерживает `/auth/firebase-login`, будет создан User с дефолтными значениями
- Для получения правильной роли и других данных пользователя, нужно либо:
  - Настроить бэкенд для поддержки Firebase auth
  - Использовать Firebase Custom Claims
  - Обновить User после авторизации через другой endpoint

