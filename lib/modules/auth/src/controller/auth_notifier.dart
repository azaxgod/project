import 'package:akimat_project/core/di.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:akimat_project/modules/auth/src/repository/i_auth_repository.dart';
import 'package:akimat_project/modules/auth/src/storage/token_storage.dart';
import 'package:akimat_project/services/auth/collection/auth_collection.dart';
import 'package:akimat_project/services/auth/model/auth_response.dart';
import 'package:akimat_project/services/auth/model/user.dart';

class AuthState {
  final bool isCheckingToken; // загрузка при старте приложения
  final bool isLoggingIn;     // загрузка при логине
  final User? user;
  final String? error;
  final bool isLoading;

  const AuthState({
    this.isLoading = true,
    this.isCheckingToken = false,
    this.isLoggingIn = false,
    this.user,
    this.error,
  });

  AuthState copyWith({
    bool? isCheckingToken,
    bool? isLoggingIn,
    User? user,
    String? error,
  }) {
    return AuthState(
      isCheckingToken: isCheckingToken ?? this.isCheckingToken,
      isLoggingIn: isLoggingIn ?? this.isLoggingIn,
      user: user ?? this.user,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final IAuthRepository repo;

  AuthNotifier(this.repo) : super(const AuthState()) {
    _loadUserFromToken();
  }

  Future<void> _loadUserFromToken() async {
    state = state.copyWith(isCheckingToken: true);
    final token = await TokenStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      try {
        final authResponse = await repo.meFromToken(token);
        state = state.copyWith(isCheckingToken: false, user: authResponse.user);
      } catch (_) {
        state = state.copyWith(isCheckingToken: false, user: null);
      }
    } else {
      state = state.copyWith(isCheckingToken: false);
    }
  }

  Future<void> loginAkimat(String login, String password) async {
    state = state.copyWith(isLoggingIn: true, error: null);
    try {
      final authResponse = await repo.loginAkimat(login, password);
      state = state.copyWith(isLoggingIn: false, user: authResponse.user, error: null);
    } catch (e) {
      final errorMessage = e is AuthException ? e.message : e.toString();
      state = state.copyWith(isLoggingIn: false, error: errorMessage);
    }
  }

  Future<void> sendSms(String phone) async {
    state = state.copyWith(isLoggingIn: true, error: null);
    try {
      await repo.sendSms(phone);
      state = state.copyWith(isLoggingIn: false, error: null);
    } catch (e) {
      final errorMessage = e is AuthException ? e.message : e.toString();
      state = state.copyWith(isLoggingIn: false, error: errorMessage);
    }
  }

  Future<void> verifySms(String phone, String code) async {
    state = state.copyWith(isLoggingIn: true, error: null);
    try {
      final authResponse = await repo.verifySms(phone, code);
      state = state.copyWith(isLoggingIn: false, user: authResponse.user, error: null);
    } catch (e) {
      final errorMessage = e is AuthException ? e.message : e.toString();
      state = state.copyWith(isLoggingIn: false, error: errorMessage);
    }
  }

  Future<void> logout() async {
    try {
      final refreshToken = await TokenStorage.getRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await repo.logout(refreshToken);
      }
    } catch (_) {
      // Игнорируем ошибки при logout, все равно очищаем локально
    } finally {
      await TokenStorage.saveAccessToken('');
      await TokenStorage.saveRefreshToken('');
      state = const AuthState();
    }
  }

  /// Обновление токенов
  Future<void> refreshTokens() async {
    final refreshToken = await TokenStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      state = state.copyWith(error: 'Refresh token not found');
      return;
    }

    try {
      final authResponse = await repo.refreshTokens(refreshToken);
      state = state.copyWith(user: authResponse.user);
    } catch (e) {
      // Refresh не удался, очищаем токены и разлогиниваем
      await TokenStorage.saveAccessToken('');
      await TokenStorage.saveRefreshToken('');
      state = const AuthState();
    }
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.read(iAuthRepositoryProvider);
  return AuthNotifier(repo);
});
