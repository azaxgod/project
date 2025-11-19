import 'package:akimat_project/modules/auth/src/storage/token_storage.dart';
import 'package:akimat_project/services/operations/collection/operations_collection.dart';
import 'package:akimat_project/services/operations/services.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final operationsDioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://snowops-operations-service.onrender.com',
      connectTimeout: const Duration(seconds: 15), // Уменьшено с 30 до 15 секунд
      receiveTimeout: const Duration(seconds: 15), // Уменьшено с 30 до 15 секунд
      sendTimeout: const Duration(seconds: 15), // Добавлен таймаут отправки
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
        final token = await TokenStorage.getAccessToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        
        // Логирование запросов для отладки
        debugPrint('OperationsService Request: ${options.method} ${options.uri}');
        debugPrint('OperationsService Headers: ${options.headers}');
        debugPrint('OperationsService Query params: ${options.queryParameters}');
        
        handler.next(options);
      },
      onError: (error, handler) async {
        // Логирование ошибок для отладки
        debugPrint('OperationsService Error: ${error.type}');
        debugPrint('OperationsService Error URL: ${error.requestOptions.uri}');
        debugPrint('OperationsService Error Method: ${error.requestOptions.method}');
        debugPrint('OperationsService Error Status: ${error.response?.statusCode}');
        debugPrint('OperationsService Error Data: ${error.response?.data}');
        debugPrint('OperationsService Error Headers: ${error.response?.headers}');
        debugPrint('OperationsService Error Message: ${error.message}');
        
        // Автоматический refresh токена при 401
        if (error.response?.statusCode == 401) {
          final refreshToken = await TokenStorage.getRefreshToken();
          if (refreshToken != null && refreshToken.isNotEmpty) {
            try {
              final tempDio = Dio(
                BaseOptions(
                  baseUrl: 'https://snowops-auth-service.onrender.com',
                  connectTimeout: const Duration(seconds: 10),
                  receiveTimeout: const Duration(seconds: 10),
                  sendTimeout: const Duration(seconds: 10),
                  headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                  },
                ),
              );
              
              final refreshResponse = await tempDio.post(
                '/auth/refresh',
                data: {'refresh_token': refreshToken},
              );
              
              final authResponse = refreshResponse.data['data'];
              await TokenStorage.saveAccessToken(authResponse['access_token']);
              await TokenStorage.saveRefreshToken(authResponse['refresh_token']);

              final opts = error.requestOptions;
              opts.headers['Authorization'] = 'Bearer ${authResponse['access_token']}';
              
              final response = await dio.fetch(opts);
              handler.resolve(response);
              return;
            } catch (e) {
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

final operationsCollectionProvider = Provider<OperationsCollection>((ref) {
  final dio = ref.read(operationsDioProvider);
  return OperationsCollection(dio: dio);
});

final operationsServicesProvider = Provider<OperationsServices>((ref) {
  return OperationsServices(collection: ref.read(operationsCollectionProvider));
});

