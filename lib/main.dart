import 'package:akimat_project/core/app/app.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Инициализация Firebase
  try {
    if (kIsWeb) {
      // Для веба нужно явно указать FirebaseOptions
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyBYy_rqZMZQ_aGcUPP2exKRwWB8m3FHj58",
          authDomain: "smsakimat.firebaseapp.com",
          projectId: "smsakimat",
          storageBucket: "smsakimat.firebasestorage.app",
          messagingSenderId: "1056160130840",
          appId: "1:1056160130840:web:d977b411f03d870199a06d",
          measurementId: "G-DVYV2E6NH0",
        ),
      );
    } else {
      // Для мобильных платформ конфигурация загружается автоматически из:
      // - android/app/google-services.json (Android)
      // - ios/Runner/GoogleService-Info.plist (iOS)
      await Firebase.initializeApp();
    }
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
    debugPrint('Убедитесь, что Firebase настроен правильно. См. FIREBASE_SETUP.md');
    // Продолжаем работу даже если Firebase не инициализирован
    // (для разработки, когда конфигурационные файлы еще не добавлены)
  }

  runApp(const ProviderScope(child: AkimatApp()));
}
