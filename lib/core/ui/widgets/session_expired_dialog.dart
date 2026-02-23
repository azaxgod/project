import 'package:flutter/material.dart';
import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/core/ui/widgets/animated_button.dart';
import 'package:go_router/go_router.dart';

/// Глобальный сервис для показа модального окна истекшей сессии
class SessionExpiredService {
  static BuildContext? _context;
  static GlobalKey<NavigatorState>? _navigatorKey;
  static bool _isShowing = false;

  /// Установить контекст для показа диалога
  static void setContext(BuildContext context) {
    _context = context;
  }

  /// Установить navigator key для показа диалога
  static void setNavigatorKey(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
  }
    
  /// Показать модальное окно истекшей сессии
  static void show() {
    if (_isShowing) return; // Не показываем несколько раз
    
    _isShowing = true;
    
    BuildContext? dialogContext;
    
    // Пытаемся использовать root navigator key
    if (_navigatorKey?.currentContext != null) {
      dialogContext = _navigatorKey!.currentContext;
    } else if (_context != null) {
        // Используем сохраненный контекст с root navigator
      try {
        dialogContext = Navigator.of(_context!, rootNavigator: true).context;
      } catch (e) {
        debugPrint('SessionExpiredService: Error getting navigator context: $e');
      }
    }
    
    if (dialogContext == null) {
      debugPrint('SessionExpiredService: Context is null, cannot show dialog. Retrying...');
      _isShowing = false;
      // Попробуем еще раз через небольшую задержку
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!_isShowing) {
          show();
        }
      });
      return;
    }
    
    // Проверяем, не находимся ли мы уже на странице логина
    try {
      final currentRoute = GoRouter.of(dialogContext).routerDelegate.currentConfiguration.uri.toString();
      if (currentRoute == '/login' || currentRoute.startsWith('/login')) {
        debugPrint('SessionExpiredService: Already on login page, not showing dialog');
        _isShowing = false;
        return;
      }
      
    } catch (e) {
      debugPrint('SessionExpiredService: Error checking current route: $e');
      // Продолжаем показ диалога, если не удалось проверить роут
    }
    
    SessionExpiredDialog.show(dialogContext).then((_) {
      _isShowing = false;
    }).catchError((error) {
      debugPrint('SessionExpiredService: Error showing dialog: $error');
      _isShowing = false;
    });
  }
}

/// Модальное окно истекшей сессии
class SessionExpiredDialog extends StatelessWidget {
  const SessionExpiredDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Нельзя закрыть кнопкой назад
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSize.cardRadius),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSize.cardRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.background,
                AppColors.background.withOpacity(0.95),
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Иконка
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.errorGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.error.withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.lock_outline,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 24),
              
              // Заголовок
              Text(
                'Сессия завершена',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              
              // Текст
              Text(
                'Сессия завершена. Нажмите кнопку "Обновить".',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Кнопка обновить
              SizedBox(
                width: double.infinity,
                child: AnimatedButton(
                  label: 'Обновить',
                  onPressed: () {
                    // Перенаправляем на страницу логина
                    context.go('/login');
                  },
                  useBlackText: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Показать модальное окно
  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false, // Нельзя закрыть кликом вне окна
      builder: (context) => const SessionExpiredDialog(),
    );
  }
}

