import 'package:akimat_project/services/auth/model/user.dart';
import 'package:akimat_project/services/auth/model/send_code_response.dart';
import 'package:akimat_project/services/auth/model/logout_response.dart';
import 'package:dio/dio.dart';
import '../model/auth_response.dart';

/// Ошибки авторизации
class AuthException implements Exception {
  final String message;
  final int? statusCode;
  
  AuthException(this.message, [this.statusCode]);
  
  @override
  String toString() => message;
}

class AuthCollection {
  final Dio dio;
  String? _tempToken;
  AuthCollection({required this.dio});

  void setTempToken(String token) {
    _tempToken = token;
  }

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
          throw AuthException(errorMessage, 400);
        case 401:
          throw AuthException(errorMessage, 401);
        case 403:
          throw AuthException(errorMessage, 403);
        case 404:
          throw AuthException(errorMessage, 404);
        case 409:
          throw AuthException(errorMessage, 409);
        default:
          throw AuthException(errorMessage, statusCode);
      }
    } else {
      // Обработка ошибок подключения (network errors)
      String errorMessage;
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
          errorMessage = 'Connection timeout. Please check your internet connection.';
          break;
        case DioExceptionType.sendTimeout:
          errorMessage = 'Send timeout. Please try again.';
          break;
        case DioExceptionType.receiveTimeout:
          errorMessage = 'Receive timeout. Please try again.';
          break;
        case DioExceptionType.badCertificate:
          errorMessage = 'Certificate error. Please contact support.';
          break;
        case DioExceptionType.badResponse:
          errorMessage = 'Bad response from server.';
          break;
        case DioExceptionType.cancel:
          errorMessage = 'Request cancelled.';
          break;
        case DioExceptionType.connectionError:
          errorMessage = 'Connection error. Please check your internet connection and try again.';
          break;
        case DioExceptionType.unknown:
        default:
          final message = error.message ?? 'Unknown error';
          if (message.contains('Failed host lookup') || 
              message.contains('failed host lookup') ||
              message.contains('getaddrinfo failed')) {
            errorMessage = 'Cannot connect to server. Please check your internet connection and try again.';
          } else {
            errorMessage = message;
          }
          break;
      }
      throw AuthException(errorMessage, null);
    }
  }

  /// POST /auth/login
  /// Авторизация по логину/паролю.
  /// Ответ оборачивается в {"data": ...}
  Future<AuthResponse> login(String login, String password) async {
    try {
      final response = await dio.post('/auth/login', data: {
        'login': login,
        'password': password,
      });
      // Ответ оборачивается в {"data": ...}
      return AuthResponse.fromJson(response.data['data']);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// POST /auth/send-code
  /// Отправка одноразового SMS-кода для входа по номеру телефона.
  /// Ответ НЕ оборачивается в {"data": ...}
  Future<SendCodeResponse> sendSms(String phone) async {
    try {
      final response = await dio.post('/auth/send-code', data: {'phone': phone});
      // /auth/send-code не оборачивается в {"data": ...}
      return SendCodeResponse.fromJson(response.data);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// POST /auth/verify-code
  /// Ввод SMS-кода, создаёт сессию и выдаёт токены.
  /// Ответ оборачивается в {"data": ...}
  Future<AuthResponse> verifySms(String phone, String code) async {
    try {
      final response = await dio.post(
        '/auth/verify-code',
        data: {'phone': phone, 'code': code},
      );
      // Ответ оборачивается в {"data": ...}
      return AuthResponse.fromJson(response.data['data']);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// POST /auth/logout
  /// Инвалидирует refresh-токен.
  /// Ответ НЕ оборачивается в {"data": ...}, возвращает {"success": true}
  Future<LogoutResponse> logout(String refreshToken) async {
    try {
      final response = await dio.post('/auth/logout', data: {'refresh_token': refreshToken});
      // /auth/logout не оборачивается в {"data": ...}
      return LogoutResponse.fromJson(response.data);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// POST /auth/refresh
  /// Обновление пары токенов. Требует действующий refresh.
  /// Ответ оборачивается в {"data": ...}
  Future<AuthResponse> refresh(String refreshToken) async {
    try {
      final response = await dio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      // Ответ оборачивается в {"data": ...}
      return AuthResponse.fromJson(response.data['data']);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// GET /auth/me
  /// Информация о текущем пользователе (по access JWT).
  /// Требуется заголовок Authorization: Bearer <access_token>.
  /// Ответ оборачивается в {"data": ...}
  Future<User> me() async {
    try {
      final response = await dio.get(
        '/auth/me',
        options: _tempToken != null
            ? Options(headers: {'Authorization': 'Bearer $_tempToken'})
            : null,
      );
      // Ответ оборачивается в {"data": ...}
      return User.fromJson(response.data['data']);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// POST /auth/firebase-login
  /// Авторизация через Firebase ID Token.
  /// Если бэкенд не поддерживает этот endpoint, выбрасывает исключение.
  /// Ответ оборачивается в {"data": ...}
  Future<AuthResponse> loginWithFirebaseToken(String firebaseIdToken, String phoneNumber) async {
    try {
      final response = await dio.post(
        '/auth/firebase-login',
        data: {
          'firebase_id_token': firebaseIdToken,
          'phone': phoneNumber,
        },
      );
      // Ответ оборачивается в {"data": ...}
      return AuthResponse.fromJson(response.data['data']);
    } on DioException catch (e) {
      // Если endpoint не найден (404), выбрасываем исключение
      // чтобы в auth_notifier создать User из Firebase User
      if (e.response?.statusCode == 404) {
        throw AuthException('Firebase login endpoint not found', 404);
      }
      _handleError(e);
      rethrow;
    }
  }
}
