

import 'package:akimat_project/services/auth/model/auth_response.dart';
import 'package:akimat_project/services/auth/model/user.dart';

abstract class IAuthRepository {
  Future<AuthResponse> loginAkimat(String login, String password);
  Future<AuthResponse> meFromToken(String token); 
  Future<void> sendSms(String phone);
  Future<AuthResponse> verifySms(String phone, String code);
}
