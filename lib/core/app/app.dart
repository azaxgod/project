import 'package:akimat_project/core/locale/custom_localization_delegate.dart';
import 'package:akimat_project/core/locale/locale_provider.dart';
import 'package:akimat_project/core/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AkimatApp extends ConsumerWidget {
  const AkimatApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routerAsync = ref.watch(appRouterProvider);
    final locale = ref.watch(localeProvider);

    return routerAsync.when(
      data: (router) => MaterialApp.router(
        key: ValueKey(locale.languageCode), // Force rebuild when locale changes
        title: 'Akimat Project',
        debugShowCheckedModeBanner: false,
        routerConfig: router,
        theme: ThemeData(primarySwatch: Colors.blue),
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
      ),
      loading: () => MaterialApp(
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
      error: (error, stack) => MaterialApp(
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
    );
  }
}
