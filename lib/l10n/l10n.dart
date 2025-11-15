import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'l10n_en.dart';
import 'l10n_kk.dart';
import 'l10n_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of S
/// returned by `S.of(context)`.
///
/// Applications need to include `S.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/l10n.dart';
///
/// return MaterialApp(
///   localizationsDelegates: S.localizationsDelegates,
///   supportedLocales: S.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the S.supportedLocales
/// property.
abstract class S {
  S(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static S? of(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('kk'),
    Locale('ru')
  ];

  /// No description provided for @login_title.
  ///
  /// In en, this message translates to:
  /// **'Akimat Login'**
  String get login_title;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @enter_login_password.
  ///
  /// In en, this message translates to:
  /// **'Enter login and password'**
  String get enter_login_password;

  /// No description provided for @login_button.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login_button;

  /// No description provided for @wrong_credentials.
  ///
  /// In en, this message translates to:
  /// **'Wrong login or password'**
  String get wrong_credentials;

  /// No description provided for @login_error.
  ///
  /// In en, this message translates to:
  /// **'Login error: {error}'**
  String login_error(Object error);

  /// No description provided for @user_not_found.
  ///
  /// In en, this message translates to:
  /// **'User not found'**
  String get user_not_found;

  /// No description provided for @logged_in_as.
  ///
  /// In en, this message translates to:
  /// **'Logged in as'**
  String get logged_in_as;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @logout_confirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logout_confirmation;

  /// No description provided for @home_title.
  ///
  /// In en, this message translates to:
  /// **'Home page'**
  String get home_title;

  /// No description provided for @welcome_back.
  ///
  /// In en, this message translates to:
  /// **'Welcome back!'**
  String get welcome_back;

  /// No description provided for @network_error.
  ///
  /// In en, this message translates to:
  /// **'Network error. Check your internet connection'**
  String get network_error;

  /// No description provided for @try_again.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get try_again;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @organizations.
  ///
  /// In en, this message translates to:
  /// **'Organizations'**
  String get organizations;

  /// No description provided for @areas.
  ///
  /// In en, this message translates to:
  /// **'Cleaning Areas'**
  String get areas;

  /// No description provided for @polygons.
  ///
  /// In en, this message translates to:
  /// **'Polygons & Cameras'**
  String get polygons;

  /// No description provided for @tickets.
  ///
  /// In en, this message translates to:
  /// **'Tasks (Tickets)'**
  String get tickets;

  /// No description provided for @trips.
  ///
  /// In en, this message translates to:
  /// **'Trips & Violations'**
  String get trips;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @sistem_control_sneg.
  ///
  /// In en, this message translates to:
  /// **'sistem control of snow'**
  String get sistem_control_sneg;

  /// No description provided for @no_available_tabs.
  ///
  /// In en, this message translates to:
  /// **'No available tabs'**
  String get no_available_tabs;

  /// No description provided for @contact_admin_for_permissions.
  ///
  /// In en, this message translates to:
  /// **'Contact administrator for permissions.'**
  String get contact_admin_for_permissions;

  /// No description provided for @role_management.
  ///
  /// In en, this message translates to:
  /// **'Role management'**
  String get role_management;

  /// No description provided for @organizations_contractors_drivers.
  ///
  /// In en, this message translates to:
  /// **'Organizations, contractors and drivers'**
  String get organizations_contractors_drivers;

  /// No description provided for @kgu_zkh.
  ///
  /// In en, this message translates to:
  /// **'KGU ZKH'**
  String get kgu_zkh;

  /// No description provided for @too.
  ///
  /// In en, this message translates to:
  /// **'TOO'**
  String get too;

  /// No description provided for @contractors.
  ///
  /// In en, this message translates to:
  /// **'Contractors'**
  String get contractors;

  /// No description provided for @drivers.
  ///
  /// In en, this message translates to:
  /// **'Drivers'**
  String get drivers;

  /// No description provided for @vehicles.
  ///
  /// In en, this message translates to:
  /// **'Vehicles'**
  String get vehicles;

  /// No description provided for @main.
  ///
  /// In en, this message translates to:
  /// **'Main'**
  String get main;

  /// No description provided for @main_panel.
  ///
  /// In en, this message translates to:
  /// **'Main Panel'**
  String get main_panel;

  /// No description provided for @insufficient_permissions.
  ///
  /// In en, this message translates to:
  /// **'Insufficient permissions'**
  String get insufficient_permissions;

  /// No description provided for @insufficient_permissions_message.
  ///
  /// In en, this message translates to:
  /// **'This section is only available to Akimat, TOO or Contractor administrators.'**
  String get insufficient_permissions_message;

  /// No description provided for @failed_to_load_data.
  ///
  /// In en, this message translates to:
  /// **'Failed to load data: {error}'**
  String failed_to_load_data(Object error);

  /// No description provided for @last_trips.
  ///
  /// In en, this message translates to:
  /// **'Last trips'**
  String get last_trips;

  /// No description provided for @additional_web_widget.
  ///
  /// In en, this message translates to:
  /// **'Additional web widget'**
  String get additional_web_widget;

  /// No description provided for @additional_mobile_widget.
  ///
  /// In en, this message translates to:
  /// **'Additional mobile widget'**
  String get additional_mobile_widget;

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @create_ticket.
  ///
  /// In en, this message translates to:
  /// **'Create Ticket'**
  String get create_ticket;

  /// No description provided for @area.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get area;

  /// No description provided for @contractor.
  ///
  /// In en, this message translates to:
  /// **'Contractor'**
  String get contractor;

  /// No description provided for @select_contractor.
  ///
  /// In en, this message translates to:
  /// **'Select contractor'**
  String get select_contractor;

  /// No description provided for @start_date.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get start_date;

  /// No description provided for @end_date.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get end_date;

  /// No description provided for @select_date.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get select_date;

  /// No description provided for @select_period.
  ///
  /// In en, this message translates to:
  /// **'Select period'**
  String get select_period;

  /// No description provided for @end_date_must_be_after_start.
  ///
  /// In en, this message translates to:
  /// **'End date must be after start date'**
  String get end_date_must_be_after_start;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @active_tickets.
  ///
  /// In en, this message translates to:
  /// **'Active Tickets'**
  String get active_tickets;

  /// No description provided for @ticket_id.
  ///
  /// In en, this message translates to:
  /// **'Ticket ID'**
  String get ticket_id;

  /// No description provided for @period.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get period;

  /// No description provided for @trips_count.
  ///
  /// In en, this message translates to:
  /// **'Trips Count'**
  String get trips_count;

  /// No description provided for @volume_shipped.
  ///
  /// In en, this message translates to:
  /// **'Volume Shipped'**
  String get volume_shipped;

  /// No description provided for @volume_normative.
  ///
  /// In en, this message translates to:
  /// **'Volume Normative'**
  String get volume_normative;

  /// No description provided for @violations.
  ///
  /// In en, this message translates to:
  /// **'Violations'**
  String get violations;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @planned.
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get planned;

  /// No description provided for @in_progress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get in_progress;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closed;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @contract.
  ///
  /// In en, this message translates to:
  /// **'Contract'**
  String get contract;

  /// No description provided for @select_contract.
  ///
  /// In en, this message translates to:
  /// **'Select contract'**
  String get select_contract;

  /// No description provided for @select_contractor_first.
  ///
  /// In en, this message translates to:
  /// **'Select contractor first'**
  String get select_contractor_first;

  /// No description provided for @no_contracts_available.
  ///
  /// In en, this message translates to:
  /// **'No contracts available'**
  String get no_contracts_available;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @cancel_ticket.
  ///
  /// In en, this message translates to:
  /// **'Cancel ticket'**
  String get cancel_ticket;

  /// No description provided for @close_ticket.
  ///
  /// In en, this message translates to:
  /// **'Close ticket'**
  String get close_ticket;

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @contracts.
  ///
  /// In en, this message translates to:
  /// **'Contracts'**
  String get contracts;

  /// No description provided for @create_contract.
  ///
  /// In en, this message translates to:
  /// **'Create contract'**
  String get create_contract;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expired;

  /// No description provided for @archived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get archived;

  /// No description provided for @period_start.
  ///
  /// In en, this message translates to:
  /// **'Period from'**
  String get period_start;

  /// No description provided for @period_end.
  ///
  /// In en, this message translates to:
  /// **'Period to'**
  String get period_end;

  /// No description provided for @contract_name.
  ///
  /// In en, this message translates to:
  /// **'Contract'**
  String get contract_name;

  /// No description provided for @price_per_m3.
  ///
  /// In en, this message translates to:
  /// **'Price per m³'**
  String get price_per_m3;

  /// No description provided for @volume_progress.
  ///
  /// In en, this message translates to:
  /// **'Volume progress'**
  String get volume_progress;

  /// No description provided for @budget_progress.
  ///
  /// In en, this message translates to:
  /// **'Budget progress'**
  String get budget_progress;

  /// No description provided for @budget_exceeded.
  ///
  /// In en, this message translates to:
  /// **'Budget exceeded'**
  String get budget_exceeded;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @no_contracts_found.
  ///
  /// In en, this message translates to:
  /// **'No contracts found'**
  String get no_contracts_found;
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  Future<S> load(Locale locale) {
    return SynchronousFuture<S>(lookupS(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'kk', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_SDelegate old) => false;
}

S lookupS(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return SEn();
    case 'kk':
      return SKk();
    case 'ru':
      return SRu();
  }

  throw FlutterError(
      'S.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
