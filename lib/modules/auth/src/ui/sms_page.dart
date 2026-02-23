import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controller/auth_notifier.dart';
import 'home_router.dart';

class SmsPage extends ConsumerStatefulWidget {
  const SmsPage({super.key});

  @override
  ConsumerState<SmsPage> createState() => _SmsPageState();
}

class _SmsPageState extends ConsumerState<SmsPage> {
  final phoneController = TextEditingController();
  final codeController = TextEditingController();

  void _sendSms() async {
    await ref.read(authNotifierProvider.notifier).sendSms(phoneController.text);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('SMS отправлено')));
  }

  void _verifySms() async {
    try {
      await ref.read(authNotifierProvider.notifier)
          .verifySms(phoneController.text, codeController.text);
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeRouter()));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Неверный код')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Номер телефона')),
          ElevatedButton(onPressed: _sendSms, child: const Text('Отправить SMS')),
          TextField(controller: codeController, decoration: const InputDecoration(labelText: 'Код из SMS')),
          ElevatedButton(onPressed: _verifySms, child: const Text('Подтвердить')),
        ],
      ),
    );
  }
}
