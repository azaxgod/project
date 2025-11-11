import 'package:akimat_project/core/platform/platform_config_web.dart';
import 'package:akimat_project/core/platform/platform_utils.dart' hide PlatformConfigWeb;
import 'package:akimat_project/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../controller/auth_notifier.dart';
import 'home_router.dart';
// import '../../core/platform/platform_config.dart'; // 👈 добавь этот импорт

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final loginController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;

  Future<void> _login() async {
    final login = loginController.text.trim();
    final password = passwordController.text.trim();

    if (login.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите логин и пароль')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await ref.read(authNotifierProvider.notifier).loginAkimat(login, password);
      final user = ref.read(authNotifierProvider);

      if (user != null && mounted) {
      context.go('/home');
    } 
    }
    catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка входа: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = PlatformConfig.instance; 
    final user = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: config.backgroundColor, 
      appBar: AppBar(title: const Text('Авторизация Akimat')),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(config.padding * 2), 
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: config is PlatformConfigWeb ? 400 : double.infinity,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: loginController,
                  decoration: InputDecoration(labelText: S.of(context).enter_credentials),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Пароль'),
                ),
                const SizedBox(height: 24),
                isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        child: const Text('Войти'),
                      ),
                const SizedBox(height: 24),
                if (user != null)
                  Text(
                    'Вы вошли как: ${user.login}',
                    style: const TextStyle(color: Colors.green),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
