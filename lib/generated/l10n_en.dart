// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'l10n.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SEn extends S {
  SEn();

  @override
  String get login_title => 'Akimat Login';

  @override
  String get login => 'Login';

  @override
  String get password => 'Password';

  @override
  String get enter_login_password => 'Enter login and password';

  @override
  String get login_button => 'Login';

  @override
  String get wrong_credentials => 'Wrong login or password';

  @override
  String login_error(Object error) {
    return 'Login error: $error';
  }

  @override
  String get user_not_found => 'User not found';

  @override
  String get logged_in_as => 'Logged in as';

  @override
  String get loading => 'Loading...';

  @override
  String get logout => 'Logout';

  @override
  String get home_title => 'Home page';

  @override
  String get welcome_back => 'Welcome back!';

  @override
  String get network_error => 'Network error. Check your internet connection';

  @override
  String get try_again => 'Try again';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get organizations => 'Organizations';

  @override
  String get areas => 'Cleaning Areas';

  @override
  String get polygons => 'Polygons & Cameras';

  @override
  String get tickets => 'Tasks (Tickets)';

  @override
  String get trips => 'Trips & Violations';

  @override
  String get reports => 'Reports';

  @override
  String get sistem_control_sneg => 'sistem control of snow';

  @override
  String get no_available_tabs => 'No available tabs';

  @override
  String get contact_admin_for_permissions => 'Contact administrator for permissions.';

  @override
  String get role_management => 'Role management';

  @override
  String get organizations_contractors_drivers => 'Organizations, contractors and drivers';

  @override
  String get too => 'TOO';

  @override
  String get contractors => 'Contractors';

  @override
  String get drivers => 'Drivers';

  @override
  String get vehicles => 'Vehicles';

  @override
  String get main => 'Main';

  @override
  String get main_panel => 'Main Panel';

  @override
  String get insufficient_permissions => 'Insufficient permissions';

  @override
  String get insufficient_permissions_message => 'This section is only available to Akimat, TOO or Contractor administrators.';

  @override
  String failed_to_load_data(Object error) => 'Failed to load data: $error';

  @override
  String get last_trips => 'Last trips';

  @override
  String get additional_web_widget => 'Additional web widget';

  @override
  String get additional_mobile_widget => 'Additional mobile widget';

  @override
  String get menu => 'Menu';
}
