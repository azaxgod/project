import 'package:akimat_project/core/interceptors/token_error_handler.dart';
import 'package:akimat_project/modules/auth/src/storage/token_storage.dart';
import 'package:akimat_project/services/tickets/collection/tickets_collection.dart';
import 'package:akimat_project/services/tickets/services.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final ticketsDioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://snowops-tickets.onrender.com', 
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
        
        // Логирование запросов для отладки
        debugPrint('TicketService Request: ${options.method} ${options.uri}');
        debugPrint('TicketService Headers: ${options.headers}');
        debugPrint('TicketService Query params: ${options.queryParameters}');
        
        handler.next(options);
      },
      onError: (error, handler) async {
        // Логирование ошибок для отладки
        debugPrint('TicketService Error: ${error.type}');
        debugPrint('TicketService Error URL: ${error.requestOptions.uri}');
        debugPrint('TicketService Error Method: ${error.requestOptions.method}');
        debugPrint('TicketService Error Status: ${error.response?.statusCode}');
        debugPrint('TicketService Error Data: ${error.response?.data}');
        debugPrint('TicketService Error Message: ${error.message}');
        
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

final ticketsCollectionProvider = Provider<TicketsCollection>((ref) {
  final dio = ref.read(ticketsDioProvider);
  return TicketsCollection(dio: dio);
});

final ticketsServicesProvider = Provider<TicketsServices>((ref) {
  return TicketsServices(collection: ref.read(ticketsCollectionProvider));
});







