import 'package:akimat_project/modules/auth/src/storage/token_storage.dart';
import 'package:akimat_project/services/acts/collection/acts_collection.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider для Dio с настройкой для acts-service
final actsDioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://snowops-acts-service.onrender.com', // TODO: заменить на реальный URL
      connectTimeout: const Duration(seconds: 30), // PDF может генерироваться долго
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      // responseType будет меняться динамически для PDF запросов
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await TokenStorage.getAccessToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
          debugPrint('Acts API - JWT token added (length: ${token.length})');
        } else {
          debugPrint('Acts API - WARNING: No JWT token found!');
        }
        debugPrint('Acts API - Request: ${options.method} ${options.baseUrl}${options.path}');
        debugPrint('Acts API - Body: ${options.data}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        debugPrint('Acts API - Response: ${response.statusCode} ${response.requestOptions.path}');
        debugPrint('Acts API - Response type: ${response.headers.value('content-type')}');
        debugPrint('Acts API - Response size: ${response.data?.length ?? 0} bytes');
        handler.next(response);
      },
      onError: (error, handler) {
        debugPrint('Acts API - Error: ${error.type}');
        if (error.response != null) {
          debugPrint('Acts API - Error status: ${error.response!.statusCode}');
          debugPrint('Acts API - Error data: ${error.response!.data}');
        }
        handler.next(error);
      },
    ),
  );

  return dio;
});

final actsCollectionProvider = Provider<ActsCollection>((ref) {
  final dio = ref.read(actsDioProvider);
  return ActsCollection(dio: dio);
});

