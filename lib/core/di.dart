import 'package:akimat_project/modules/analytics/src/repository/analytics_repository_impl.dart';
import 'package:akimat_project/modules/analytics/src/repository/i_analytics_repository.dart';
import 'package:akimat_project/modules/auth/src/repository/auth_repository_impl.dart';
import 'package:akimat_project/modules/auth/src/repository/i_auth_repository.dart';
import 'package:akimat_project/core/interceptors/token_error_handler.dart';
import 'package:akimat_project/modules/auth/src/storage/token_storage.dart';
import 'package:akimat_project/modules/dashboard/src/repository/organizations_repository.dart';
import 'package:akimat_project/modules/dashboard/src/repository/organizations_repository_impl.dart';
import 'package:akimat_project/modules/violations/src/repository/i_violations_repository.dart';
import 'package:akimat_project/modules/violations/src/repository/violations_repository_impl.dart';
import 'package:akimat_project/services/analytics/module.dart';
import 'package:akimat_project/services/auth/collection/auth_collection.dart';
import 'package:akimat_project/services/auth/firebase_auth_service.dart';
import 'package:akimat_project/services/organizations/collection/roles_collection.dart';
import 'package:akimat_project/services/organizations/module.dart';
import 'package:akimat_project/services/violations/module.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://snowops-auth-service.onrender.com',
      connectTimeout: const Duration(seconds: 15), // Уменьшено с 30 до 15 секунд
      receiveTimeout: const Duration(seconds: 15), // Уменьшено с 30 до 15 секунд
      sendTimeout: const Duration(seconds: 15), // Добавлен таймаут отправки
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );


  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await TokenStorage.getAccessToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // Игнорируем ошибки "missing token" - это нормально при выходе из аккаунта
        // Проверяем, не является ли это ошибкой "missing token"
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
            // Проверяем, очищены ли токены (пользователь вышел)
            final refreshToken = await TokenStorage.getRefreshToken();
            final accessToken = await TokenStorage.getAccessToken();
            if ((refreshToken == null || refreshToken.isEmpty) && 
                (accessToken == null || accessToken.isEmpty)) {
              // Игнорируем ошибку, не передаем дальше - пользователь уже вышел
              debugPrint('Missing token error ignored - user logged out');
              return;
            }
          }
        }
        
        // Автоматический refresh токена при ошибках токена
        final tokenRefreshed = await handleTokenError(error, dio);
        if (tokenRefreshed) {
          try {
            // Повторяем оригинальный запрос с новым токеном
            final opts = error.requestOptions;
            final newToken = await TokenStorage.getAccessToken();
            if (newToken != null && newToken.isNotEmpty) {
              opts.headers['Authorization'] = 'Bearer $newToken';
            }
            final response = await dio.fetch(opts);
            handler.resolve(response);
            return;
          } catch (e) {
            // Если повторный запрос не удался, передаем ошибку дальше
            handler.next(error);
            return;
          }
        }
        handler.next(error);
      },
    ),
  );

  return dio;
});

final authCollectionProvider = Provider<AuthCollection>((ref) {
  final dio = ref.read(dioProvider);
  return AuthCollection(dio: dio);
});

final iAuthRepositoryProvider = Provider<IAuthRepository>((ref) {
  final collection = ref.read(authCollectionProvider);
  return AuthRepositoryImpl(authCollection: collection);
});

final rolesDioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://snowops-roles.onrender.com',
      connectTimeout: const Duration(seconds: 15), // Уменьшено с 30 до 15 секунд
      receiveTimeout: const Duration(seconds: 15), // Уменьшено с 30 до 15 секунд
      sendTimeout: const Duration(seconds: 15), // Добавлен таймаут отправки
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await TokenStorage.getAccessToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // Игнорируем ошибки "missing token" - это нормально при выходе из аккаунта
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
            // Проверяем, очищены ли токены (пользователь вышел)
            final refreshToken = await TokenStorage.getRefreshToken();
            final accessToken = await TokenStorage.getAccessToken();
            if ((refreshToken == null || refreshToken.isEmpty) && 
                (accessToken == null || accessToken.isEmpty)) {
              // Игнорируем ошибку, не передаем дальше - пользователь уже вышел
              debugPrint('Missing token error ignored (rolesDio) - user logged out');
              return;
            }
          }
        }
        
        // Автоматический refresh токена при ошибках токена
        final tokenRefreshed = await handleTokenError(
          error,
          dio,
          authServiceBaseUrl: 'https://snowops-auth-service.onrender.com',
        );
        if (tokenRefreshed) {
          try {
            // Повторяем оригинальный запрос с новым токеном
            final opts = error.requestOptions;
            final newToken = await TokenStorage.getAccessToken();
            if (newToken != null && newToken.isNotEmpty) {
              opts.headers['Authorization'] = 'Bearer $newToken';
            }
            final response = await dio.fetch(opts);
            handler.resolve(response);
            return;
          } catch (e) {
            // Если повторный запрос не удался, передаем ошибку дальше
            handler.next(error);
            return;
          }
        }
        handler.next(error);
      },
    ),
  );

  return dio;
});

final rolesCollectionProvider = Provider<RolesCollection>((ref) {
  final dio = ref.read(rolesDioProvider);
  return RolesCollection(dio: dio);
});

final firebaseAuthServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});

// Analytics providers
final iAnalyticsRepositoryProvider = Provider<IAnalyticsRepository>((ref) {
  final collection = ref.read(analyticsCollectionProvider);
  return AnalyticsRepositoryImpl(collection: collection);
});

// Violations providers
final iViolationsRepositoryProvider = Provider<IViolationsRepository>((ref) {
  final collection = ref.read(violationsCollectionProvider);
  return ViolationsRepositoryImpl(collection: collection);
});

// Organizations repository provider
final organizationsRepositoryProvider = Provider<OrganizationsRepository>((ref) {
  final services = ref.read(organizationsServicesProvider);
  return OrganizationsRepositoryImpl(services: services);
});
