import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controller/auth_notifier.dart';
import 'home_router.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final loginController = TextEditingController();
  final passwordController = TextEditingController();

  void _login() async {
    try {
      await ref.read(authNotifierProvider.notifier)
          .loginAkimat(loginController.text, passwordController.text);
      // Перенаправление на HomeRouter
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeRouter()));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Ошибка логина')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            TextField(controller: loginController, decoration: const InputDecoration(labelText: 'Логин')),
            TextField(controller: passwordController, decoration: const InputDecoration(labelText: 'Пароль'), obscureText: true),
            ElevatedButton(onPressed: _login, child: const Text('Войти')),
          ],
        ),
      ),
    );
  }
}
