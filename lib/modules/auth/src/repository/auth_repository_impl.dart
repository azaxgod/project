import 'package:akimat_project/services/auth/model/user.dart';

import 'i_auth_repository.dart';
// import '../../models/user.dart';

class AuthRepositoryImpl implements IAuthRepository {
  @override
  Future<User> loginAkimat(String login, String password) async {
    // TODO: API вызов
    // Проверка login/password, возврат User с ролью AKIMAT_ADMIN
    return User(id: '1', login: login, role: 'AKIMAT_ADMIN', isActive: true);
  }

  @override
  Future<void> sendSms(String phone) async {
    // TODO: вызвать API для отправки SMS
  }

  @override
  Future<User> verifySms(String phone, String code) async {
    // TODO: проверить код и вернуть User с нужной ролью
    return User(id: '2', login: phone, phone: phone, role: 'TOO_ADMIN', isActive: true);
  }
}
