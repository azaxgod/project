# План реализации по требованиям API и документации

## 📋 Общая оценка

**Статус:** ⚠️ **Требуется значительная доработка** (~30-40% соответствия)

---

## 🔴 Критические несоответствия с API

### 1. Отсутствующие API endpoints для управления пользователями

**Требуемые endpoints (согласно документации):**

#### ❌ POST /roles/akimat/users - Создать сотрудника Акимата
```json
{
  "phone": "+77001234560",
  "login": "akimat.user1",
  "password": "Secret123"
}
```
**Доступ:** только `AKIMAT_ADMIN`  
**Роль:** `AKIMAT_USER`

#### ❌ GET /roles/akimat/users - Список сотрудников Акимата
**Доступ:** `AKIMAT_ADMIN`  
**Возвращает:** всех пользователей с ролью `AKIMAT_USER` текущего акимата

#### ❌ POST /roles/kgu/users - Создать сотрудника КГУ
```json
{
  "phone": "+77001234561",
  "login": "kgu.manager1",
  "password": "Secret123"
}
```
**Доступ:** только `KGU_ZKH_ADMIN`  
**Роль:** `KGU_ZKH_USER`

#### ❌ GET /roles/kgu/users - Список сотрудников КГУ
**Доступ:** `KGU_ZKH_ADMIN`  
**Возвращает:** всех `KGU_ZKH_USER` текущего КГУ

#### ❌ POST /roles/landfill/users - Создать сотрудника LANDFILL
```json
{
  "phone": "+77001234562",
  "login": "landfill.user1",
  "password": "Secret123"
}
```
**Доступ:** только `LANDFILL_ADMIN`  
**Роль:** `LANDFILL_USER`

#### ❌ GET /roles/landfill/users - Список сотрудников LANDFILL
**Доступ:** `LANDFILL_ADMIN`  
**Возвращает:** всех `LANDFILL_USER` текущего оператора

#### ❌ POST /roles/users - Создать сотрудника подрядчика
```json
{
  "phone": "+77001234563",
  "login": "contractor.user1",
  "password": "Secret123"
}
```
**Доступ:** только `CONTRACTOR_ADMIN`  
**Роль:** `CONTRACTOR_USER`

#### ❌ GET /roles/users - Список сотрудников подрядчика
**Доступ:** `CONTRACTOR_ADMIN`  
**Возвращает:** всех `CONTRACTOR_USER` текущего подрядчика

**Текущая реализация:**
- ✅ `POST /roles/drivers` - реализован
- ❌ Все остальные endpoints отсутствуют

**Файл для доработки:**
- `lib/services/organizations/collection/roles_collection.dart`

---

### 2. Отсутствующие роли

**Требуемые роли (согласно документации):**

| Роль | Текущая реализация | Статус |
|------|-------------------|--------|
| `AKIMAT_ADMIN` | ✅ `AKIMAT_ADMIN` | ✅ Есть |
| `AKIMAT_USER` | ❌ Отсутствует | ❌ Нужно добавить |
| `KGU_ZKH_ADMIN` | ✅ `KGU_ZKH_ADMIN` | ✅ Есть |
| `KGU_ZKH_USER` | ❌ Отсутствует | ❌ Нужно добавить |
| `LANDFILL_ADMIN` | ⚠️ `TOO_ADMIN` | ⚠️ Нужно переименовать |
| `LANDFILL_USER` | ❌ Отсутствует | ❌ Нужно добавить |
| `CONTRACTOR_ADMIN` | ✅ `CONTRACTOR_ADMIN` | ✅ Есть |
| `CONTRACTOR_USER` | ❌ Отсутствует | ❌ Нужно добавить |
| `DRIVER` | ✅ `DRIVER` | ✅ Есть |

**Файлы для доработки:**
- `lib/modules/dashboard/src/model/organizations/user_role.dart`
- `lib/services/auth/model/user.dart`
- Все места, где используется `userRoleFromString`

---

### 3. API для создания организаций

**Требуемый формат (согласно документации):**

```json
POST /roles/organizations
{
  "name": "TOO Snow Demo",
  "type": "CONTRACTOR", // или "KGU_ZKH", "LANDFILL" (принимается также "TOO")
  "bin": "123456789012",
  "head_full_name": "Иван Иванов",
  "address": "Астана",
  "phone": "+77001234567",
  "admin_full_name": "Администратор",
  "admin_phone": "+77001234568",
  "admin_login": "snow.demo",        // опционально
  "admin_password": "Secret123!"     // опционально
}
```

**Ответ:**
```json
{
  "organization": { ... },
  "admin": {
    "id": "...",
    "login": "too_snow_demo",
    "generatedPassword": "X1yZ..."
  }
}
```

**Текущая реализация:**
- ✅ `POST /roles/organizations` - реализован
- ⚠️ Формат запроса частично соответствует (нужно проверить поля `admin_login`, `admin_password`)
- ⚠️ Нужно обработать ответ с `generatedPassword`

**Файл для проверки:**
- `lib/services/organizations/collection/roles_collection.dart:151-193`

---

## 🟡 Отсутствующие UI экраны

### 1. Управление пользователями Акимата

**Требования:**
- Экран "Пользователи Акимата" (только для `AKIMAT_ADMIN`)
- Таблица: ФИО, телефон, логин, роль (`AKIMAT_USER`), статус
- Кнопка "Создать пользователя"
- Действия: изменить данные, сбросить пароль, заблокировать

**Текущая реализация:**
- ❌ Экран отсутствует

**Нужно создать:**
- `lib/modules/dashboard/src/ui/screen/akimat_users/akimat_users_page.dart`
- `lib/modules/dashboard/src/controller/akimat_users_controller.dart`

---

### 2. Управление пользователями КГУ

**Требования:**
- Экран "Пользователи КГУ" (только для `KGU_ZKH_ADMIN`)
- Таблица: телефон, логин, роль (`KGU_ZKH_USER`), статус
- Кнопка "Создать пользователя"
- Действия: редактирование, блокировка, сброс пароля

**Текущая реализация:**
- ❌ Экран отсутствует

**Нужно создать:**
- `lib/modules/dashboard/src/ui/screen/kgu_users/kgu_users_page.dart`
- `lib/modules/dashboard/src/controller/kgu_users_controller.dart`

---

### 3. Управление пользователями LANDFILL

**Требования:**
- Экран "Пользователи" (только для `LANDFILL_ADMIN`)
- Таблица: ФИО, телефон, логин, роль (`LANDFILL_USER`), статус
- Кнопка "Создать пользователя"
- Действия: редактирование, блокировка, сброс пароля

**Текущая реализация:**
- ❌ Экран отсутствует

**Нужно создать:**
- `lib/modules/dashboard/src/ui/screen/landfill_users/landfill_users_page.dart`
- `lib/modules/dashboard/src/controller/landfill_users_controller.dart`

---

### 4. Управление пользователями подрядчика

**Требования:**
- Экран "Пользователи" (только для `CONTRACTOR_ADMIN`)
- Таблица: телефон, логин, роль (`CONTRACTOR_USER`), статус
- Кнопка "Создать пользователя"
- Действия: редактирование, блокировка, сброс пароля

**Текущая реализация:**
- ❌ Экран отсутствует

**Нужно создать:**
- `lib/modules/dashboard/src/ui/screen/contractor_users/contractor_users_page.dart`
- `lib/modules/dashboard/src/controller/contractor_users_controller.dart`

---

## 📝 План реализации

### Этап 1: Обновление ролей и типов организаций

#### 1.1. Добавить недостающие роли

**Файл:** `lib/modules/dashboard/src/model/organizations/user_role.dart`

```dart
enum UserRole {
  akimatAdmin,      // AKIMAT_ADMIN
  akimatUser,       // AKIMAT_USER - НОВОЕ
  kguZkhAdmin,      // KGU_ZKH_ADMIN
  kguZkhUser,       // KGU_ZKH_USER - НОВОЕ
  landfillAdmin,   // LANDFILL_ADMIN (переименовать из tooAdmin)
  landfillUser,    // LANDFILL_USER - НОВОЕ
  contractorAdmin, // CONTRACTOR_ADMIN
  contractorUser,  // CONTRACTOR_USER - НОВОЕ
  driver,          // DRIVER
  unknown,
}
```

#### 1.2. Обновить маппинг ролей

```dart
UserRole userRoleFromString(String? role) {
  switch (role) {
    case 'AKIMAT_ADMIN':
      return UserRole.akimatAdmin;
    case 'AKIMAT_USER':  // НОВОЕ
      return UserRole.akimatUser;
    case 'KGU_ZKH_ADMIN':
      return UserRole.kguZkhAdmin;
    case 'KGU_ZKH_USER':  // НОВОЕ
      return UserRole.kguZkhUser;
    case 'LANDFILL_ADMIN':  // НОВОЕ (вместо TOO_ADMIN)
    case 'TOO_ADMIN':  // Поддержка старого значения
      return UserRole.landfillAdmin;
    case 'LANDFILL_USER':  // НОВОЕ
      return UserRole.landfillUser;
    case 'CONTRACTOR_ADMIN':
      return UserRole.contractorAdmin;
    case 'CONTRACTOR_USER':  // НОВОЕ
      return UserRole.contractorUser;
    case 'DRIVER':
      return UserRole.driver;
    default:
      return UserRole.unknown;
  }
}
```

#### 1.3. Обновить тип организации

**Файл:** `lib/modules/dashboard/src/model/organizations/organization_type.dart`

```dart
enum OrganizationType {
  akimat,
  kguZkh,
  landfill,  // Переименовать из too
  contractor,
}
```

**Важно:** Поддержать оба значения `LANDFILL` и `TOO` при парсинге.

---

### Этап 2: Реализация API endpoints

#### 2.1. Добавить методы в RolesCollection

**Файл:** `lib/services/organizations/collection/roles_collection.dart`

```dart
// ==================== Akimat Users ====================

/// POST /roles/akimat/users - Создать сотрудника Акимата
Future<UserDto> createAkimatUser({
  required String phone,
  required String login,
  required String password,
}) async {
  try {
    final response = await dio.post(
      '/roles/akimat/users',
      data: {
        'phone': phone,
        'login': login,
        'password': password,
      },
    );
    return UserDto.fromJson(
        response.data['user'] as Map<String, dynamic>);
  } on DioException catch (e) {
    _handleError(e);
    rethrow;
  }
}

/// GET /roles/akimat/users - Список сотрудников Акимата
Future<List<UserDto>> getAkimatUsers() async {
  try {
    final response = await dio.get('/roles/akimat/users');
    final List<dynamic> users = response.data['users'] ?? [];
    return users
        .map((json) => UserDto.fromJson(json as Map<String, dynamic>))
        .toList();
  } on DioException catch (e) {
    _handleError(e);
    rethrow;
  }
}

// ==================== KGU Users ====================

/// POST /roles/kgu/users - Создать сотрудника КГУ
Future<UserDto> createKguUser({
  required String phone,
  required String login,
  required String password,
}) async {
  try {
    final response = await dio.post(
      '/roles/kgu/users',
      data: {
        'phone': phone,
        'login': login,
        'password': password,
      },
    );
    return UserDto.fromJson(
        response.data['user'] as Map<String, dynamic>);
  } on DioException catch (e) {
    _handleError(e);
    rethrow;
  }
}

/// GET /roles/kgu/users - Список сотрудников КГУ
Future<List<UserDto>> getKguUsers() async {
  try {
    final response = await dio.get('/roles/kgu/users');
    final List<dynamic> users = response.data['users'] ?? [];
    return users
        .map((json) => UserDto.fromJson(json as Map<String, dynamic>))
        .toList();
  } on DioException catch (e) {
    _handleError(e);
    rethrow;
  }
}

// ==================== LANDFILL Users ====================

/// POST /roles/landfill/users - Создать сотрудника LANDFILL
Future<UserDto> createLandfillUser({
  required String phone,
  required String login,
  required String password,
}) async {
  try {
    final response = await dio.post(
      '/roles/landfill/users',
      data: {
        'phone': phone,
        'login': login,
        'password': password,
      },
    );
    return UserDto.fromJson(
        response.data['user'] as Map<String, dynamic>);
  } on DioException catch (e) {
    _handleError(e);
    rethrow;
  }
}

/// GET /roles/landfill/users - Список сотрудников LANDFILL
Future<List<UserDto>> getLandfillUsers() async {
  try {
    final response = await dio.get('/roles/landfill/users');
    final List<dynamic> users = response.data['users'] ?? [];
    return users
        .map((json) => UserDto.fromJson(json as Map<String, dynamic>))
        .toList();
  } on DioException catch (e) {
    _handleError(e);
    rethrow;
  }
}

// ==================== Contractor Users ====================

/// POST /roles/users - Создать сотрудника подрядчика
Future<UserDto> createContractorUser({
  required String phone,
  required String login,
  required String password,
}) async {
  try {
    final response = await dio.post(
      '/roles/users',
      data: {
        'phone': phone,
        'login': login,
        'password': password,
      },
    );
    return UserDto.fromJson(
        response.data['user'] as Map<String, dynamic>);
  } on DioException catch (e) {
    _handleError(e);
    rethrow;
  }
}

/// GET /roles/users - Список сотрудников подрядчика
Future<List<UserDto>> getContractorUsers() async {
  try {
    final response = await dio.get('/roles/users');
    final List<dynamic> users = response.data['users'] ?? [];
    return users
        .map((json) => UserDto.fromJson(json as Map<String, dynamic>))
        .toList();
  } on DioException catch (e) {
    _handleError(e);
    rethrow;
  }
}
```

---

### Этап 3: Создание UI экранов

#### 3.1. Экран "Пользователи Акимата"

**Структура:**
```
lib/modules/dashboard/src/ui/screen/akimat_users/
  ├── akimat_users_page.dart
  ├── widgets/
  │   ├── akimat_users_table.dart
  │   └── create_akimat_user_dialog.dart
  └── controller/
      └── akimat_users_controller.dart
```

**Функциональность:**
- Таблица с пользователями `AKIMAT_USER`
- Кнопка "Создать пользователя"
- Действия: редактирование, блокировка, сброс пароля
- Доступ: только `AKIMAT_ADMIN`

#### 3.2. Экран "Пользователи КГУ"

**Структура:**
```
lib/modules/dashboard/src/ui/screen/kgu_users/
  ├── kgu_users_page.dart
  ├── widgets/
  │   ├── kgu_users_table.dart
  │   └── create_kgu_user_dialog.dart
  └── controller/
      └── kgu_users_controller.dart
```

#### 3.3. Экран "Пользователи LANDFILL"

**Структура:**
```
lib/modules/dashboard/src/ui/screen/landfill_users/
  ├── landfill_users_page.dart
  ├── widgets/
  │   ├── landfill_users_table.dart
  │   └── create_landfill_user_dialog.dart
  └── controller/
      └── landfill_users_controller.dart
```

#### 3.4. Экран "Пользователи подрядчика"

**Структура:**
```
lib/modules/dashboard/src/ui/screen/contractor_users/
  ├── contractor_users_page.dart
  ├── widgets/
  │   ├── contractor_users_table.dart
  │   └── create_contractor_user_dialog.dart
  └── controller/
      └── contractor_users_controller.dart
```

---

### Этап 4: Обновление навигации

#### 4.1. Добавить пункты меню

**Для AKIMAT_ADMIN:**
- Главная
- Организационная структура
- **Пользователи Акимата** ← НОВОЕ
- KGU ЖКХ
- Мониторинг
- Аналитика

**Для KGU_ZKH_ADMIN:**
- Главная
- Подрядчики
- Организации приёма снега
- Полигоны
- Контракты
- Акты
- Мониторинг
- Аналитика
- **Пользователи КГУ** ← НОВОЕ

**Для LANDFILL_ADMIN:**
- Главная
- Мои полигоны
- Камеры
- Журнал приёма снега
- Акты с КГУ
- **Пользователи** ← НОВОЕ

**Для CONTRACTOR_ADMIN:**
- Главная
- Участки уборки
- Водители
- Техника
- Тикеты и рейсы
- Мониторинг
- Акты
- Аналитика
- **Пользователи** ← НОВОЕ

---

## 🔧 Технические детали

### Модель UserDto

**Файл:** `lib/services/organizations/model/user_dto.dart`

Убедиться, что модель поддерживает:
- `id`
- `phone`
- `login`
- `role`
- `organizationId`
- `isActive`
- `generatedPassword` (для ответов API)

### Обработка generatedPassword

При создании организации или водителя API может вернуть `generatedPassword`. Нужно:
1. Показать пользователю сгенерированный пароль
2. Сохранить его для передачи пользователю
3. Предложить скопировать пароль

---

## 📊 Приоритеты реализации

### Приоритет 1 (Критично) - Неделя 1-2

1. ✅ Добавить недостающие роли в `user_role.dart`
2. ✅ Реализовать API endpoints для создания пользователей
3. ✅ Создать экран "Пользователи Акимата"
4. ✅ Создать экран "Пользователи КГУ"

### Приоритет 2 (Важно) - Неделя 3-4

5. ✅ Создать экран "Пользователи LANDFILL"
6. ✅ Создать экран "Пользователи подрядчика"
7. ✅ Обновить навигацию для всех ролей
8. ✅ Добавить обработку `generatedPassword`

### Приоритет 3 (Желательно) - Неделя 5+

9. ✅ Переименовать `TOO` → `LANDFILL` (с поддержкой старого значения)
10. ✅ Добавить валидацию прав доступа
11. ✅ Добавить логирование действий
12. ✅ Улучшить UX (сообщения об успехе/ошибках)

---

## 🔗 Связанные файлы

### Модели
- `lib/modules/dashboard/src/model/organizations/user_role.dart`
- `lib/modules/dashboard/src/model/organizations/organization_type.dart`
- `lib/services/organizations/model/user_dto.dart`

### API
- `lib/services/organizations/collection/roles_collection.dart`

### UI (нужно создать)
- `lib/modules/dashboard/src/ui/screen/akimat_users/`
- `lib/modules/dashboard/src/ui/screen/kgu_users/`
- `lib/modules/dashboard/src/ui/screen/landfill_users/`
- `lib/modules/dashboard/src/ui/screen/contractor_users/`

### Навигация
- `lib/core/routes/app_routes.dart`
- `lib/core/navbar/drawer_mobile.dart`
- `lib/core/navbar/navbar_widgets_provider.dart`

---

## ✅ Чеклист реализации

- [ ] Обновить enum UserRole
- [ ] Обновить userRoleFromString
- [ ] Добавить API методы для создания пользователей Акимата
- [ ] Добавить API методы для создания пользователей КГУ
- [ ] Добавить API методы для создания пользователей LANDFILL
- [ ] Добавить API методы для создания пользователей подрядчика
- [ ] Создать экран "Пользователи Акимата"
- [ ] Создать экран "Пользователи КГУ"
- [ ] Создать экран "Пользователи LANDFILL"
- [ ] Создать экран "Пользователи подрядчика"
- [ ] Обновить навигацию
- [ ] Добавить обработку generatedPassword
- [ ] Протестировать все сценарии





