import 'package:akimat_project/services/organizations/model/driver_dto.dart';
import 'package:akimat_project/services/organizations/model/organization_dto.dart';
import 'package:akimat_project/services/organizations/model/user_dto.dart';
import 'package:akimat_project/services/organizations/model/vehicle_dto.dart';
import 'package:dio/dio.dart';

/// Результат создания организации
class CreateOrganizationResult {
  final OrganizationDto organization;
  final UserDto? admin;

  CreateOrganizationResult({
    required this.organization,
    this.admin,
  });
}

/// Результат создания водителя
class CreateDriverResult {
  final DriverDto driver;
  final UserDto? user;

  CreateDriverResult({
    required this.driver,
    this.user,
  });
}

/// Ошибки Roles Service
class RolesException implements Exception {
  final String message;
  final int? statusCode;

  RolesException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class RolesCollection {
  final Dio dio;

  RolesCollection({required this.dio});

  /// Обработка ошибок API
  void _handleError(DioException error) {
    if (error.response != null) {
      final statusCode = error.response!.statusCode;
      final errorData = error.response!.data;
      final errorMessage = errorData is Map && errorData.containsKey('error')
          ? errorData['error'] as String
          : error.message ?? 'Unknown error';

      switch (statusCode) {
        case 400:
          throw RolesException(errorMessage, 400);
        case 401:
          throw RolesException(errorMessage, 401);
        case 403:
          throw RolesException(errorMessage, 403);
        case 404:
          throw RolesException(errorMessage, 404);
        case 500:
        case 502:
        case 503:
        case 504:
          throw RolesException('Сервер временно недоступен. Попробуйте позже.', statusCode);
        default:
          throw RolesException(errorMessage, statusCode);
      }
    } else {
      // Обработка ошибок подключения (network errors)
      String errorMessage;
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
          errorMessage = 'Превышено время ожидания подключения. Проверьте интернет-соединение.';
          break;
        case DioExceptionType.sendTimeout:
          errorMessage = 'Превышено время отправки данных. Попробуйте снова.';
          break;
        case DioExceptionType.receiveTimeout:
          errorMessage = 'Превышено время получения данных. Попробуйте снова.';
          break;
        case DioExceptionType.badCertificate:
          errorMessage = 'Ошибка сертификата. Обратитесь в поддержку.';
          break;
        case DioExceptionType.badResponse:
          errorMessage = 'Некорректный ответ от сервера.';
          break;
        case DioExceptionType.cancel:
          errorMessage = 'Запрос отменён.';
          break;
        case DioExceptionType.connectionError:
          errorMessage = 'Ошибка подключения. Проверьте интернет-соединение и попробуйте снова.';
          break;
        case DioExceptionType.unknown:
        default:
          final message = error.message ?? 'Неизвестная ошибка';
          if (message.contains('Failed host lookup') || 
              message.contains('failed host lookup') ||
              message.contains('getaddrinfo failed')) {
            errorMessage = 'Не удалось подключиться к серверу. Проверьте интернет-соединение и попробуйте снова.';
          } else {
            errorMessage = message;
          }
          break;
      }
      throw RolesException(errorMessage, null);
    }
  }

  // ==================== Organizations ====================

  /// GET /roles/organizations - Получить список организаций
  Future<List<OrganizationDto>> getOrganizations() async {
    try {
      final response = await dio.get('/roles/organizations');
      // Проверяем формат ответа - может быть обернут в {"data": ...} или прямой массив
      final responseData = response.data;
      List<dynamic> organizations;
      
      if (responseData is Map<String, dynamic>) {
        // Если ответ обернут в {"data": ...}
        if (responseData.containsKey('data')) {
          final data = responseData['data'];
          if (data is Map && data.containsKey('organizations')) {
            organizations = data['organizations'] as List<dynamic>? ?? [];
          } else if (data is List) {
            organizations = data;
          } else {
            organizations = responseData['organizations'] as List<dynamic>? ?? [];
          }
        } else {
          organizations = responseData['organizations'] as List<dynamic>? ?? [];
        }
      } else if (responseData is List) {
        organizations = responseData;
      } else {
        organizations = [];
      }
      
      return organizations
          .map((json) => OrganizationDto.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// POST /roles/organizations - Создать организацию и администратора
  Future<CreateOrganizationResult> createOrganization({
    required String name,
    required String type,
    String? bin,
    String? headFullName,
    String? address,
    String? phone,
    String? parentOrgId,
    String? adminFullName,
    required String adminPhone,
    String? adminPassword,
  }) async {
    try {
      final response = await dio.post(
        '/roles/organizations',
        data: {
          'name': name,
          'type': type,
          if (bin != null) 'bin': bin,
          if (headFullName != null) 'headFullName': headFullName,
          if (address != null) 'address': address,
          if (phone != null) 'phone': phone,
          if (parentOrgId != null) 'parentOrgID': parentOrgId,
          if (adminFullName != null) 'adminFullName': adminFullName,
          'admin_phone': adminPhone, // API ожидает snake_case
          if (adminPassword != null) 'adminPassword': adminPassword,
        },
      );
      final data = response.data as Map<String, dynamic>;
      return CreateOrganizationResult(
        organization: OrganizationDto.fromJson(
          data['organization'] as Map<String, dynamic>,
        ),
        admin: data['admin'] != null
            ? UserDto.fromJson(data['admin'] as Map<String, dynamic>)
            : null,
      );
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// GET /roles/organizations/:id - Получить организацию по ID
  Future<OrganizationDto> getOrganization(String id) async {
    try {
      final response = await dio.get('/roles/organizations/$id');
      return OrganizationDto.fromJson(
          response.data['organization'] as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// PUT /roles/organizations/:id - Обновить организацию
  Future<OrganizationDto> updateOrganization(
    String id, {
    String? name,
    String? type,
    String? bin,
    String? headFullName,
    String? address,
    String? phone,
    bool? isActive,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) {
        data['name'] = name;
      }
      if (type != null) {
        data['type'] = type;
      }
      if (bin != null) {
        data['bin'] = bin;
      }
      if (headFullName != null) {
        data['head_full_name'] = headFullName;
      }
      if (address != null) {
        data['address'] = address;
      }
      if (phone != null) {
        data['phone'] = phone;
      }
      if (isActive != null) {
        data['is_active'] = isActive;
      }

      final response = await dio.put('/roles/organizations/$id', data: data);
      return OrganizationDto.fromJson(
          response.data['organization'] as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// DELETE /roles/organizations/:id - Удалить организацию
  Future<void> deleteOrganization(String id) async {
    try {
      await dio.delete('/roles/organizations/$id');
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // ==================== Users ====================

  // ==================== Akimat Users ====================

  /// POST /roles/akimat/users - Создать сотрудника Акимата
  /// Доступ: только AKIMAT_ADMIN
  /// Роль: AKIMAT_USER
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
  /// Доступ: AKIMAT_ADMIN
  /// Возвращает: всех пользователей с ролью AKIMAT_USER текущего акимата
  Future<List<UserDto>> getAkimatUsers() async {
    try {
      final response = await dio.get('/roles/akimat/users');
      final usersData = response.data;
      
      // Обработка разных форматов ответа
      // API может возвращать: массив пользователей напрямую или объект с полем users
      List<dynamic> users;
      if (usersData is List) {
        users = usersData;
      } else if (usersData is Map) {
        // Проверяем различные возможные ключи
        if (usersData['users'] != null) {
        users = usersData['users'] as List<dynamic>? ?? [];
        } else if (usersData['data'] != null) {
          users = usersData['data'] as List<dynamic>? ?? [];
        } else {
          users = [];
        }
      } else {
        users = [];
      }
      
      return users
          .where((json) => json != null)
          .map((json) {
            try {
              // Убеждаемся, что json - это Map
              if (json is! Map<String, dynamic>) {
                return null;
              }
              return UserDto.fromJson(json);
            } catch (e) {
              // Логируем ошибку парсинга, но продолжаем обработку остальных пользователей
              print('Error parsing user: $e, data: $json');
              return null;
            }
          })
          .whereType<UserDto>()
          .toList();
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // ==================== KGU Users ====================

  /// POST /roles/kgu/users - Создать сотрудника КГУ
  /// Доступ: только KGU_ZKH_ADMIN
  /// Роль: KGU_ZKH_USER
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
  /// Доступ: KGU_ZKH_ADMIN
  /// Возвращает: всех KGU_ZKH_USER текущего КГУ
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
  /// Доступ: только LANDFILL_ADMIN
  /// Роль: LANDFILL_USER
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
  /// Доступ: LANDFILL_ADMIN
  /// Возвращает: всех LANDFILL_USER текущего оператора
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
  /// Доступ: только CONTRACTOR_ADMIN
  /// Роль: CONTRACTOR_USER
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
  /// Доступ: CONTRACTOR_ADMIN
  /// Возвращает: всех CONTRACTOR_USER текущего подрядчика
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

  // ==================== Generic User Operations ====================

  /// GET /roles/users?phone=...&login=... - Найти пользователя
  Future<UserDto?> findUser({String? phone, String? login}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (phone != null) {
        queryParams['phone'] = phone;
      }
      if (login != null) {
        queryParams['login'] = login;
      }

      final response = await dio.get(
        '/roles/users',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );
      final userData = response.data['user'];
      if (userData == null) {
        return null;
      }
      return UserDto.fromJson(userData as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      _handleError(e);
      rethrow;
    }
  }

  /// GET /roles/users/:id - Получить пользователя по ID
  Future<UserDto> getUser(String id) async {
    try {
      // Валидация и нормализация ID
      final normalizedId = id.trim();
      if (normalizedId.isEmpty) {
        throw RolesException('ID пользователя не может быть пустым', 400);
      }
      
      final response = await dio.get('/roles/users/$normalizedId');
      
      // Обработка разных форматов ответа
      Map<String, dynamic> userData;
      if (response.data is Map) {
        if (response.data.containsKey('user')) {
          userData = response.data['user'] as Map<String, dynamic>;
        } else {
          // Если ответ - это сам объект пользователя
          userData = response.data as Map<String, dynamic>;
        }
      } else {
        throw RolesException('Некорректный формат ответа от сервера', 500);
      }
      
      return UserDto.fromJson(userData);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        final errorData = e.response?.data;
        final errorMessage = errorData is Map && errorData.containsKey('error')
            ? errorData['error'] as String
            : 'Пользователь не найден';
        throw RolesException(errorMessage, 404);
      }
      _handleError(e);
      rethrow;
    }
  }

  /// PUT /roles/users/:id - Обновить пользователя
  /// Поддерживает блокировку с причиной:
  /// - is_active: false + block_reason - блокировка с причиной
  /// - is_active: true - разблокировка (block_reason автоматически очищается)
  Future<UserDto> updateUser(
    String id, {
    String? phone,
    String? login,
    String? password,
    String? role,
    String? organizationId,
    String? driverId,
    bool? isActive,
    String? blockReason,
  }) async {
    try {
      // Валидация и нормализация ID
      final normalizedId = id.trim();
      if (normalizedId.isEmpty) {
        throw RolesException('ID пользователя не может быть пустым', 400);
      }

      final data = <String, dynamic>{};
      if (phone != null) {
        data['phone'] = phone;
      }
      if (login != null) {
        data['login'] = login;
      }
      if (password != null) {
        data['password'] = password;
      }
      if (role != null) {
        data['role'] = role;
      }
      if (organizationId != null) {
        data['organization_id'] = organizationId;
      }
      if (driverId != null) {
        data['driver_id'] = driverId;
      }
      if (isActive != null) {
        data['is_active'] = isActive;
      }
      // Если blockReason явно передан (включая null), отправляем его
      // Это нужно для явной очистки block_reason при разблокировке
      if (blockReason != null || (isActive == true && blockReason == null)) {
        // Если разблокируем (isActive == true), явно очищаем block_reason
        data['block_reason'] = blockReason;
      }

      // Убеждаемся, что endpoint правильно сформирован
      final endpoint = '/roles/users/$normalizedId';
      final response = await dio.put(endpoint, data: data);
      
      // Обработка разных форматов ответа
      Map<String, dynamic> userData;
      if (response.data is Map) {
        if (response.data.containsKey('user')) {
          userData = response.data['user'] as Map<String, dynamic>;
        } else {
          // Если ответ - это сам объект пользователя
          userData = response.data as Map<String, dynamic>;
        }
      } else {
        throw RolesException('Некорректный формат ответа от сервера', 500);
      }
      
      return UserDto.fromJson(userData);
    } on DioException catch (e) {
      // Специальная обработка для 404 ошибки
      if (e.response?.statusCode == 404) {
        final errorData = e.response?.data;
        final errorMessage = errorData is Map && errorData.containsKey('error')
            ? errorData['error'] as String
            : 'Пользователь не найден';
        throw RolesException(errorMessage, 404);
      }
      _handleError(e);
      rethrow;
    }
  }

  /// Блокировать пользователя с причиной
  /// Определяет правильный endpoint на основе роли пользователя
  Future<UserDto> blockUser(
    String id, {
    String? blockReason,
    String? userRole,
  }) async {
    // Если роль не указана, получаем пользователя для определения роли
    String? role = userRole;
    if (role == null) {
      try {
        final user = await getUser(id);
        role = user.role;
      } catch (e) {
        // Если не удалось получить пользователя, используем общий endpoint
    return updateUser(
      id,
      isActive: false,
      blockReason: blockReason,
    );
  }
    }
    
    // Для PUT запросов всегда используем общий endpoint /roles/users/:id
    // Специфичные endpoints (/roles/akimat/users, /roles/kgu/users) используются только для GET и POST
    // PUT запросы для обновления пользователей идут через общий endpoint
    return updateUser(
      id,
      isActive: false,
      blockReason: blockReason,
    );
  }

  /// Разблокировать пользователя
  /// При разблокировке block_reason автоматически очищается на бэкенде
  /// Определяет правильный endpoint на основе роли пользователя
  Future<UserDto> unblockUser(String id, {String? userRole}) async {
    try {
      // Валидация и нормализация ID
      final normalizedId = id.trim();
      if (normalizedId.isEmpty) {
        throw RolesException('ID пользователя не может быть пустым', 400);
      }
      
      // Сначала получаем пользователя, чтобы убедиться, что он существует
      // и получить его роль для определения правильного endpoint
      UserDto existingUser;
      try {
        existingUser = await getUser(normalizedId);
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          throw RolesException('Пользователь не найден. Возможно, он был удален или ID изменился. Обновите список.', 404);
        }
        // Если другая ошибка, пробрасываем её
        rethrow;
      }
      
      // Для PUT запросов всегда используем общий endpoint /roles/users/:id
      // Специфичные endpoints (/roles/akimat/users, /roles/kgu/users) используются только для GET и POST
      // PUT запросы для обновления пользователей идут через общий endpoint
      final endpoint = '/roles/users/$normalizedId';
      
      // При разблокировке отправляем только is_active: true
      // Не отправляем block_reason, бэкенд должен автоматически очистить его
      // Некоторые API не принимают null значения, поэтому отправляем только нужные поля
      final data = <String, dynamic>{
        'is_active': true,
      };
      
      // Логируем для отладки
      final role = userRole ?? existingUser.role;
      print('Unblocking user: ID=$normalizedId, role=$role, endpoint=$endpoint, data=$data');
      print('Existing user: ${existingUser.id}, isActive: ${existingUser.isActive}, role: ${existingUser.role}');
      
      final response = await dio.put(endpoint, data: data);
      
      // Обработка разных форматов ответа
      Map<String, dynamic> userData;
      if (response.data is Map) {
        if (response.data.containsKey('user')) {
          userData = response.data['user'] as Map<String, dynamic>;
        } else {
          // Если ответ - это сам объект пользователя
          userData = response.data as Map<String, dynamic>;
        }
      } else {
        throw RolesException('Некорректный формат ответа от сервера', 500);
      }
      
      return UserDto.fromJson(userData);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        final errorData = e.response?.data;
        final errorMessage = errorData is Map && errorData.containsKey('error')
            ? errorData['error'] as String
            : 'Пользователь не найден';
        throw RolesException('$errorMessage. ID: $id. Обновите список и попробуйте снова.', 404);
      }
      _handleError(e);
      rethrow;
    } on RolesException {
      // Пробрасываем RolesException как есть
      rethrow;
    } catch (e) {
      throw RolesException('Ошибка при разблокировке пользователя: ${e.toString()}', null);
    }
  }

  // ==================== Drivers ====================

  /// GET /roles/drivers - Получить список водителей
  Future<List<DriverDto>> getDrivers() async {
    try {
      final response = await dio.get('/roles/drivers');
      final List<dynamic> drivers = response.data['drivers'] ?? [];
      return drivers
          .map((json) => DriverDto.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// POST /roles/drivers - Создать водителя и пользователя
  Future<CreateDriverResult> createDriver({
    required String fullName,
    required String iin,
    required int birthYear,
    required String phone,
  }) async {
    try {
      final response = await dio.post(
        '/roles/drivers',
        data: {
          'fullName': fullName,
          'iin': iin,
          'birthYear': birthYear,
          'phone': phone,
        },
      );
      final data = response.data as Map<String, dynamic>;
      return CreateDriverResult(
        driver: DriverDto.fromJson(data['driver'] as Map<String, dynamic>),
        user: data['user'] != null
            ? UserDto.fromJson(data['user'] as Map<String, dynamic>)
            : null,
      );
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// GET /roles/drivers/:id - Получить водителя по ID
  Future<DriverDto> getDriver(String id) async {
    try {
      final response = await dio.get('/roles/drivers/$id');
      return DriverDto.fromJson(
          response.data['driver'] as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// PUT /roles/drivers/:id - Обновить водителя
  Future<DriverDto> updateDriver(
    String id, {
    String? fullName,
    String? phone,
    int? birthYear,
    String? iin,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (fullName != null) {
        data['fullName'] = fullName;
      }
      if (phone != null) {
        data['phone'] = phone;
      }
      if (birthYear != null) {
        data['birthYear'] = birthYear;
      }
      if (iin != null) {
        data['iin'] = iin;
      }

      final response = await dio.put('/roles/drivers/$id', data: data);
      return DriverDto.fromJson(
          response.data['driver'] as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// DELETE /roles/drivers/:id - Удалить водителя
  Future<void> deleteDriver(String id) async {
    try {
      await dio.delete('/roles/drivers/$id');
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // ==================== Vehicles ====================

  /// GET /roles/vehicles?only_active=true - Получить список транспорта
  Future<List<VehicleDto>> getVehicles({bool? onlyActive}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (onlyActive != null) {
        queryParams['only_active'] = onlyActive;
      }

      final response = await dio.get(
        '/roles/vehicles',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );
      
      // API может возвращать данные в формате {vehicles: [...]} или просто массив
      final List<dynamic> vehicles;
      if (response.data is Map) {
        vehicles = response.data['vehicles'] ?? response.data['vehicle'] ?? [];
      } else if (response.data is List) {
        vehicles = response.data;
      } else {
        vehicles = [];
      }
      
      return vehicles
          .map((json) => VehicleDto.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// POST /roles/vehicles - Создать транспорт
  Future<VehicleDto> createVehicle({
    required String plateNumber,
    required String brand,
    required String model,
    required String color,
    required int year,
    required double bodyVolumeM3,
    String? photoUrl,
    String? driverId,
  }) async {
    try {
      final response = await dio.post(
        '/roles/vehicles',
        data: {
          'plate_number': plateNumber,
          'brand': brand,
          'model': model,
          'color': color,
          'year': year,
          'body_volume_m3': bodyVolumeM3,
          if (photoUrl != null) 'photo_url': photoUrl,
          if (driverId != null) 'driver_id': driverId,
        },
      );
      return VehicleDto.fromJson(
          response.data['vehicle'] as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// GET /roles/vehicles/:id - Получить транспорт по ID
  Future<VehicleDto> getVehicle(String id) async {
    try {
      final response = await dio.get('/roles/vehicles/$id');
      return VehicleDto.fromJson(
          response.data['vehicle'] as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// PATCH /roles/vehicles/:id - Обновить транспорт
  Future<VehicleDto> updateVehicle(
    String id, {
    String? color,
    double? bodyVolumeM3,
    String? driverId, // пустая строка для отвязки
  }) async {
    try {
      final data = <String, dynamic>{};
      if (color != null) {
        data['color'] = color;
      }
      if (bodyVolumeM3 != null) {
        data['body_volume_m3'] = bodyVolumeM3;
      }
      if (driverId != null) {
        data['driver_id'] = driverId;
      }

      final response = await dio.patch('/roles/vehicles/$id', data: data);
      return VehicleDto.fromJson(
          response.data['vehicle'] as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// DELETE /roles/vehicles/:id - Удалить транспорт
  Future<void> deleteVehicle(String id) async {
    try {
      await dio.delete('/roles/vehicles/$id');
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }
}

