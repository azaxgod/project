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

  static String m0(error) => "Login error: ${error}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "areas": MessageLookupByLibrary.simpleMessage("Cleaning Areas"),
    "dashboard": MessageLookupByLibrary.simpleMessage("Dashboard"),
    "enter_login_password": MessageLookupByLibrary.simpleMessage(
      "Enter login and password",
    ),
    "home_title": MessageLookupByLibrary.simpleMessage("Home page"),
    "loading": MessageLookupByLibrary.simpleMessage("Loading..."),
    "logged_in_as": MessageLookupByLibrary.simpleMessage("Logged in as"),
    "login": MessageLookupByLibrary.simpleMessage("Login"),
    "login_button": MessageLookupByLibrary.simpleMessage("Login"),
    "login_error": m0,
    "login_title": MessageLookupByLibrary.simpleMessage("Akimat Login"),
    "logout": MessageLookupByLibrary.simpleMessage("Logout"),
    "network_error": MessageLookupByLibrary.simpleMessage(
      "Network error. Check your internet connection",
    ),
    "organizations": MessageLookupByLibrary.simpleMessage("Organizations"),
    "password": MessageLookupByLibrary.simpleMessage("Password"),
    "polygons": MessageLookupByLibrary.simpleMessage("Polygons & Cameras"),
    "reports": MessageLookupByLibrary.simpleMessage("Reports"),
    "sistem_control_sneg": MessageLookupByLibrary.simpleMessage(
      "sistem control of snow",
    ),
    "tickets": MessageLookupByLibrary.simpleMessage("Tasks (Tickets)"),
    "trips": MessageLookupByLibrary.simpleMessage("Trips & Violations"),
    "try_again": MessageLookupByLibrary.simpleMessage("Try again"),
    "user_not_found": MessageLookupByLibrary.simpleMessage("User not found"),
    "welcome_back": MessageLookupByLibrary.simpleMessage("Welcome back!"),
    "wrong_credentials": MessageLookupByLibrary.simpleMessage(
      "Wrong login or password",
    ),
  };
}
