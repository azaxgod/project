import 'package:akimat_project/core/di.dart';
import 'package:akimat_project/modules/analytics/src/controller/analytics_controller.dart';
import 'package:akimat_project/modules/analytics/src/controller/analytics_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final analyticsControllerProvider =
    StateNotifierProvider<AnalyticsController, AnalyticsState>((ref) {
  final repository = ref.read(iAnalyticsRepositoryProvider);
  return AnalyticsController(repository: repository);
});

