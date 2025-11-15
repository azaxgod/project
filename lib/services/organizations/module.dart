import 'package:akimat_project/modules/auth/src/storage/token_storage.dart';
import 'package:akimat_project/services/organizations/collection/organizations_collection.dart';
import 'package:akimat_project/services/organizations/collection/roles_collection.dart';
import 'package:akimat_project/services/organizations/services.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider для Dio с настройкой для roles-service
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

/// Provider для RolesCollection (реальный API)
final rolesCollectionProvider = Provider<RolesCollection>((ref) {
  final dio = ref.read(rolesDioProvider);
  return RolesCollection(dio: dio);
});

/// Provider для OrganizationsCollection (мок, для обратной совместимости)
final organizationsCollectionProvider =
    Provider<OrganizationsCollection>((ref) => OrganizationsCollection());

/// Provider для OrganizationsServices
final organizationsServicesProvider = Provider<OrganizationsServices>((ref) {
  // Используем RolesCollection вместо мок-данных
  return OrganizationsServices(
    collection: ref.read(organizationsCollectionProvider),
    rolesCollection: ref.read(rolesCollectionProvider),
  );
});
