import 'package:flutter/material.dart';

class ContractorHome extends StatelessWidget {
  const ContractorHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Панель ТОО/Подрядчика')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('Главная панель ТОО/Подрядчика'),
            SizedBox(height: 8),
            Text('Сюда можно добавить KPI и список своих участков/тикетов'),
          ],
        ),
      ),
    );
  }
}
