// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'l10n.dart';

// ignore_for_file: type=lint

/// The translations for Kazakh (`kk`).
class SKk extends S {
  SKk([String locale = 'kk']) : super(locale);

  @override
  String get login_title => 'Akimat-қа авторизация';

  @override
  String get login => 'Логин';

  @override
  String get password => 'Құпия сөз';

  @override
  String get enter_login_password => 'Логин мен құпия сөзді енгізіңіз';

  @override
  String get login_button => 'Кіру';

  @override
  String get wrong_credentials => 'Қате логин немесе құпия сөз';

  @override
  String login_error(Object error) {
    return 'Кіру қатесі: $error';
  }

  @override
  String get user_not_found => 'Пайдаланушы табылмады';

  @override
  String get logged_in_as => 'Сіз кірдіңіз';

  @override
  String get loading => 'Жүктелуде...';

  @override
  String get logout => 'Шығу';

  @override
  String get logout_confirmation => 'Шығуды қалайсыз ба?';

  @override
  String get home_title => 'Басты бет';

  @override
  String get welcome_back => 'Қайта қош келдіңіз!';

  @override
  String get network_error => 'Желі қатесі. Интернетке қосылуды тексеріңіз';

  @override
  String get try_again => 'Қайтадан әрекет жасау';

  @override
  String get dashboard => 'Басты';

  @override
  String get organizations => 'Ұйымдар';

  @override
  String get areas => 'Тазалау учаскелері';

  @override
  String get polygons => 'Полигондар және камералар';

  @override
  String get tickets => 'Тапсырмалар (тикеттер)';

  @override
  String get trips => 'Рейс пен бұзушылықтар';

  @override
  String get reports => 'Есептер';

  @override
  String get sistem_control_sneg => 'Система контроля снега';

  @override
  String get no_available_tabs => 'Қолжетімді қойындылар жоқ';

  @override
  String get contact_admin_for_permissions =>
      'Құқықтар беру үшін әкімшіге хабарласыңыз.';

  @override
  String get role_management => 'Рөлдерді басқару';

  @override
  String get organizations_contractors_drivers =>
      'Ұйымдар, подрядчиктер және жүргізушілер';

  @override
  String get kgu_zkh => 'КГУ ЖКХ';

  @override
  String get too => 'ТОО';

  @override
  String get contractors => 'Подрядчиктер';

  @override
  String get drivers => 'Жүргізушілер';

  @override
  String get vehicles => 'Көліктер';

  @override
  String get main => 'Басты';

  @override
  String get main_panel => 'Басты панель';

  @override
  String get insufficient_permissions => 'Құқықтар жеткіліксіз';

  @override
  String get insufficient_permissions_message =>
      'Бұл бөлім тек Акимат, ТОО немесе Подрядчик әкімшілеріне қолжетімді.';

  @override
  String failed_to_load_data(Object error) {
    return 'Деректерді жүктеу сәтсіз аяқталды: $error';
  }

  @override
  String get last_trips => 'Соңғы рейстер';

  @override
  String get additional_web_widget => 'Қосымша веб-виджет';

  @override
  String get additional_mobile_widget => 'Қосымша мобильді виджет';

  @override
  String get menu => 'Мәзір';

  @override
  String get create_ticket => 'Тикет құру';

  @override
  String get area => 'Аудан';

  @override
  String get contractor => 'Подрядчик';

  @override
  String get select_contractor => 'Подрядчикті таңдаңыз';

  @override
  String get start_date => 'Басталу күні';

  @override
  String get end_date => 'Аяқталу күні';

  @override
  String get select_date => 'Күнді таңдаңыз';

  @override
  String get select_period => 'Кезеңді таңдаңыз';

  @override
  String get end_date_must_be_after_start =>
      'Аяқталу күні басталу күнінен кейін болуы керек';

  @override
  String get description => 'Сипаттама';

  @override
  String get save => 'Сақтау';

  @override
  String get cancel => 'Болдырмау';

  @override
  String get active_tickets => 'Белсенді тикеттер';

  @override
  String get ticket_id => 'Тикет ID';

  @override
  String get period => 'Кезең';

  @override
  String get trips_count => 'Рейстер саны';

  @override
  String get volume_shipped => 'Шығарылған көлем';

  @override
  String get volume_normative => 'Норматив';

  @override
  String get violations => 'Бұзушылықтар';

  @override
  String get status => 'Статус';

  @override
  String get pending => 'Күтуде';

  @override
  String get planned => 'Жоспарланған';

  @override
  String get in_progress => 'Жұмыс істеп жатыр';

  @override
  String get completed => 'Аяқталды';

  @override
  String get closed => 'Жабылды';

  @override
  String get cancelled => 'Болдырылды';

  @override
  String get all => 'Барлығы';

  @override
  String get contract => 'Келісім';

  @override
  String get select_contract => 'Келісімді таңдаңыз';

  @override
  String get select_contractor_first => 'Алдымен подрядчикті таңдаңыз';

  @override
  String get no_contracts_available => 'Қолжетімді келісімдер жоқ';

  @override
  String get details => 'Толығырақ';

  @override
  String get cancel_ticket => 'Тикетті болдыру';

  @override
  String get close_ticket => 'Тикетті жабу';

  @override
  String get actions => 'Әрекеттер';

  @override
  String get contracts => 'Келісімдер';

  @override
  String get create_contract => 'Келісім құру';

  @override
  String get active => 'Белсенді';

  @override
  String get expired => 'Мерзімі өткен';

  @override
  String get archived => 'Мұрағатталған';

  @override
  String get period_start => 'Кезең басталуы';

  @override
  String get period_end => 'Кезең аяқталуы';

  @override
  String get contract_name => 'Келісім';

  @override
  String get price_per_m3 => 'м³ бағасы';

  @override
  String get volume_progress => 'Көлемді игеру';

  @override
  String get budget_progress => 'Бюджетті игеру';

  @override
  String get budget_exceeded => 'Бюджетті асу';

  @override
  String get yes => 'Иә';

  @override
  String get no => 'Жоқ';

  @override
  String get open => 'Ашу';

  @override
  String get no_contracts_found => 'Келісімдер табылмады';

  @override
  String get analytics => 'Аналитика';

  @override
  String get download_excel => 'Excel жүктеу';
}
