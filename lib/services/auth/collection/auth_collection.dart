import 'package:akimat_project/services/auth/model/user.dart';
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
      throw AuthException(
        error.message ?? 'Network error: ${error.type}',
        null,
      );
    }
  }

  Future<AuthResponse> login(String login, String password) async {
    try {
      final response = await dio.post('/auth/login', data: {
        'login': login,
        'password': password,
      });
      return AuthResponse.fromJson(response.data['data']);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> sendSms(String phone) async {
    try {
      final response = await dio.post('/auth/send-code', data: {'phone': phone});
      // /auth/send-code не оборачивается в {"data": ...}
      return response.data;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<AuthResponse> verifySms(String phone, String code) async {
    try {
      final response = await dio.post(
        '/auth/verify-code',
        data: {'phone': phone, 'code': code},
      );
      return AuthResponse.fromJson(response.data['data']);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<void> logout(String refreshToken) async {
    try {
      await dio.post('/auth/logout', data: {'refresh_token': refreshToken});
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<AuthResponse> refresh(String refreshToken) async {
    try {
      final response = await dio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      return AuthResponse.fromJson(response.data['data']);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<User> me() async {
    try {
      final response = await dio.get(
        '/auth/me',
        options: _tempToken != null
            ? Options(headers: {'Authorization': 'Bearer $_tempToken'})
            : null,
      );
      return User.fromJson(response.data['data']);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }
}
