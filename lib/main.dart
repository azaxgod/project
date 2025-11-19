import 'package:akimat_project/core/app/app.dart';
import 'package:akimat_project/firebase_options.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Инициализация Firebase через FlutterFire CLI конфигурацию
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Настройка Firebase App Check
    // В debug режиме используем debug provider, в production - реальные провайдеры
    try {
      // Для веба в debug режиме не используем App Check (требует настройки reCAPTCHA)
      // Для production веба нужен reCAPTCHA ключ из Firebase Console
      if (kIsWeb && kDebugMode) {
        debugPrint('Firebase App Check: Skipping for web in debug mode');
        // Для веба в debug режиме можно не активировать App Check
        // или настроить debug token в Firebase Console
      } else {
        // Для Web - только в production, нужен reCAPTCHA ключ
        // Получите ключ в Firebase Console → App Check → Settings → Web apps
        if (kIsWeb && !kDebugMode) {
          // Для production веба нужен reCAPTCHA ключ
          await FirebaseAppCheck.instance.activate(
            androidProvider: AndroidProvider.playIntegrity,
            appleProvider: AppleProvider.appAttest,
            webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'), // Замените на ваш ключ из Firebase Console
          );
        } else {
          // Для мобильных платформ и веба в debug режиме
          await FirebaseAppCheck.instance.activate(
            androidProvider: kDebugMode
                ? AndroidProvider.debug
                : AndroidProvider.playIntegrity,
            appleProvider: kDebugMode
                ? AppleProvider.debug
                : AppleProvider.appAttest,
          );
        }
        
        debugPrint('Firebase App Check initialized in ${kDebugMode ? "DEBUG" : "PRODUCTION"} mode');
      }
    } catch (appCheckError) {
      debugPrint('Firebase App Check initialization error: $appCheckError');
      debugPrint('App Check будет работать в режиме без проверки');
      // Продолжаем работу даже если App Check не инициализирован
    }
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
    debugPrint('Убедитесь, что Firebase настроен правильно. См. FIREBASE_SETUP.md');
    // Продолжаем работу даже если Firebase не инициализирован
    // (для разработки, когда конфигурационные файлы еще не добавлены)
  }

  runApp(const ProviderScope(child: AkimatApp()));
}
