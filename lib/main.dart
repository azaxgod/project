import 'package:akimat_project/core/app/app.dart';
import 'package:akimat_project/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Инициализация Firebase через FlutterFire CLI конфигурацию
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
    debugPrint('Убедитесь, что Firebase настроен правильно. См. FIREBASE_SETUP.md');
    // Продолжаем работу даже если Firebase не инициализирован
    // (для разработки, когда конфигурационные файлы еще не добавлены)
  }

  runApp(const ProviderScope(child: AkimatApp()));
}
