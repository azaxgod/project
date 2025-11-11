import 'package:akimat_project/services/auth/model/user.dart';

class AuthState {
  final bool isCheckingToken; // при старте приложения
  final bool isLoggingIn;     // при логине через форму
  final User? user;
  final String? error;
  final bool? isLoading;

  const AuthState({
    this.isCheckingToken = false,
    this.isLoggingIn = false,
    this.user,
    this.isLoading,
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
