import 'package:akimat_project/core/locale/locale_provider.dart';
import 'package:akimat_project/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LanguageSwitcher extends ConsumerWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final notifier = ref.read(localeProvider.notifier);

    return PopupMenuButton<Locale>(
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.language),
          const SizedBox(width: 4),
          Text(
            _getLanguageCode(currentLocale.languageCode),
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
      tooltip: 'Выбрать язык / Select language / Тілді таңдау',
      onSelected: (Locale locale) {
        notifier.setLocale(locale);
      },
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<Locale>(
          value: const Locale.fromSubtags(languageCode: 'ru'),
          child: Row(
            children: [
              if (currentLocale.languageCode == 'ru')
                const Icon(Icons.check, size: 20, color: Colors.blue)
              else
                const SizedBox(width: 20),
              const SizedBox(width: 8),
              const Text('Русский'),
            ],
          ),
        ),
        PopupMenuItem<Locale>(
          value: const Locale.fromSubtags(languageCode: 'en'),
          child: Row(
            children: [
              if (currentLocale.languageCode == 'en')
                const Icon(Icons.check, size: 20, color: Colors.blue)
              else
                const SizedBox(width: 20),
              const SizedBox(width: 8),
              const Text('English'),
            ],
          ),
        ),
        PopupMenuItem<Locale>(
          value: const Locale.fromSubtags(languageCode: 'kk'),
          child: Row(
            children: [
              if (currentLocale.languageCode == 'kk')
                const Icon(Icons.check, size: 20, color: Colors.blue)
              else
                const SizedBox(width: 20),
              const SizedBox(width: 8),
              const Text('Қазақша'),
            ],
          ),
        ),
      ],
    );
  }

  String _getLanguageCode(String code) {
    switch (code) {
      case 'ru':
        return 'RU';
      case 'en':
        return 'EN';
      case 'kk':
        return 'KK';
      default:
        return code.toUpperCase();
    }
  }
}

