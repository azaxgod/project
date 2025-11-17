import 'package:flutter/material.dart';

class AnalyticsPerformancePage extends StatelessWidget {
  const AnalyticsPerformancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Аналитика эффективности')),
      body: const Center(child: Text('Аналитика эффективности (в разработке)')),
    );
  }
}

