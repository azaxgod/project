import 'package:akimat_project/modules/auth/src/repository/auth_repository_impl.dart';
import 'package:akimat_project/modules/auth/src/repository/i_auth_repository.dart';
import 'package:akimat_project/modules/auth/src/storage/token_storage.dart';
import 'package:akimat_project/services/auth/collection/auth_collection.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'http://10.25.0.200:7080', 
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await TokenStorage.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token'; // исправил опечатку Berrear -> Bearer
        }
        handler.next(options);
      },
    ),
  );

  return dio; //  обязательно вернуть Dio
});

final authCollectionProvider = Provider<AuthCollection>((ref) {
  final dio = ref.read(dioProvider);
  return AuthCollection(dio: dio);
});

final iAuthRepositoryProvider = Provider<IAuthRepository>((ref) {
  final collection = ref.read(authCollectionProvider);
  return AuthRepositoryImpl(authCollection: collection);
});