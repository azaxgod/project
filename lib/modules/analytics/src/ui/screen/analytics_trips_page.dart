import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_textstyle.dart';
import 'package:akimat_project/modules/analytics/src/controller/analytics_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AnalyticsTripsPage extends ConsumerStatefulWidget {
  const AnalyticsTripsPage({super.key});

  @override
  ConsumerState<AnalyticsTripsPage> createState() => _AnalyticsTripsPageState();
}

class _AnalyticsTripsPageState extends ConsumerState<AnalyticsTripsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final now = DateTime.now();
      ref.read(analyticsControllerProvider.notifier).loadTripsAnalytics(
        from: now.subtract(const Duration(days: 7)),
        to: now,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(analyticsControllerProvider);
    final controller = ref.read(analyticsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Аналитика рейсов'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final now = DateTime.now();
              controller.loadTripsAnalytics(
                from: now.subtract(const Duration(days: 7)),
                to: now,
              );
            },
          ),
        ],
      ),
      body: state.tripsAnalytics?.when(
        data: (data) => SingleChildScrollView(
          padding: const EdgeInsets.all(AppPadding.large),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Аналитика рейсов', style: AppTextStyles.title),
              const SizedBox(height: AppPadding.large),
              // TODO: Добавить графики и таблицы
              Text('Данные загружены: ${data.data.series.length} точек'),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Ошибка: $error'),
        ),
      ) ?? const Center(child: CircularProgressIndicator()),
    );
  }
}

