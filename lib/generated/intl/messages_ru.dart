// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a ru locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'ru';

  static String m0(user) => "Вы вошли как";

  static String m1(error) => "Ошибка входа: ${error}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "enter_credentials": MessageLookupByLibrary.simpleMessage(
      "Введите логин и пароль",
    ),
    "home_title": MessageLookupByLibrary.simpleMessage("Главная страница"),
    "loading": MessageLookupByLibrary.simpleMessage("Загрузка..."),
    "logged_in_as": m0,
    "loggin_button": MessageLookupByLibrary.simpleMessage("Войти"),
    "login": MessageLookupByLibrary.simpleMessage("Логин"),
    "login_error": m1,
    "login_title": MessageLookupByLibrary.simpleMessage("Авторизация Akimat"),
    "logout": MessageLookupByLibrary.simpleMessage("Выйти"),
    "network_error": MessageLookupByLibrary.simpleMessage(
      "Ошибка сети. Проверьте подключение к интернету",
    ),
    "password": MessageLookupByLibrary.simpleMessage("Пароль"),
    "try_again": MessageLookupByLibrary.simpleMessage("Попробовать снова"),
    "user_not_found": MessageLookupByLibrary.simpleMessage(
      "Пользователь не найден",
    ),
    "welcome_back": MessageLookupByLibrary.simpleMessage("С возвращением!"),
    "wrong_credentials": MessageLookupByLibrary.simpleMessage("неправильно"),
  };
}
