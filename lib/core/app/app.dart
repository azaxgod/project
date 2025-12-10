import 'package:akimat_project/core/locale/custom_localization_delegate.dart';
import 'package:akimat_project/core/locale/locale_provider.dart';
import 'package:akimat_project/core/routes/app_routes.dart';
import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_theme.dart';
import 'package:akimat_project/core/ui/widgets/notification_overlay.dart';
import 'package:akimat_project/core/ui/widgets/session_expired_dialog.dart';
import 'package:akimat_project/core/utils/notification_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AkimatApp extends ConsumerStatefulWidget {
  const AkimatApp({super.key});

  @override
  ConsumerState<AkimatApp> createState() => _AkimatAppState();
}

class _AkimatAppState extends ConsumerState<AkimatApp> {
  late final NotificationController _notificationController;

  @override
  void initState() {
    super.initState();
    _notificationController = NotificationController();
    // Инициализируем глобальный контроллер для удобного доступа
    NotificationHelper.init(_notificationController);
  }

  @override
  void dispose() {
    _notificationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final routerAsync = ref.watch(appRouterProvider);
    final locale = ref.watch(localeProvider);

    return routerAsync.when(
      data: (router) {
        // Устанавливаем navigator key для показа модального окна сессии
        WidgetsBinding.instance.addPostFrameCallback((_) {
          SessionExpiredService.setNavigatorKey(router.routerDelegate.navigatorKey);
        });
        
        return NotificationOverlay(
          controller: _notificationController,
          child: Builder(
            builder: (context) {
              // Сохраняем контекст после первой отрисовки для показа модального окна сессии
              WidgetsBinding.instance.addPostFrameCallback((_) {
                SessionExpiredService.setContext(context);
              });
              return MaterialApp.router(
                key: ValueKey(locale.languageCode), // Force rebuild when locale changes
                title: 'Akimat Project',
                debugShowCheckedModeBanner: false,
                routerConfig: router,
                theme: AppTheme.lightTheme,
                localizationsDelegates: const [
                  CustomLocalizationDelegate(),
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: const [
                  Locale.fromSubtags(languageCode: 'en'),
                  Locale.fromSubtags(languageCode: 'ru'),
                  Locale.fromSubtags(languageCode: 'kk'),
                ],
                locale: locale,
              );
            },
          ),
        );
      },
      loading: () => NotificationOverlay(
        controller: _notificationController,
        child: MaterialApp(
          title: 'Akimat Project',
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('Загрузка...', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
          ),
        ),
      ),
      error: (error, stack) => NotificationOverlay(
        controller: _notificationController,
        child: MaterialApp(
          title: 'Akimat Project',
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Ошибка загрузки: $error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(appRouterProvider),
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
