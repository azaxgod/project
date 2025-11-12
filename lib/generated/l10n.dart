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

  // Localization getters - these should be overridden by locale-specific classes
  String get login_title => Intl.message('Akimat Login', name: 'login_title');
  String get login => Intl.message('Login', name: 'login');
  String get password => Intl.message('Password', name: 'password');
  String get enter_login_password => Intl.message('Enter login and password', name: 'enter_login_password');
  String get login_button => Intl.message('Login', name: 'login_button');
  String get wrong_credentials => Intl.message('Wrong login or password', name: 'wrong_credentials');
  String login_error(Object error) => Intl.message('Login error: $error', name: 'login_error', args: [error]);
  String get user_not_found => Intl.message('User not found', name: 'user_not_found');
  String get logged_in_as => Intl.message('Logged in as', name: 'logged_in_as');
  String get loading => Intl.message('Loading...', name: 'loading');
  String get logout => Intl.message('Logout', name: 'logout');
  String get home_title => Intl.message('Home page', name: 'home_title');
  String get welcome_back => Intl.message('Welcome back!', name: 'welcome_back');
  String get network_error => Intl.message('Network error. Check your internet connection', name: 'network_error');
  String get try_again => Intl.message('Try again', name: 'try_again');
  String get dashboard => Intl.message('Dashboard', name: 'dashboard');
  String get organizations => Intl.message('Organizations', name: 'organizations');
  String get areas => Intl.message('Cleaning Areas', name: 'areas');
  String get polygons => Intl.message('Polygons & Cameras', name: 'polygons');
  String get tickets => Intl.message('Tasks (Tickets)', name: 'tickets');
  String get trips => Intl.message('Trips & Violations', name: 'trips');
  String get reports => Intl.message('Reports', name: 'reports');
  String get sistem_control_sneg => Intl.message('sistem control of snow', name: 'sistem_control_sneg');
  String get no_available_tabs => Intl.message('No available tabs', name: 'no_available_tabs');
  String get contact_admin_for_permissions => Intl.message('Contact administrator for permissions.', name: 'contact_admin_for_permissions');
  String get role_management => Intl.message('Role management', name: 'role_management');
  String get organizations_contractors_drivers => Intl.message('Organizations, contractors and drivers', name: 'organizations_contractors_drivers');
  String get too => Intl.message('TOO', name: 'too');
  String get contractors => Intl.message('Contractors', name: 'contractors');
  String get drivers => Intl.message('Drivers', name: 'drivers');
  String get vehicles => Intl.message('Vehicles', name: 'vehicles');
  String get main => Intl.message('Main', name: 'main');
  String get main_panel => Intl.message('Main Panel', name: 'main_panel');
  String get insufficient_permissions => Intl.message('Insufficient permissions', name: 'insufficient_permissions');
  String get insufficient_permissions_message => Intl.message('This section is only available to Akimat, TOO or Contractor administrators.', name: 'insufficient_permissions_message');
  String failed_to_load_data(Object error) => Intl.message('Failed to load data: $error', name: 'failed_to_load_data', args: [error]);
  String get last_trips => Intl.message('Last trips', name: 'last_trips');
  String get additional_web_widget => Intl.message('Additional web widget', name: 'additional_web_widget');
  String get additional_mobile_widget => Intl.message('Additional mobile widget', name: 'additional_mobile_widget');
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
