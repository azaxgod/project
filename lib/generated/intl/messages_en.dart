// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
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
  String get localeName => 'en';

  static String m0(user) => "Logged in as ${user}";

  static String m1(error) => "Login error: ${error}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "enter_credentials": MessageLookupByLibrary.simpleMessage(
      "Please enter login and password",
    ),
    "home_title": MessageLookupByLibrary.simpleMessage("Home"),
    "loading": MessageLookupByLibrary.simpleMessage("Loading..."),
    "logged_in_as": m0,
    "loggin_button": MessageLookupByLibrary.simpleMessage("Log in"),
    "login": MessageLookupByLibrary.simpleMessage("Login"),
    "login_error": m1,
    "login_title": MessageLookupByLibrary.simpleMessage("Akimat Authorization"),
    "logout": MessageLookupByLibrary.simpleMessage("Logout"),
    "network_error": MessageLookupByLibrary.simpleMessage(
      "Network error. Please check your internet connection",
    ),
    "password": MessageLookupByLibrary.simpleMessage("Password"),
    "sign_in": MessageLookupByLibrary.simpleMessage("Sign In"),
    "try_again": MessageLookupByLibrary.simpleMessage("Try again"),
    "user_not_found": MessageLookupByLibrary.simpleMessage("User not found"),
    "welcome_back": MessageLookupByLibrary.simpleMessage("Welcome back!"),
    "wrong_credentials": MessageLookupByLibrary.simpleMessage(
      "wrong credentails",
    ),
  };
}
