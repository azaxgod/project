import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AnalyticsViolationsPage extends ConsumerWidget {
  const AnalyticsViolationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Аналитика нарушений')),
      body: const Center(child: Text('Аналитика нарушений (в разработке)')),
    );
  }
}

