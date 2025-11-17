import 'package:flutter/material.dart';

class AnalyticsDriversPage extends StatelessWidget {
  const AnalyticsDriversPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Аналитика водителей')),
      body: const Center(child: Text('Аналитика водителей (в разработке)')),
    );
  }
}

