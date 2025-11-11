import 'package:akimat_project/modules/auth/src/repository/auth_repository_impl.dart';
import 'package:akimat_project/modules/auth/src/storage/token_storage.dart';
import 'package:akimat_project/services/auth/collection/auth_collection.dart';
import 'package:akimat_project/services/auth/model/user.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_riverpod/legacy.dart';
import '../repository/i_auth_repository.dart';

final dioProvider = Provider<Dio>((ref) => Dio(
      BaseOptions(baseUrl: 'http://10.25.0.200:7080'), 
    ));


final authCollectionProvider = Provider<AuthCollection>((ref) {
  final dio = ref.read(dioProvider);
  return AuthCollection(dio: dio);
});
final iAuthRepositoryProvider = Provider<IAuthRepository>((ref) {
  final collection = ref.read(authCollectionProvider); 
  return AuthRepositoryImpl(authCollection: collection);
});

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, User?>((ref) => AuthNotifier(ref));

class AuthNotifier extends StateNotifier<User?> {
  final Ref ref;

  AuthNotifier(this.ref) : super(null){
  _loadUserFromToken();
  }
  Future<void> _loadUserFromToken() async {
    final token = await TokenStorage.getAccessToken();
    if (token != null) {
      try {
        final repo = ref.read(iAuthRepositoryProvider);
        final user = await repo.meFromToken(token); 
        state = user;
      } catch (e) {
        state = null;
      }
    }
  }
  Future<void> loginAkimat(String login, String password) async {
    final repo = ref.read(iAuthRepositoryProvider);
    final user = await repo.loginAkimat(login, password);
    state = user;
  }

  Future<void> sendSms(String phone) async {
    final repo = ref.read(iAuthRepositoryProvider);
    await repo.sendSms(phone);
  }

  Future<void> verifySms(String phone, String code) async {
    final repo = ref.read(iAuthRepositoryProvider);
    final user = await repo.verifySms(phone, code);
    state = user;
  }
  Future<void> logout()async{
    await TokenStorage.saveAccessToken('');
    await TokenStorage.saveRefreshToken('');
    state != null;
  }
}
