import 'package:akimat_project/modules/auth/src/storage/token_storage.dart';
import 'package:akimat_project/services/contracts/collection/contracts_collection.dart';
import 'package:akimat_project/services/contracts/services.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final contractsDioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://snowops-contract-service.onrender.com',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
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
        // Автоматический refresh токена при 401
        if (error.response?.statusCode == 401) {
          final refreshToken = await TokenStorage.getRefreshToken();
          if (refreshToken != null && refreshToken.isNotEmpty) {
            try {
              final tempDio = Dio(
                BaseOptions(
                  baseUrl: 'https://snowops-auth-service.onrender.com',
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

final contractsCollectionProvider = Provider<ContractsCollection>((ref) {
  final dio = ref.read(contractsDioProvider);
  return ContractsCollection(dio: dio);
});

final contractsServicesProvider = Provider<ContractsServices>((ref) {
  return ContractsServices(collection: ref.read(contractsCollectionProvider));
});

