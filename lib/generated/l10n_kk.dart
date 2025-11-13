// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'l10n.dart';

// ignore_for_file: type=lint

/// The translations for Kazakh (`kk`).
class SKk extends S {
  SKk();

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
  String get home_title => 'Басты бет';

  @override
  String get welcome_back => 'Қайта қош келдіңіз!';

  @override
  String get network_error => 'Желі қатесі. Интернетке қосылуды тексеріңіз';

  @override
  String get try_again => 'Қайтадан әрекет жасау';

  @override
  String get dashboard => 'Дэшборд';

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
  String get contact_admin_for_permissions => 'Құқықтар беру үшін әкімшіге хабарласыңыз.';

  @override
  String get role_management => 'Рөлдерді басқару';

  @override
  String get organizations_contractors_drivers => 'Ұйымдар, подрядчиктер және жүргізушілер';

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
  String get insufficient_permissions_message => 'Бұл бөлім тек Акимат, ТОО немесе Подрядчик әкімшілеріне қолжетімді.';

  @override
  String failed_to_load_data(Object error) => 'Деректерді жүктеу сәтсіз аяқталды: $error';

  @override
  String get last_trips => 'Соңғы рейстер';

  @override
  String get additional_web_widget => 'Қосымша веб-виджет';

  @override
  String get additional_mobile_widget => 'Қосымша мобильді виджет';

  @override
  String get menu => 'Мәзір';
}
