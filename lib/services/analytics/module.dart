import 'package:akimat_project/modules/auth/src/storage/token_storage.dart';
import 'package:akimat_project/services/analytics/collection/analytics_collection.dart';
import 'package:akimat_project/services/analytics/services.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider для Dio с настройкой для analytics-service
final analyticsDioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://snowops-analytics-service.onrender.com', // TODO: заменить на реальный URL
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
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
          debugPrint('Analytics API - JWT token added (length: ${token.length})');
        } else {
          debugPrint('Analytics API - WARNING: No JWT token found!');
        }
        debugPrint('Analytics API - Request: ${options.method} ${options.baseUrl}${options.path}');
        debugPrint('Analytics API - Query params: ${options.queryParameters}');
        debugPrint('Analytics API - Headers: ${options.headers}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        debugPrint('Analytics API - Response: ${response.statusCode} ${response.requestOptions.path}');
        handler.next(response);
      },
      onError: (error, handler) {
        debugPrint('Analytics API - Error: ${error.type}');
        if (error.response != null) {
          debugPrint('Analytics API - Error status: ${error.response!.statusCode}');
          debugPrint('Analytics API - Error data: ${error.response!.data}');
        }
        handler.next(error);
      },
    ),
  );

  return dio;
});

final analyticsCollectionProvider = Provider<AnalyticsCollection>((ref) {
  final dio = ref.read(analyticsDioProvider);
  return AnalyticsCollection(dio: dio);
});

final analyticsServicesProvider = Provider<AnalyticsServices>((ref) {
  final collection = ref.read(analyticsCollectionProvider);
  return AnalyticsServices(collection: collection);
});

