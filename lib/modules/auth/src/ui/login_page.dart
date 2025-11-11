import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/core/ui/app_textstyle.dart';
import 'package:akimat_project/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../controller/auth_notifier.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  late final TextEditingController loginController;
  late final TextEditingController passwordController;

  @override
  void initState() {
    super.initState();
    loginController = TextEditingController();
    passwordController = TextEditingController();
  }

  @override
  void dispose() {
    loginController.dispose();
    passwordController.dispose();
    super.dispose();
  }

Future<void> handleLogin() async {
  final login = loginController.text.trim();
  final password = passwordController.text.trim();

  if (login.isEmpty || password.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(S.of(context).enter_credentials)),
    );
    return;
  }


  await ref.read(authNotifierProvider.notifier).loginAkimat(login, password);

  if (!mounted) return;


  final authState = ref.read(authNotifierProvider);
  if (authState.user != null) {
    context.go('/home');
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(S.of(context).wrong_credentials)),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoggingIn = authState.isLoggingIn;
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          S.of(context).login_title,
          style: AppTextStyles.title.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppPadding.large),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: loginController,
                  decoration: InputDecoration(
                    labelText: S.of(context).enter_credentials,
                    labelStyle: AppTextStyles.body,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSize.cardRadius),
                    ),
                  ),
                ),
                const SizedBox(height: AppPadding.normall),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: S.of(context).password,
                    labelStyle: AppTextStyles.body,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSize.cardRadius),
                    ),
                  ),
                ),
                const SizedBox(height: AppPadding.large),
                isLoggingIn
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          minimumSize:
                              const Size(double.infinity, AppSize.buttonHeight * 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSize.cardRadius),
                          ),
                        ),
                        child: Text(
                          S.of(context).loggin_button,
                          style: AppTextStyles.button,
                        ),
                      ),
                const SizedBox(height: AppPadding.large),
                if (user != null)
                  Text(
                    '${S.of(context).logged_in_as}: ${user.login}',
                    style: AppTextStyles.body.copyWith(color: Colors.green),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
