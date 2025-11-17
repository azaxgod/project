import 'package:akimat_project/core/di.dart';
import 'package:akimat_project/modules/violations/src/controller/violations_controller.dart';
import 'package:akimat_project/modules/violations/src/controller/violations_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final violationsControllerProvider =
    StateNotifierProvider<ViolationsController, ViolationsState>(
  (ref) => ViolationsController(
    repository: ref.read(iViolationsRepositoryProvider),
  ),
);

