import 'package:akimat_project/modules/auth/src/storage/token_storage.dart';
import 'package:akimat_project/core/ui/widgets/session_expired_dialog.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Проверяет, является ли ошибка ошибкой токена (invalid, expired и т.д.)
bool _isTokenError(DioException error) {
  // Не обрабатываем ошибки для эндпоинтов авторизации - это не ошибки токена
  final path = error.requestOptions.path.toLowerCase();
  if (path.contains('/auth/login') ||
      path.contains('/auth/verify-code') ||
      path.contains('/auth/send-code') ||
      path.contains('/auth/logout')) {
    return false;
  }

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
        errorMessage.contains('invalid_token') ||
        errorMessage.contains('token_invalid') ||
        errorMessage.contains('access denied')) {
      return true;
    }
    
    // Не считаем "missing token" ошибкой токена - это нормально при выходе из аккаунта
    if (errorMessage.contains('missing token') || 
        errorMessage.contains('token missing') ||
        errorMessage.contains('no token') ||
        errorMessage.contains('token not found')) {
      return false;
    }
    
    // Не считаем "unauthorized" или "authentication failed" ошибкой токена для эндпоинтов авторизации
    // Эти сообщения могут быть из-за неправильных учетных данных
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
  final accessToken = await TokenStorage.getAccessToken();
  
  // Если токены уже очищены (пользователь разлогинен), не показываем диалог
  if ((refreshToken == null || refreshToken.isEmpty) && 
      (accessToken == null || accessToken.isEmpty)) {
    debugPrint('Tokens already cleared (user logged out), ignoring token error');
    return false;
  }
  
  // Проверяем, не является ли это ошибкой "missing token" - это нормально при выходе
  if (error.response?.data != null) {
    final errorData = error.response!.data;
    String errorMessage = '';
    
    if (errorData is Map) {
      errorMessage = (errorData['error'] ?? errorData['message'] ?? '').toString().toLowerCase();
    } else if (errorData is String) {
      errorMessage = errorData.toLowerCase();
    }
    
    if (errorMessage.contains('missing token') || 
        errorMessage.contains('token missing') ||
        errorMessage.contains('no token') ||
        errorMessage.contains('token not found')) {
      debugPrint('Missing token error detected, but tokens are cleared (user logged out), ignoring');
      return false;
    }
  }
  
  if (refreshToken == null || refreshToken.isEmpty) {
    debugPrint('No refresh token found. Clearing access token.');
    await TokenStorage.saveAccessToken('');
    await TokenStorage.saveRefreshToken('');
    
    // Показываем модальное окно об истекшей сессии только если пользователь еще авторизован
    // Проверяем, что access token был (значит пользователь был авторизован)
    if (accessToken != null && accessToken.isNotEmpty) {
      SessionExpiredService.show();
    }
    
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

    // Проверяем, были ли токены до попытки обновления
    final hadTokens = refreshToken.isNotEmpty;
    
    await TokenStorage.saveAccessToken('');
    await TokenStorage.saveRefreshToken('');
    
    // Показываем модальное окно об истекшей сессии только если токены были (пользователь был авторизован)
    // Не показываем, если пользователь уже разлогинен
    if (hadTokens) {
      SessionExpiredService.show();
    }
    
    return false;
  }
}

