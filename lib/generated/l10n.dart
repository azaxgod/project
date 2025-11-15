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

abstract class S {
  S();

  static S? _current;

  static S get current {
    assert(
      _current != null,
      'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.',
    );
    return _current!;
  }

  /// Set the current instance (used by CustomLocalizationDelegate)
  static void setCurrent(S instance) {
    _current = instance;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<void> loadMessages(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
    });
  }

  // Keep the old load method for compatibility with AppLocalizationDelegate
  static Future<S> load(Locale locale) {
    return loadMessages(locale).then((_) {
      // Return a placeholder - actual instance should be created by CustomLocalizationDelegate
      // This should not be used, but kept for compatibility
      throw UnsupportedError('Use CustomLocalizationDelegate.load() instead');
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

  // Abstract getters - must be implemented by subclasses
  String get login_title;
  String get login;
  String get password;
  String get enter_login_password;
  String get login_button;
  String get wrong_credentials;
  String login_error(Object error);
  String get user_not_found;
  String get logged_in_as;
  String get loading;
  String get logout;
  String get home_title;
  String get welcome_back;
  String get network_error;
  String get try_again;
  String get dashboard;
  String get organizations;
  String get areas;
  String get polygons;
  String get tickets;
  String get trips;
  String get reports;
  String get sistem_control_sneg;
  String get no_available_tabs;
  String get contact_admin_for_permissions;
  String get role_management;
  String get organizations_contractors_drivers;
  String get too;
  String get contractors;
  String get drivers;
  String get vehicles;
  String get main;
  String get main_panel;
  String get insufficient_permissions;
  String get insufficient_permissions_message;
  String failed_to_load_data(Object error);
  String get last_trips;
  String get additional_web_widget;
  String get additional_mobile_widget;
  String get menu;
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[Locale.fromSubtags(languageCode: 'en')];
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
