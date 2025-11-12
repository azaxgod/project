// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(
      _current != null,
      'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.',
    );
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(
      instance != null,
      'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?',
    );
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `Akimat Login`
  String get login_title {
    return Intl.message(
      'Akimat Login',
      name: 'login_title',
      desc: '',
      args: [],
    );
  }

  /// `Login`
  String get login {
    return Intl.message('Login', name: 'login', desc: '', args: []);
  }

  /// `Password`
  String get password {
    return Intl.message('Password', name: 'password', desc: '', args: []);
  }

  /// `Enter login and password`
  String get enter_login_password {
    return Intl.message(
      'Enter login and password',
      name: 'enter_login_password',
      desc: '',
      args: [],
    );
  }

  /// `Login`
  String get login_button {
    return Intl.message('Login', name: 'login_button', desc: '', args: []);
  }

  /// `Wrong login or password`
  String get wrong_credentials {
    return Intl.message(
      'Wrong login or password',
      name: 'wrong_credentials',
      desc: '',
      args: [],
    );
  }

  /// `Login error: {error}`
  String login_error(Object error) {
    return Intl.message(
      'Login error: $error',
      name: 'login_error',
      desc: '',
      args: [error],
    );
  }

  /// `User not found`
  String get user_not_found {
    return Intl.message(
      'User not found',
      name: 'user_not_found',
      desc: '',
      args: [],
    );
  }

  /// `Logged in as`
  String get logged_in_as {
    return Intl.message(
      'Logged in as',
      name: 'logged_in_as',
      desc: '',
      args: [],
    );
  }

  /// `Loading...`
  String get loading {
    return Intl.message('Loading...', name: 'loading', desc: '', args: []);
  }

  /// `Logout`
  String get logout {
    return Intl.message('Logout', name: 'logout', desc: '', args: []);
  }

  /// `Home page`
  String get home_title {
    return Intl.message('Home page', name: 'home_title', desc: '', args: []);
  }

  /// `Welcome back!`
  String get welcome_back {
    return Intl.message(
      'Welcome back!',
      name: 'welcome_back',
      desc: '',
      args: [],
    );
  }

  /// `Network error. Check your internet connection`
  String get network_error {
    return Intl.message(
      'Network error. Check your internet connection',
      name: 'network_error',
      desc: '',
      args: [],
    );
  }

  /// `Try again`
  String get try_again {
    return Intl.message('Try again', name: 'try_again', desc: '', args: []);
  }

  /// `Dashboard`
  String get dashboard {
    return Intl.message('Dashboard', name: 'dashboard', desc: '', args: []);
  }

  /// `Organizations`
  String get organizations {
    return Intl.message(
      'Organizations',
      name: 'organizations',
      desc: '',
      args: [],
    );
  }

  /// `Cleaning Areas`
  String get areas {
    return Intl.message('Cleaning Areas', name: 'areas', desc: '', args: []);
  }

  /// `Polygons & Cameras`
  String get polygons {
    return Intl.message(
      'Polygons & Cameras',
      name: 'polygons',
      desc: '',
      args: [],
    );
  }

  /// `Tasks (Tickets)`
  String get tickets {
    return Intl.message('Tasks (Tickets)', name: 'tickets', desc: '', args: []);
  }

  /// `Trips & Violations`
  String get trips {
    return Intl.message(
      'Trips & Violations',
      name: 'trips',
      desc: '',
      args: [],
    );
  }

  /// `Reports`
  String get reports {
    return Intl.message('Reports', name: 'reports', desc: '', args: []);
  }

  /// `sistem control of snow`
  String get sistem_control_sneg {
    return Intl.message(
      'sistem control of snow',
      name: 'sistem_control_sneg',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'kk'),
      Locale.fromSubtags(languageCode: 'ru'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
