import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/l10n/l10n.dart';
import 'package:akimat_project/modules/auth/src/controller/auth_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Кнопка выхода из системы для веба
class LogoutButtonWeb extends ConsumerWidget {
  const LogoutButtonWeb({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context)!;
    final authNotifier = ref.read(authNotifierProvider.notifier);

    return IconButton(
      icon: const Icon(Icons.logout),
      tooltip: s.logout,
      color: AppColors.textSecondary,
      onPressed: () async {
        final shouldLogout = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(s.logout),
            content: Text(s.logout_confirmation),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(s.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(s.logout),
              ),
            ],
          ),
        );

        if (shouldLogout == true) {
          await authNotifier.logout();
          if (context.mounted) {
            context.go('/login');
          }
        }
      },
    );
  }
}

/// Кнопка выхода из системы для мобилки (в drawer)
class LogoutButtonMobile extends ConsumerWidget {
  const LogoutButtonMobile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context)!;
    final authNotifier = ref.read(authNotifierProvider.notifier);

    return Container(
      margin: const EdgeInsets.all(AppPadding.normal),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.separator,
            width: 0.5,
          ),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppPadding.normal,
          vertical: AppPadding.small,
        ),
        leading: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSize.smallRadius),
          ),
          child: const Icon(
            Icons.logout,
            color: Colors.red,
            size: 20,
          ),
        ),
        title: Text(
          s.logout,
          style: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 17,
            letterSpacing: -0.41,
            color: Colors.red,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSize.buttonRadius),
        ),
        onTap: () async {
          // Получаем router перед закрытием drawer
          final router = GoRouter.of(context);
          
          // Закрываем drawer
          Navigator.of(context).pop();
          
          // Небольшая задержка для закрытия drawer перед показом диалога
          await Future.delayed(const Duration(milliseconds: 150));
          
          // Используем root navigator для показа диалога
          final rootContext = Navigator.of(context, rootNavigator: true).context;
          
          if (!rootContext.mounted) return;
          
          final shouldLogout = await showDialog<bool>(
            context: rootContext,
            builder: (dialogContext) => AlertDialog(
              title: Text(s.logout),
              content: Text(s.logout_confirmation),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(s.cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: Text(s.logout),
                ),
              ],
            ),
          );

          if (shouldLogout == true) {
            await authNotifier.logout();
            // Используем router для навигации
            router.go('/login');
          }
        },
      ),
    );
  }
}

