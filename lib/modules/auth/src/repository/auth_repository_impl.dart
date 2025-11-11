import 'package:akimat_project/modules/auth/src/storage/token_storage.dart';
import 'package:akimat_project/services/auth/collection/auth_collection.dart';
import 'package:akimat_project/services/auth/model/user.dart';
import 'i_auth_repository.dart';

class AuthRepositoryImpl implements IAuthRepository {
  final AuthCollection authCollection;

  AuthRepositoryImpl({required this.authCollection});

  @override
  Future<User> loginAkimat(String login, String password) async {
    try {

      final authResponse = await authCollection.login(login, password);

      // Сохраняем токены
      await TokenStorage.saveAccessToken(authResponse.accessToken);
      await TokenStorage.saveRefreshToken(authResponse.refreshToken);


      return authResponse.user;
    } catch (e) {

      throw Exception('Неверный логин или пароль: $e');
    }
    
  }

  Future<User> meFromToken(String token) async{
    authCollection.setTempToken(token);
    final user = await authCollection.me();
    return user;
  }

  @override
  Future<void> sendSms(String phone) async {
    await authCollection.sendSms(phone);
  }

  @override
  Future<User> verifySms(String phone, String code) async {
    try {
      final authResponse = await authCollection.verifySms(phone, code);

      // Сохраняем токены
      await TokenStorage.saveAccessToken(authResponse.accessToken);
      await TokenStorage.saveRefreshToken(authResponse.refreshToken);

      return authResponse.user;
    } catch (e) {
      throw Exception('Неверный код или ошибка верификации: $e');
    }
  }
}
