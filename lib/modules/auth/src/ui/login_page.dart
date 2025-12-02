import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/core/ui/app_textstyle.dart';
import 'package:akimat_project/core/widgets/app_footer.dart';
import 'package:akimat_project/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../controller/auth_notifier.dart';
import 'phone_login_widget.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  late final TextEditingController loginController;
  late final TextEditingController passwordController;
  late final TabController tabController;

  @override
  void initState() {
    super.initState();
    loginController = TextEditingController();
    passwordController = TextEditingController();
    tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    loginController.dispose();
    passwordController.dispose();
    tabController.dispose();
    super.dispose();
  }

  Future<void> handleLogin() async {
    final login = loginController.text.trim();
    final password = passwordController.text.trim();

    if (login.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context)!.enter_login_password)),
      );
      return;
    }

    await ref.read(authNotifierProvider.notifier).loginAkimat(login, password);

    if (!mounted) return;

    final authState = ref.read(authNotifierProvider);
    if (authState.user != null) {
      context.go('/home');
    } else if (authState.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authState.error!),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context)!.wrong_credentials)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoggingIn = authState.isLoggingIn;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Основной контент
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppPadding.large),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSize.cardRadius)),
                    elevation: 6,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [

                        Container(
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.vertical(
                                top: Radius.circular(AppSize.cardRadius)),
                          ),
                          height: 170,
                          width: 500,
                          padding: const EdgeInsets.symmetric(
                              vertical: AppPadding.large),
                          child: Column(
                            children: [
                              Icon(
                                Icons.ac_unit,
                                color: AppColors.background,
                                size: 70,
                              ),
                              const SizedBox(height: AppPadding.small),
                              Text(
                                S.of(context)!.sistem_control_sneg,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.title
                                    .copyWith(color: Colors.white),
                              ),
                            ],
                          ),
                        ),


                        TabBar(
                          controller: tabController,
                          labelColor: AppColors.primary,
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: AppColors.primary,
                          tabs: [
                            Tab(text: S.of(context)!.login_title),
                            const Tab(text: 'По номеру телефона'),
                          ],
                        ),

                        // Контент табов
                        Padding(
                          padding: const EdgeInsets.all(AppPadding.large),
                          child: SizedBox(
                            height: 350,
                            child: TabBarView(
                              controller: tabController,
                              children: [
                                // Таб 1: Авторизация по логину/паролю
                                buildLoginForm(isLoggingIn),
                                // Таб 2: Авторизация по номеру телефона
                                PhoneLoginWidget(
                                  onCodeSent: (phone) {
                                    // Код отправлен, можно показать сообщение
                                  },
                                  onVerified: (userCredential, phone) async {
                                    // После успешной верификации Firebase, авторизуемся через Firebase Phone Auth
                                    await ref.read(authNotifierProvider.notifier).loginWithFirebasePhone(userCredential, phone);
                                    if (!mounted) return;
                                    final authState = ref.read(authNotifierProvider);
                                    if (authState.user != null) {
                                      context.go('/home');
                                    } else if (authState.error != null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(authState.error!),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Футер с версией
          const AppFooter(),
        ],
      ),
    );
  }

  Widget buildLoginForm(bool isLoggingIn) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        TextField(
          controller: loginController,
          decoration: InputDecoration(
            labelText: S.of(context)!.login_title,
            labelStyle: AppTextStyles.body,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSize.cardRadius),
            ),
          ),
        ),
        const SizedBox(height: AppPadding.normal),
        TextField(
          controller: passwordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: S.of(context)!.password,
            labelStyle: AppTextStyles.body,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSize.cardRadius),
            ),
          ),
        ),
        const SizedBox(height: AppPadding.large),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: isLoggingIn
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSize.cardRadius)),
                  ),
                  child: Text(
                    S.of(context)!.login_button,
                    style: AppTextStyles.button,
                  ),
                ),
        ),
      ],
    );
  }
}
