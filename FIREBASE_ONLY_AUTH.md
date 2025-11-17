# ✅ Чистая Firebase Phone Authentication для подрядчиков

## Что было сделано:

### 1. ✅ Обновлен `auth_notifier.dart`
- **Убрана интеграция с бэкендом** - теперь используется только Firebase
- **`_loadUserFromToken()`** - проверяет `FirebaseAuth.instance.currentUser` вместо токенов бэкенда
- **`loginWithFirebasePhone()`** - создает User из Firebase User без вызовов бэкенда
- **`logout()`** - вызывает `FirebaseAuth.instance.signOut()`
- **`_createUserFromFirebase()`** - создает User с ролью `CONTRACTOR_ADMIN` для подрядчиков

### 2. ✅ Роль для подрядчиков
- По умолчанию используется роль: **`CONTRACTOR_ADMIN`**
- Можно настроить Custom Claims через Firebase Admin SDK для получения дополнительных данных

## Как это работает:

### Поток авторизации:

1. **Пользователь вводит номер телефона** → `PhoneLoginWidget`
2. **Отправка SMS через Firebase** → `FirebaseAuth.verifyPhoneNumber()`
3. **Пользователь вводит код из SMS** → `PhoneAuthProvider.credential()`
4. **Верификация через Firebase** → `FirebaseAuth.signInWithCredential()`
5. **Создание User из Firebase User**:
   - `id`: Firebase UID
   - `phone`: номер телефона из Firebase
   - `role`: `CONTRACTOR_ADMIN` (дефолт для подрядчиков)
   - `isActive`: `true`

### Проверка авторизации при старте:

- Проверяет `FirebaseAuth.instance.currentUser`
- Если пользователь авторизован, создает User из Firebase User
- Не использует токены бэкенда

### Выход:

- Вызывает `FirebaseAuth.instance.signOut()`
- Очищает локальные токены (если они были)

## Настройка Custom Claims (опционально):

Если нужно хранить дополнительную информацию (роль, organizationId и т.д.), можно использовать Firebase Custom Claims:

### Через Firebase Admin SDK:

```javascript
// Node.js пример
const admin = require('firebase-admin');

admin.auth().setCustomUserClaims(uid, {
  role: 'CONTRACTOR_ADMIN',
  organizationId: 'org123',
  organization: 'Организация подрядчика'
});
```

### Получение Custom Claims в Flutter:

Для получения Custom Claims нужно декодировать JWT токен. Можно использовать пакет `jwt_decoder`:

```dart
import 'package:jwt_decoder/jwt_decoder.dart';

final idToken = await firebaseUser.getIdToken(true);
final decodedToken = JwtDecoder.decode(idToken);
final role = decodedToken['role'] as String? ?? 'CONTRACTOR_ADMIN';
```

## Преимущества:

✅ **Только Firebase** - нет зависимости от бэкенда
✅ **Простота** - вся авторизация через Firebase
✅ **Безопасность** - Firebase управляет аутентификацией
✅ **Работает на всех платформах** - Android, iOS, Web

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
7. User будет создан с ролью `CONTRACTOR_ADMIN`

## Примечания:

- Старые методы `sendSms` и `verifySms` остались для обратной совместимости (используют бэкенд)
- Метод `loginAkimat` (логин/пароль) также остался для обратной совместимости
- Для подрядчиков используется только `loginWithFirebasePhone`
- Роль `CONTRACTOR_ADMIN` установлена по умолчанию
- Для получения Custom Claims можно добавить декодирование JWT токена

