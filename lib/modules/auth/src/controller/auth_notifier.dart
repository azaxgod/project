import 'package:akimat_project/modules/auth/src/repository/auth_repository_impl.dart';
import 'package:akimat_project/services/auth/model/user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_riverpod/legacy.dart';
import '../repository/i_auth_repository.dart';

// Провайдер репозитория
final iAuthRepositoryProvider = Provider<IAuthRepository>(
  (ref) => AuthRepositoryImpl(),
);

// StateNotifierProvider для Auth
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, User?>((ref) => AuthNotifier(ref));

class AuthNotifier extends StateNotifier<User?> {
  final Ref ref;

  AuthNotifier(this.ref) : super(null);

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
}
