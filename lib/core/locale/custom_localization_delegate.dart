import 'package:akimat_project/generated/l10n.dart';
import 'package:akimat_project/generated/l10n_en.dart';
import 'package:akimat_project/generated/l10n_ru.dart';
import 'package:akimat_project/generated/l10n_kk.dart';
import 'package:flutter/material.dart';

class CustomLocalizationDelegate extends LocalizationsDelegate<S> {
  const CustomLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'ru'),
      Locale.fromSubtags(languageCode: 'kk'),
    ];
  }

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ru', 'kk'].contains(locale.languageCode);
  }

  @override
  Future<S> load(Locale locale) async {
    // Initialize messages for the locale
    await S.loadMessages(locale);
    
    // Return the appropriate locale-specific class
    S instance;
    switch (locale.languageCode) {
      case 'ru':
        instance = SRu();
        break;
      case 'kk':
        instance = SKk();
        break;
      case 'en':
      default:
        instance = SEn();
        break;
    }
    
    // Set the current instance for S.current access
    S.setCurrent(instance);
    
    return instance;
  }

  @override
  bool shouldReload(CustomLocalizationDelegate old) => true;
}

