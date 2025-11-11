// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a kk locale. All the
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
  String get localeName => 'kk';

  static String m0(user) => "${user} ретінде кірдіңіз";

  static String m1(error) => "Кіру қатесі: ${error}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "enter_credentials": MessageLookupByLibrary.simpleMessage(
      "Логин мен құпия сөзді енгізіңіз",
    ),
    "home_title": MessageLookupByLibrary.simpleMessage("Басты бет"),
    "loading": MessageLookupByLibrary.simpleMessage("Жүктелуде..."),
    "logged_in_as": m0,
    "login": MessageLookupByLibrary.simpleMessage("Логин"),
    "login_error": m1,
    "login_title": MessageLookupByLibrary.simpleMessage("Akimat авторизациясы"),
    "logout": MessageLookupByLibrary.simpleMessage("Шығу"),
    "network_error": MessageLookupByLibrary.simpleMessage(
      "Желі қатесі. Интернет байланысын тексеріңіз",
    ),
    "password": MessageLookupByLibrary.simpleMessage("Құпия сөз"),
    "sign_in": MessageLookupByLibrary.simpleMessage("Кіру"),
    "try_again": MessageLookupByLibrary.simpleMessage("Қайта көру"),
    "user_not_found": MessageLookupByLibrary.simpleMessage(
      "Пайдаланушы табылмады",
    ),
    "welcome_back": MessageLookupByLibrary.simpleMessage("Қайта оралдыңыз!"),
    "wrong_credentials": MessageLookupByLibrary.simpleMessage("Дурыс емес"),
  };
}
