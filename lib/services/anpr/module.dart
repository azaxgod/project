import 'package:akimat_project/core/interceptors/token_error_handler.dart';
import 'package:akimat_project/modules/auth/src/storage/token_storage.dart';
import 'package:akimat_project/services/anpr/collection/anpr_collection.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider для Dio с настройкой для anpr-service
final anprDioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://snowops-anpr-service.onrender.com',
      connectTimeout: const Duration(seconds: 30), // Загрузка фотографий может занять время
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // JWT interceptor с автоматическим обновлением токена при 401
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Для публичных эндпоинтов не добавляем токен
        final publicPaths = [
          '/api/v1/anpr/events',
          '/api/v1/anpr/hikvision',
          '/api/v1/camera/status',
          '/health/live',
          '/health/ready',
        ];

        final isPublic = publicPaths.any((path) => options.path.contains(path));

        if (!isPublic) {
          final token = await TokenStorage.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }

        if (kDebugMode) {
          debugPrint('ANPR Request: ${options.method} ${options.path}');
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // Автоматический refresh токена при ошибках токена (только для защищенных эндпоинтов)
        final publicPaths = [
          '/api/v1/anpr/events',
          '/api/v1/anpr/hikvision',
          '/api/v1/camera/status',
          '/health/live',
          '/health/ready',
        ];

        final isPublic = publicPaths.any((path) => error.requestOptions.path.contains(path));

        if (!isPublic) {
          final tokenRefreshed = await handleTokenError(error, dio);
          if (tokenRefreshed) {
            try {
              final opts = error.requestOptions;
              final newToken = await TokenStorage.getAccessToken();
              if (newToken != null && newToken.isNotEmpty) {
                opts.headers['Authorization'] = 'Bearer $newToken';
              }
              final response = await dio.fetch(opts);
              handler.resolve(response);
              return;
            } catch (e) {
              handler.next(error);
              return;
            }
          }
        }
        handler.next(error);
      },
    ),
  );

  return dio;
});

/// Provider для AnprCollection
final anprCollectionProvider = Provider<AnprCollection>((ref) {
  final dio = ref.read(anprDioProvider);
  return AnprCollection(dio: dio);
});

