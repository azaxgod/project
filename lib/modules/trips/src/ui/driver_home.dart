import 'package:flutter/material.dart';

class DriverHome extends StatelessWidget {
  const DriverHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Панель Водителя')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('Список рейсов водителя'),
            SizedBox(height: 8),
            Text('Здесь показываем рейсы, нарушения и мини-карту'),
          ],
        ),
      ),
    );
  }
}
