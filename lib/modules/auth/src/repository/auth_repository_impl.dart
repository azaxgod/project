import 'package:akimat_project/modules/auth/src/storage/token_storage.dart';
import 'package:akimat_project/services/auth/collection/auth_collection.dart';
import 'package:akimat_project/services/auth/model/auth_response.dart';
import 'package:akimat_project/services/auth/model/user.dart';
// import '../model/auth_response.dart';
import 'i_auth_repository.dart';

class AuthRepositoryImpl implements IAuthRepository {
  final AuthCollection authCollection;

  AuthRepositoryImpl({required this.authCollection});

  @override
  Future<AuthResponse> loginAkimat(String login, String password) async {
    try {
      final authResponse = await authCollection.login(login, password);

      // Сохраняем токены
      await TokenStorage.saveAccessToken(authResponse.accessToken);
      await TokenStorage.saveRefreshToken(authResponse.refreshToken);

      return authResponse;
    } catch (e) {
      throw Exception('Неверный логин или пароль: $e');
    }
  }

  @override
  Future<AuthResponse> meFromToken(String token) async {
    try {
      authCollection.setTempToken(token);
      final user = await authCollection.me();

      // Создаём AuthResponse с пустыми токенами, так как у нас есть только User
      return AuthResponse(
        accessToken: token,
        refreshToken: '', // если нужно, можно сделать отдельный метод для refresh
        user: user,
      );
    } catch (e) {
      throw Exception('Не удалось получить данные пользователя: $e');
    }
  }

  @override
  Future<void> sendSms(String phone) async {
    await authCollection.sendSms(phone);
  }

  @override
  Future<AuthResponse> verifySms(String phone, String code) async {
    try {
      final authResponse = await authCollection.verifySms(phone, code);

      // Сохраняем токены
      await TokenStorage.saveAccessToken(authResponse.accessToken);
      await TokenStorage.saveRefreshToken(authResponse.refreshToken);

      return authResponse;
    } catch (e) {
      throw Exception('Неверный код или ошибка верификации: $e');
    }
  }
}
