// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'l10n.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class SRu extends S {
  SRu();

  @override
  String get login_title => 'Авторизация Akimat';

  @override
  String get login => 'Логин';

  @override
  String get password => 'Пароль';

  @override
  String get enter_login_password => 'Введите логин и пароль';

  @override
  String get login_button => 'Войти';

  @override
  String get wrong_credentials => 'Неверный логин или пароль';

  @override
  String login_error(Object error) {
    return 'Ошибка входа: $error';
  }

  @override
  String get user_not_found => 'Пользователь не найден';

  @override
  String get logged_in_as => 'Вы вошли как';

  @override
  String get loading => 'Загрузка...';

  @override
  String get logout => 'Выйти';

  @override
  String get home_title => 'Главная страница';

  @override
  String get welcome_back => 'С возвращением!';

  @override
  String get network_error => 'Ошибка сети. Проверьте подключение к интернету';

  @override
  String get try_again => 'Попробовать снова';

  @override
  String get dashboard => 'Дэшборд';

  @override
  String get organizations => 'Организации';

  @override
  String get areas => 'Участки уборки';

  @override
  String get polygons => 'Полигоны и камеры';

  @override
  String get tickets => 'Задания (тикеты)';

  @override
  String get trips => 'Рейсы и нарушения';

  @override
  String get reports => 'Отчеты';

  @override
  String get sistem_control_sneg => 'Система контроля снега';

  @override
  String get no_available_tabs => 'Нет доступных вкладок';

  @override
  String get contact_admin_for_permissions => 'Обратитесь к администратору для выдачи прав.';

  @override
  String get role_management => 'Управление ролями';

  @override
  String get organizations_contractors_drivers => 'Организации, подрядчики и водители';

  @override
  String get too => 'ТОО';

  @override
  String get contractors => 'Подрядчики';

  @override
  String get drivers => 'Водители';

  @override
  String get vehicles => 'Транспорт';

  @override
  String get main => 'Главная';

  @override
  String get main_panel => 'Главная панель';

  @override
  String get insufficient_permissions => 'Недостаточно прав';

  @override
  String get insufficient_permissions_message => 'Раздел доступен только администраторам Акимата, ТОО или Подрядчика.';

  @override
  String failed_to_load_data(Object error) => 'Не удалось загрузить данные: $error';

  @override
  String get last_trips => 'Последние рейсы';

  @override
  String get additional_web_widget => 'Дополнительный веб-виджет';

  @override
  String get additional_mobile_widget => 'Дополнительный мобильный виджет';

  @override
  String get menu => 'Меню';
}
