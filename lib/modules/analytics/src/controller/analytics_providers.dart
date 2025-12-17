import 'package:akimat_project/core/di.dart';
import 'package:akimat_project/modules/analytics/src/controller/analytics_controller.dart';
import 'package:akimat_project/modules/analytics/src/controller/analytics_state.dart';
import 'package:akimat_project/modules/analytics/src/controller/anpr_controller.dart';
import 'package:akimat_project/services/anpr/module.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final analyticsControllerProvider =
    StateNotifierProvider<AnalyticsController, AnalyticsState>((ref) {
  final repository = ref.read(iAnalyticsRepositoryProvider);
  return AnalyticsController(repository: repository);
});

/// Provider для ANPR контроллера
final anprControllerProvider =
    StateNotifierProvider<AnprController, AnprState>((ref) {
  final anprCollection = ref.read(anprCollectionProvider);
  return AnprController(anprCollection: anprCollection);
});








