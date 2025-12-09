import 'package:akimat_project/modules/auth/src/storage/token_storage.dart';
import 'package:akimat_project/core/ui/widgets/session_expired_dialog.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Проверяет, является ли ошибка ошибкой токена (invalid, expired и т.д.)
bool _isTokenError(DioException error) {
  // Проверяем статус код (401 Unauthorized или 403 Forbidden)
  if (error.response?.statusCode == 401 || error.response?.statusCode == 403) {
    return true;
  }

  // Проверяем текст ошибки в теле ответа
  if (error.response?.data != null) {
    final errorData = error.response!.data;
    String errorMessage = '';

    if (errorData is Map) {
      errorMessage = (errorData['error'] ?? errorData['message'] ?? '').toString().toLowerCase();
    } else if (errorData is String) {
      errorMessage = errorData.toLowerCase();
    }

    // Проверяем наличие ключевых слов, связанных с токеном
    if (errorMessage.contains('invalid token') ||
        errorMessage.contains('expired token') ||
        errorMessage.contains('token expired') ||
        errorMessage.contains('unauthorized') ||
        errorMessage.contains('invalid_token') ||
        errorMessage.contains('token_invalid') ||
        errorMessage.contains('access denied') ||
        errorMessage.contains('authentication failed')) {
      return true;
    }
  }

  return false;
}

/// Обрабатывает ошибку токена: пытается обновить токен, при неудаче очищает токены
/// Возвращает true, если токен был успешно обновлен и запрос нужно повторить
/// Возвращает false, если токен не удалось обновить (нужно разлогинить пользователя)
Future<bool> handleTokenError(
  DioException error,
  Dio dio, {
  String? authServiceBaseUrl,
}) async {
  // Проверяем, является ли это ошибкой токена
  if (!_isTokenError(error)) {
    return false;
  }

  debugPrint('Token error detected. Attempting to refresh token...');

  final refreshToken = await TokenStorage.getRefreshToken();
  if (refreshToken == null || refreshToken.isEmpty) {
    debugPrint('No refresh token found. Clearing access token.');
    await TokenStorage.saveAccessToken('');
    await TokenStorage.saveRefreshToken('');
    
    // Показываем модальное окно об истекшей сессии
    SessionExpiredService.show();
    
    return false;
  }

  try {
    // Используем переданный baseUrl или берем из dio
    final baseUrl = authServiceBaseUrl ?? dio.options.baseUrl;

    // Создаем временный Dio без interceptor для refresh, чтобы избежать цикла
    final tempDio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    debugPrint('Refreshing token from: $baseUrl/auth/refresh');

    final refreshResponse = await tempDio.post(
      '/auth/refresh',
      data: {'refresh_token': refreshToken},
    );

    if (refreshResponse.data == null) {
      throw Exception('Empty refresh response');
    }

    final authResponse = refreshResponse.data['data'] ?? refreshResponse.data;
    if (authResponse == null || authResponse['access_token'] == null) {
      throw Exception('Invalid refresh response format');
    }

    await TokenStorage.saveAccessToken(authResponse['access_token']);
    if (authResponse['refresh_token'] != null) {
      await TokenStorage.saveRefreshToken(authResponse['refresh_token']);
    }

    debugPrint('Token refreshed successfully');


    final opts = error.requestOptions;
    opts.headers['Authorization'] = 'Bearer ${authResponse['access_token']}';

    return true;
  } catch (e) {
    debugPrint('Failed to refresh token: $e');

    await TokenStorage.saveAccessToken('');
    await TokenStorage.saveRefreshToken('');
    
    // Показываем модальное окно об истекшей сессии
    SessionExpiredService.show();
    
    return false;
  }
}

