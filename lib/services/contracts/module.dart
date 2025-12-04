import 'package:akimat_project/core/interceptors/token_error_handler.dart';
import 'package:akimat_project/modules/auth/src/storage/token_storage.dart';
import 'package:akimat_project/services/contracts/collection/contracts_collection.dart';
import 'package:akimat_project/services/contracts/services.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final contractsDioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://snowops-contract-service.onrender.com',
      connectTimeout: const Duration(seconds: 15), 
      receiveTimeout: const Duration(seconds: 15), 
      sendTimeout: const Duration(seconds: 15), 
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
        handler.next(options);
      },
      onError: (error, handler) async {
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

final contractsCollectionProvider = Provider<ContractsCollection>((ref) {
  final dio = ref.read(contractsDioProvider);
  return ContractsCollection(dio: dio);
});

final contractsServicesProvider = Provider<ContractsServices>((ref) {
  return ContractsServices(collection: ref.read(contractsCollectionProvider));
});

