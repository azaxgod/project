import 'dart:async';

import 'package:akimat_project/core/di.dart';
import 'package:akimat_project/core/storage/route_storage.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth show User;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:akimat_project/modules/auth/src/repository/i_auth_repository.dart';
import 'package:akimat_project/modules/auth/src/storage/token_storage.dart';
import 'package:akimat_project/services/auth/collection/auth_collection.dart';
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
  StreamSubscription<firebase_auth.User?>? _authStateSubscription;

  AuthNotifier(this.repo) : super(const AuthState()) {
    _initAuthListener();
  }

  /// Инициализация слушателя изменений состояния Firebase Auth
  void _initAuthListener() {
    // Сначала проверяем текущего пользователя
    _loadUserFromToken();
    
    // Затем подписываемся на изменения состояния
    _authStateSubscription = FirebaseAuth.instance.authStateChanges().listen(
      (firebaseUser) async {
        if (firebaseUser != null) {
          try {
            final user = await _createUserFromFirebase(firebaseUser);
            // StateNotifier не имеет mounted, но мы можем проверить через try-catch
            state = state.copyWith(user: user, isCheckingToken: false);
          } catch (e) {
            debugPrint('Error creating user from Firebase: $e');
            try {
              state = state.copyWith(user: null, isCheckingToken: false);
            } catch (_) {
              // StateNotifier уже удален, игнорируем
            }
          }
        } else {
          try {
            state = state.copyWith(user: null, isCheckingToken: false);
          } catch (_) {
            // StateNotifier уже удален, игнорируем
          }
        }
      },
      onError: (error) {
        debugPrint('Firebase Auth state changes error: $error');
        try {
          state = state.copyWith(user: null, isCheckingToken: false);
        } catch (_) {
          // StateNotifier уже удален, игнорируем
        }
      },
    );
  }

  Future<void> _loadUserFromToken() async {
    state = state.copyWith(isCheckingToken: true);
    try {
      // Ждем немного, чтобы Firebase Auth успел восстановить состояние (особенно на вебе)
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Проверяем Firebase Auth вместо токенов бэкенда
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        // Создаем User из Firebase User
        final user = await _createUserFromFirebase(firebaseUser);
        state = state.copyWith(isCheckingToken: false, user: user);
      } else {
        // На вебе может потребоваться больше времени для восстановления
        // Ждем еще немного и проверяем снова
        await Future.delayed(const Duration(milliseconds: 300));
        final firebaseUserRetry = FirebaseAuth.instance.currentUser;
        if (firebaseUserRetry != null) {
          final user = await _createUserFromFirebase(firebaseUserRetry);
          state = state.copyWith(isCheckingToken: false, user: user);
        } else {
          state = state.copyWith(isCheckingToken: false, user: null);
        }
      }
    } catch (e) {
      debugPrint('Error loading user from Firebase: $e');
      state = state.copyWith(isCheckingToken: false, user: null);
    }
  }

  /// Создает User из Firebase User
  /// Для подрядчиков используется роль CONTRACTOR_ADMIN по умолчанию
  /// Custom Claims можно добавить через Firebase Admin SDK
  Future<User> _createUserFromFirebase(firebase_auth.User firebaseUser) async {
    // Обновляем ID Token чтобы получить актуальные Custom Claims (если они есть)
    await firebaseUser.getIdToken(true);
    
    // Для простоты используем дефолтную роль для подрядчиков
    // Custom Claims можно добавить через Firebase Admin SDK:
    // admin.auth().setCustomUserClaims(uid, { role: 'CONTRACTOR_ADMIN', organizationId: '...' })
    // В будущем можно декодировать JWT токен для получения Custom Claims
    const String role = 'CONTRACTOR_ADMIN';
    String? organizationId;
    String? organization;

    return User(
      id: firebaseUser.uid,
      phone: firebaseUser.phoneNumber,
      role: role,
      organizationId: organizationId,
      organization: organization,
      isActive: true,
    );
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

  /// Авторизация через Firebase Phone Authentication (только Firebase, без бэкенда)
  /// Для подрядчиков используется роль CONTRACTOR_ADMIN
  Future<void> loginWithFirebasePhone(UserCredential userCredential, String phoneNumber) async {
    state = state.copyWith(isLoggingIn: true, error: null);
    try {
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('Firebase user is null');
      }

      if (phoneNumber.isEmpty) {
        throw Exception('Phone number is empty');
      }

      // Обновляем ID Token чтобы получить актуальные Custom Claims
      await firebaseUser.getIdToken(true);
      
      // Создаем User из Firebase User
      final user = await _createUserFromFirebase(firebaseUser);
      
      state = state.copyWith(isLoggingIn: false, user: user, error: null);
    } catch (e) {
      final errorMessage = e.toString();
      debugPrint('Firebase Phone Auth error: $errorMessage');
      state = state.copyWith(isLoggingIn: false, error: errorMessage);
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  Future<void> logout() async {
    try {
      // Выходим из Firebase Auth
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint('Firebase logout error: $e');
      // Игнорируем ошибки при logout, все равно очищаем локально
    } finally {
      // Очищаем токены (если они были)
      await TokenStorage.saveAccessToken('');
      await TokenStorage.saveRefreshToken('');
      // Очищаем сохраненный роут
      await RouteStorage.clearLastRoute();
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
