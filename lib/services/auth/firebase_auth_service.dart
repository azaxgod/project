import 'package:firebase_auth/firebase_auth.dart';

/// Сервис для Firebase SMS-авторизации
/// Используется для интеграции с Firebase Phone Authentication
class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Отправить SMS-код на номер телефона
  /// phoneNumber должен быть в формате +7XXXXXXXXXX
  Future<void> sendSmsCode(String phoneNumber) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Автоматическая верификация (Android)
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        throw Exception('Ошибка отправки SMS: ${e.message}');
      },
      codeSent: (String verificationId, int? resendToken) {
        // Код отправлен, сохраняем verificationId для верификации
        _verificationId = verificationId;
        _resendToken = resendToken;
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
      timeout: const Duration(seconds: 60),
    );
  }

  String? _verificationId;
  int? _resendToken;

  /// Верифицировать SMS-код
  Future<UserCredential> verifySmsCode(String smsCode) async {
    if (_verificationId == null) {
      throw Exception('Сначала отправьте SMS-код');
    }

    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: smsCode,
    );

    return await _auth.signInWithCredential(credential);
  }

  /// Получить текущего пользователя Firebase
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// Выйти из Firebase
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Получить номер телефона текущего пользователя
  String? getPhoneNumber() {
    return _auth.currentUser?.phoneNumber;
  }
}

