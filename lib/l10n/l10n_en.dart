// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'l10n.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SEn extends S {
  SEn([String locale = 'en']) : super(locale);

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
  String get logout_confirmation => 'Are you sure you want to logout?';

  @override
  String get home_title => 'Home page';

  @override
  String get welcome_back => 'Welcome back!';

  @override
  String get network_error => 'Network error. Check your internet connection';

  @override
  String get try_again => 'Try again';

  @override
  String get dashboard => 'Main';

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
  String get contact_admin_for_permissions =>
      'Contact administrator for permissions.';

  @override
  String get role_management => 'Role management';

  @override
  String get organizations_contractors_drivers =>
      'Organizations, contractors and drivers';

  @override
  String get kgu_zkh => 'KGU ZKH';

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
  String get insufficient_permissions_message =>
      'This section is only available to Akimat, TOO or Contractor administrators.';

  @override
  String failed_to_load_data(Object error) {
    return 'Failed to load data: $error';
  }

  @override
  String get last_trips => 'Last trips';

  @override
  String get additional_web_widget => 'Additional web widget';

  @override
  String get additional_mobile_widget => 'Additional mobile widget';

  @override
  String get menu => 'Menu';

  @override
  String get create_ticket => 'Create Ticket';

  @override
  String get area => 'Area';

  @override
  String get contractor => 'Contractor';

  @override
  String get select_contractor => 'Select contractor';

  @override
  String get start_date => 'Start Date';

  @override
  String get end_date => 'End Date';

  @override
  String get select_date => 'Select date';

  @override
  String get select_period => 'Select period';

  @override
  String get end_date_must_be_after_start =>
      'End date must be after start date';

  @override
  String get description => 'Description';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get active_tickets => 'Active Tickets';

  @override
  String get ticket_id => 'Ticket ID';

  @override
  String get period => 'Period';

  @override
  String get trips_count => 'Trips Count';

  @override
  String get volume_shipped => 'Volume Shipped';

  @override
  String get volume_normative => 'Volume Normative';

  @override
  String get violations => 'Violations';

  @override
  String get status => 'Status';

  @override
  String get pending => 'Pending';

  @override
  String get planned => 'Planned';

  @override
  String get in_progress => 'In Progress';

  @override
  String get completed => 'Completed';

  @override
  String get closed => 'Closed';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get all => 'All';

  @override
  String get contract => 'Contract';

  @override
  String get select_contract => 'Select contract';

  @override
  String get select_contractor_first => 'Select contractor first';

  @override
  String get no_contracts_available => 'No contracts available';

  @override
  String get details => 'Details';

  @override
  String get cancel_ticket => 'Cancel ticket';

  @override
  String get close_ticket => 'Close ticket';

  @override
  String get actions => 'Actions';

  @override
  String get contracts => 'Contracts';

  @override
  String get create_contract => 'Create contract';

  @override
  String get active => 'Active';

  @override
  String get expired => 'Expired';

  @override
  String get archived => 'Archived';

  @override
  String get period_start => 'Period from';

  @override
  String get period_end => 'Period to';

  @override
  String get contract_name => 'Contract';

  @override
  String get price_per_m3 => 'Price per m³';

  @override
  String get volume_progress => 'Volume progress';

  @override
  String get budget_progress => 'Budget progress';

  @override
  String get budget_exceeded => 'Budget exceeded';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get open => 'Open';

  @override
  String get no_contracts_found => 'No contracts found';

  @override
  String get analytics => 'Analytics';
}
