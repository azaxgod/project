// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

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
  String get logout_confirmation => 'Вы уверены, что хотите выйти?';

  @override
  String get home_title => 'Главная страница';

  @override
  String get welcome_back => 'С возвращением!';

  @override
  String get network_error => 'Ошибка сети. Проверьте подключение к интернету';

  @override
  String get try_again => 'Попробовать снова';

  @override
  String get dashboard => 'Главная';

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
  String get kgu_zkh => 'КГУ ЖКХ';

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
  String failed_to_load_data(Object error) {
    return 'Не удалось загрузить данные: $error';
  }

  @override
  String get last_trips => 'Последние рейсы';

  @override
  String get additional_web_widget => 'Дополнительный веб-виджет';

  @override
  String get additional_mobile_widget => 'Дополнительный мобильный виджет';

  @override
  String get menu => 'Меню';

  @override
  String get create_ticket => 'Создать тикет';

  @override
  String get area => 'Участок';

  @override
  String get contractor => 'Подрядчик';

  @override
  String get select_contractor => 'Выберите подрядчика';

  @override
  String get start_date => 'Дата начала';

  @override
  String get end_date => 'Дата окончания';

  @override
  String get select_date => 'Выберите дату';

  @override
  String get select_period => 'Выберите период';

  @override
  String get end_date_must_be_after_start => 'Дата окончания должна быть после даты начала';

  @override
  String get description => 'Описание';

  @override
  String get save => 'Сохранить';

  @override
  String get cancel => 'Отмена';

  @override
  String get active_tickets => 'Активные тикеты';

  @override
  String get ticket_id => 'ID тикета';

  @override
  String get period => 'Период';

  @override
  String get trips_count => 'Кол-во рейсов';

  @override
  String get volume_shipped => 'Объем вывезен';

  @override
  String get volume_normative => 'Норматив';

  @override
  String get violations => 'Нарушения';

  @override
  String get status => 'Статус';

  @override
  String get pending => 'Ожидает';

  @override
  String get planned => 'Запланирован';

  @override
  String get in_progress => 'В работе';

  @override
  String get completed => 'Выполнен';

  @override
  String get closed => 'Закрыт';

  @override
  String get cancelled => 'Отменен';

  @override
  String get all => 'Все';

  @override
  String get contract => 'Контракт';

  @override
  String get select_contract => 'Выберите контракт';

  @override
  String get select_contractor_first => 'Сначала выберите подрядчика';

  @override
  String get no_contracts_available => 'Нет доступных контрактов';

  @override
  String get details => 'Подробнее';

  @override
  String get cancel_ticket => 'Отменить тикет';

  @override
  String get close_ticket => 'Закрыть тикет';

  @override
  String get actions => 'Действия';

  @override
  String get contracts => 'Контракты';

  @override
  String get create_contract => 'Создать контракт';

  @override
  String get active => 'Активен';

  @override
  String get expired => 'Истек';

  @override
  String get archived => 'Архивирован';

  @override
  String get period_start => 'Период с';

  @override
  String get period_end => 'Период по';

  @override
  String get contract_name => 'Договор';

  @override
  String get price_per_m3 => 'Цена за м³';

  @override
  String get volume_progress => 'Освоение объёма';

  @override
  String get budget_progress => 'Освоение бюджета';

  @override
  String get budget_exceeded => 'Превышение бюджета';

  @override
  String get yes => 'Да';

  @override
  String get no => 'Нет';

  @override
  String get open => 'Открыть';

  @override
  String get no_contracts_found => 'Контракты не найдены';

  @override
  String get analytics => 'Аналитика';
}
