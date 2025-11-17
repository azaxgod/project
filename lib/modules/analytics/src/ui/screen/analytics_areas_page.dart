import 'package:flutter/material.dart';

class AnalyticsAreasPage extends StatelessWidget {
  const AnalyticsAreasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Аналитика участков')),
      body: const Center(child: Text('Аналитика участков (в разработке)')),
    );
  }
}

