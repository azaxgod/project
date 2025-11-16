import 'package:akimat_project/services/auth/model/auth_response.dart';
import 'package:akimat_project/services/auth/model/send_code_response.dart';

abstract class IAuthRepository {
  Future<AuthResponse> loginAkimat(String login, String password);
  Future<AuthResponse> meFromToken(String token);
  Future<SendCodeResponse> sendSms(String phone);
  Future<AuthResponse> verifySms(String phone, String code);
  Future<AuthResponse> refreshTokens(String refreshToken);
  Future<void> logout(String refreshToken);
}
