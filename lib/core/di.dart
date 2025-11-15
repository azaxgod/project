import 'package:akimat_project/modules/auth/src/repository/auth_repository_impl.dart';
import 'package:akimat_project/modules/auth/src/repository/i_auth_repository.dart';
import 'package:akimat_project/modules/auth/src/storage/token_storage.dart';
import 'package:akimat_project/services/auth/collection/auth_collection.dart';
import 'package:akimat_project/services/organizations/collection/roles_collection.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://snowops-auth-service.onrender.com',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // Interceptor для автоматического добавления токена
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
        // Автоматический refresh токена при 401
        if (error.response?.statusCode == 401) {
          final refreshToken = await TokenStorage.getRefreshToken();
          if (refreshToken != null && refreshToken.isNotEmpty) {
            try {
              // Создаем временный Dio без interceptor для refresh, чтобы избежать цикла
              final tempDio = Dio(
                BaseOptions(
                  baseUrl: dio.options.baseUrl,
                  headers: dio.options.headers,
                ),
              );
              
              final refreshResponse = await tempDio.post(
                '/auth/refresh',
                data: {'refresh_token': refreshToken},
              );
              
              final authResponse = refreshResponse.data['data'];
              await TokenStorage.saveAccessToken(authResponse['access_token']);
              await TokenStorage.saveRefreshToken(authResponse['refresh_token']);

              // Повторяем оригинальный запрос с новым токеном
              final opts = error.requestOptions;
              opts.headers['Authorization'] = 'Bearer ${authResponse['access_token']}';
              
              final response = await dio.fetch(opts);
              handler.resolve(response);
              return;
            } catch (e) {
              // Refresh не удался, очищаем токены
              await TokenStorage.saveAccessToken('');
              await TokenStorage.saveRefreshToken('');
            }
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
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
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
    ),
  );

  return dio;
});

final rolesCollectionProvider = Provider<RolesCollection>((ref) {
  final dio = ref.read(rolesDioProvider);
  return RolesCollection(dio: dio);
});
