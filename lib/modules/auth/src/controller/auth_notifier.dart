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
import 'package:akimat_project/services/auth/collection/auth_collection.dart' show AuthException;
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
  Timer? _tokenCheckTimer;

  AuthNotifier(this.repo) : super(const AuthState()) {
    _initAuthListener();
    _startTokenCheck();
  }
  
  /// Периодическая проверка токена (каждые 30 секунд)
  void _startTokenCheck() {
    _tokenCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      await _checkTokenValidity();
    });
  }
  
  /// Проверяет валидность токена и разлогинивает, если токен был очищен
  Future<void> _checkTokenValidity() async {
    // Проверяем только если пользователь авторизован
    if (state.user == null) return;
    
    final accessToken = await TokenStorage.getAccessToken();
    final refreshToken = await TokenStorage.getRefreshToken();
    
    // Если токены были очищены (например, при неудачном refresh), разлогиниваем
    if ((accessToken == null || accessToken.isEmpty) && 
        (refreshToken == null || refreshToken.isEmpty)) {
      debugPrint('AuthNotifier: Tokens were cleared, logging out user');
      await logout();
    }
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

            }
          }
        } else {
          try {
            state = state.copyWith(user: null, isCheckingToken: false);
          } catch (_) {

          }
        }
      },
      onError: (error) {
        debugPrint('Firebase Auth state changes error: $error');
        try {
          state = state.copyWith(user: null, isCheckingToken: false);
        } catch (_) { 

        }
      },
    );
  }

  Future<void> _loadUserFromToken() async {
    state = state.copyWith(isCheckingToken: true);
    try {

      final accessToken = await TokenStorage.getAccessToken();
      if (accessToken != null && accessToken.isNotEmpty) {
        debugPrint('AuthNotifier: Found access token, restoring user from backend');
        try {

          final authResponse = await repo.meFromToken(accessToken);
          state = state.copyWith(
            isCheckingToken: false,
            user: authResponse.user,
          );
          debugPrint('AuthNotifier: User restored from backend token: ${authResponse.user.role}');
          return;
        } catch (e) {
          debugPrint('AuthNotifier: Error restoring user from token: $e');
          // Если токен невалидный, очищаем его
          await TokenStorage.saveAccessToken('');
          await TokenStorage.saveRefreshToken('');
        }
      }
      
      // Если токена нет или он невалидный, проверяем Firebase Auth (для мобильных устройств)
      debugPrint('AuthNotifier: No valid backend token, checking Firebase Auth...');
      await Future.delayed(const Duration(milliseconds: 500));
      
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        debugPrint('AuthNotifier: Firebase user found, creating User object');
        // Создаем User из Firebase User
        final user = await _createUserFromFirebase(firebaseUser);
        state = state.copyWith(isCheckingToken: false, user: user);
        debugPrint('AuthNotifier: User restored from Firebase: ${user.role}');
      } else {
        // На вебе может потребоваться еще больше времени для восстановления
        // Ждем еще и проверяем снова (до 2 секунд)
        debugPrint('AuthNotifier: No Firebase user found, waiting longer...');
        for (int i = 0; i < 5; i++) {
          await Future.delayed(const Duration(milliseconds: 300));
          final firebaseUserRetry = FirebaseAuth.instance.currentUser;
          if (firebaseUserRetry != null) {
            debugPrint('AuthNotifier: Firebase user found on retry $i');
            final user = await _createUserFromFirebase(firebaseUserRetry);
            state = state.copyWith(isCheckingToken: false, user: user);
            debugPrint('AuthNotifier: User restored successfully on retry: ${user.role}');
            return;
          }
        }
        debugPrint('AuthNotifier: No user found after all retries');
        state = state.copyWith(isCheckingToken: false, user: null);
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading user: $e');
      debugPrint('Stack trace: $stackTrace');
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

  String? _verificationId;
  String? _phoneNumber; // Сохраняем номер для верификации

  /// Отправка SMS-кода через Firebase Phone Authentication
  Future<void> sendSms(String phone) async {
    state = state.copyWith(isLoggingIn: true, error: null);
    try {
      // Нормализуем номер телефона (добавляем + если нужно)
      String normalizedPhone = phone.trim();
      if (!normalizedPhone.startsWith('+')) {
        // Если номер начинается с 8, заменяем на +7
        if (normalizedPhone.startsWith('8')) {
          normalizedPhone = '+7${normalizedPhone.substring(1)}';
        } else if (normalizedPhone.startsWith('7')) {
          normalizedPhone = '+$normalizedPhone';
        } else {
          // Предполагаем, что это казахстанский номер
          normalizedPhone = '+7$normalizedPhone';
        }
      }

      debugPrint('AuthNotifier: Sending SMS to: $normalizedPhone');
      
      // Отправляем код через Firebase Phone Authentication
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: normalizedPhone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Автоматическая верификация (на Android)
          debugPrint('AuthNotifier: Auto verification completed');
          try {
            final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
            if (userCredential.user != null) {
              final user = await _createUserFromFirebase(userCredential.user!);
              state = state.copyWith(isLoggingIn: false, user: user, error: null);
            }
          } catch (e) {
            debugPrint('AuthNotifier: Error in auto verification: $e');
            state = state.copyWith(isLoggingIn: false, error: e.toString());
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('AuthNotifier: Verification failed: ${e.code} - ${e.message}');
          String errorMessage = 'Ошибка отправки SMS';
          if (e.code == 'invalid-phone-number') {
            errorMessage = 'Неверный номер телефона';
          } else if (e.code == 'too-many-requests') {
            errorMessage = 'Слишком много запросов. Попробуйте позже';
          } else if (e.code == 'quota-exceeded') {
            errorMessage = 'Превышен лимит запросов. Попробуйте позже';
          } else {
            errorMessage = e.message ?? 'Ошибка отправки SMS';
          }
          state = state.copyWith(isLoggingIn: false, error: errorMessage);
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('AuthNotifier: Code sent, verificationId: $verificationId');
          _verificationId = verificationId;
          _phoneNumber = normalizedPhone; // Сохраняем нормализованный номер
          state = state.copyWith(isLoggingIn: false, error: null);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('AuthNotifier: Code auto retrieval timeout');
          _verificationId = verificationId;
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      debugPrint('AuthNotifier: Error sending SMS: $e');
      final errorMessage = e.toString();
      state = state.copyWith(isLoggingIn: false, error: errorMessage);
    }
  }

  /// Верификация SMS-кода через Firebase Phone Authentication
  Future<void> verifySms(String phone, String code) async {
    if (_verificationId == null) {
      state = state.copyWith(isLoggingIn: false, error: 'Сначала запросите код');
      return;
    }

    state = state.copyWith(isLoggingIn: true, error: null);
    try {
      debugPrint('AuthNotifier: Verifying code with verificationId: $_verificationId');
      
      // Создаем credential из verificationId и кода
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: code.trim(),
      );

      // Входим с credential
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        debugPrint('AuthNotifier: Phone verification successful');
        
        // Создаем User из Firebase User
        final user = await _createUserFromFirebase(userCredential.user!);
        
        // Получаем ID Token для отправки на бэкенд (если нужно)
        final idToken = await userCredential.user!.getIdToken();
        if (idToken == null || idToken.isEmpty) {
          throw Exception('Failed to get Firebase ID token');
        }
        
        // Пробуем отправить Firebase ID Token на бэкенд для получения токенов бэкенда
        try {
          // Используем сохраненный номер или переданный
          final phoneForBackend = _phoneNumber != null ? _phoneNumber! : phone.trim();
          if (phoneForBackend.isEmpty) {
            throw Exception('Phone number is required');
          }
          final authResponse = await repo.loginWithFirebaseToken(idToken, phoneForBackend);
          // Сохраняем токены бэкенда
          if (authResponse.accessToken.isNotEmpty) {
            await TokenStorage.saveAccessToken(authResponse.accessToken);
          }
          if (authResponse.refreshToken.isNotEmpty) {
            await TokenStorage.saveRefreshToken(authResponse.refreshToken);
          }
          state = state.copyWith(isLoggingIn: false, user: authResponse.user, error: null);
        } catch (e) {
          // Если бэкенд не поддерживает Firebase token, используем User из Firebase
          debugPrint('AuthNotifier: Backend login failed, using Firebase user: $e');
          state = state.copyWith(isLoggingIn: false, user: user, error: null);
        }
        
        // Очищаем verificationId
        _verificationId = null;
        _phoneNumber = null;
      } else {
        throw Exception('User credential is null');
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthNotifier: Firebase verification error: ${e.code} - ${e.message}');
      String errorMessage = 'Неверный код';
      if (e.code == 'invalid-verification-code') {
        errorMessage = 'Неверный код подтверждения';
      } else if (e.code == 'session-expired') {
        errorMessage = 'Сессия истекла. Запросите новый код';
        _verificationId = null;
        _phoneNumber = null;
      } else {
        errorMessage = e.message ?? 'Ошибка верификации';
      }
      state = state.copyWith(isLoggingIn: false, error: errorMessage);
    } catch (e) {
      debugPrint('AuthNotifier: Error verifying SMS: $e');
      final errorMessage = e.toString();
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
    _tokenCheckTimer?.cancel();
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
