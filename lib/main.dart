import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Руководитель
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Пользователь
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _smsController = TextEditingController();

  bool _smsSent = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _loginAdmin() {
    final login = _loginController.text;
    final password = _passwordController.text;

    // Пример проверки
    if (login == 'akimat.sko' && password == 'qwer123!') {
      // успешный вход
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Вход успешен!')));
      // TODO: редирект на дашборд Акимата
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Неверный логин или пароль')));
    }
  }

  void _sendSMS() {
    final phone = _phoneController.text;
    if (phone.isEmpty) return;

    setState(() => _smsSent = true);

    // TODO: отправка SMS через backend
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Код отправлен на $phone')));
  }

  void _verifySMS() {
    final code = _smsController.text;
    // TODO: проверка кода через backend
    if (code == '1234') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Вход успешен!')));
      // TODO: редирект на интерфейс пользователя (ТОО/Подрядчик/Водитель)
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Неверный или просроченный код')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Авторизация'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Руководитель'),
            Tab(text: 'Пользователь'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Вкладка Руководитель
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(controller: _loginController, decoration: const InputDecoration(labelText: 'Логин')),
                const SizedBox(height: 16),
                TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Пароль'), obscureText: true),
                const SizedBox(height: 24),
                ElevatedButton(onPressed: _loginAdmin, child: const Text('Войти')),
              ],
            ),
          ),

          // Вкладка Пользователь
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Номер телефона')),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _sendSMS, child: const Text('Получить код')),
                if (_smsSent) ...[
                  const SizedBox(height: 16),
                  TextField(controller: _smsController, decoration: const InputDecoration(labelText: 'Код из SMS')),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _verifySMS, child: const Text('Подтвердить')),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void main() {
  runApp(const MaterialApp(home: LoginPage()));
}
