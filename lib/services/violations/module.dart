import 'package:akimat_project/modules/auth/src/storage/token_storage.dart';
import 'package:akimat_project/services/violations/collection/violations_collection.dart';
import 'package:akimat_project/services/violations/services.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider для Dio с настройкой для violations-service
final violationsDioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://snowops-violations-service.onrender.com',
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
        }
        handler.next(options);
      },
    ),
  );

  return dio;
});

final violationsCollectionProvider = Provider<ViolationsCollection>((ref) {
  final dio = ref.read(violationsDioProvider);
  return ViolationsCollection(dio: dio);
});

final violationsServicesProvider = Provider<ViolationsServices>((ref) {
  final collection = ref.read(violationsCollectionProvider);
  return ViolationsServices(collection: collection);
});


