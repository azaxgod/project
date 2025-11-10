

import 'package:akimat_project/services/auth/model/user.dart';

abstract class IAuthRepository{

  Future<User> loginAkimat(String login,String password);
  Future<void> sendSms(String phone);
  Future<User> verifySms(String phone,String code);
}