import 'package:akimat_project/modules/auth/src/storage/token_storage.dart';
import 'package:akimat_project/services/auth/collection/auth_collection.dart';
import 'package:akimat_project/services/auth/model/auth_response.dart';
import 'package:akimat_project/services/auth/model/send_code_response.dart';
import 'i_auth_repository.dart';

class AuthRepositoryImpl implements IAuthRepository {
  final AuthCollection authCollection;

  AuthRepositoryImpl({required this.authCollection});

  @override
  Future<AuthResponse> loginAkimat(String login, String password) async {
    final authResponse = await authCollection.login(login, password);
    
    // Проверяем, что токены не пустые перед сохранением
    if (authResponse.accessToken.isNotEmpty) {
      await TokenStorage.saveAccessToken(authResponse.accessToken);
      // Проверяем, что токен действительно сохранился
      final savedToken = await TokenStorage.getAccessToken();
      if (savedToken == null || savedToken.isEmpty) {
        throw Exception('Failed to save access token');
      }
    }
    if (authResponse.refreshToken.isNotEmpty) {
      await TokenStorage.saveRefreshToken(authResponse.refreshToken);
    }

    return authResponse;
  }

  @override
  Future<AuthResponse> meFromToken(String token) async {
    authCollection.setTempToken(token);
    final user = await authCollection.me();

    // Создаём AuthResponse с пустыми токенами, так как у нас есть только User
    return AuthResponse(
      accessToken: token,
      refreshToken: '', // если нужно, можно сделать отдельный метод для refresh
      user: user,
    );
  }

  @override
  Future<SendCodeResponse> sendSms(String phone) async {
    return await authCollection.sendSms(phone);
  }

  @override
  Future<AuthResponse> verifySms(String phone, String code) async {
    final authResponse = await authCollection.verifySms(phone, code);

    // Сохраняем токены (проверяем, что они не пустые)
    if (authResponse.accessToken.isNotEmpty) {
      await TokenStorage.saveAccessToken(authResponse.accessToken);
    }
    if (authResponse.refreshToken.isNotEmpty) {
      await TokenStorage.saveRefreshToken(authResponse.refreshToken);
    }

    return authResponse;
  }

  @override
  Future<AuthResponse> refreshTokens(String refreshToken) async {
    final authResponse = await authCollection.refresh(refreshToken);
    
    // Сохраняем токены (проверяем, что они не пустые)
    if (authResponse.accessToken.isNotEmpty) {
      await TokenStorage.saveAccessToken(authResponse.accessToken);
    }
    if (authResponse.refreshToken.isNotEmpty) {
      await TokenStorage.saveRefreshToken(authResponse.refreshToken);
    }

    return authResponse;
  }

  @override
  Future<void> logout(String refreshToken) async {
    await authCollection.logout(refreshToken);
    await TokenStorage.saveAccessToken('');
    await TokenStorage.saveRefreshToken('');
  }
}
