import 'package:akimat_project/core/locale/custom_localization_delegate.dart';
import 'package:akimat_project/core/locale/locale_provider.dart';
import 'package:akimat_project/core/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../core/app/app_routes.dart';

class AkimatApp extends ConsumerWidget {
  const AkimatApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
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
      // This ensures MaterialApp doesn't show warnings about unsupported locales
      // The Global delegates support these locales by default
      locale: locale,
    );
  }
}
