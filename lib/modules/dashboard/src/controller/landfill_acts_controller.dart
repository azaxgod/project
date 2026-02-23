import 'package:akimat_project/modules/dashboard/src/model/acts/act.dart';
import 'package:akimat_project/services/acts/collection/acts_collection.dart';
import 'package:akimat_project/services/acts/module.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LandfillActsState {
  final AsyncValue<List<Act>> acts;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final String? statusFilter;

  const LandfillActsState({
    required this.acts,
    this.periodStart,
    this.periodEnd,
    this.statusFilter,
  });

  factory LandfillActsState.initial() {
    return const LandfillActsState(
      acts: AsyncLoading(),
    );
  }

  LandfillActsState copyWith({
    AsyncValue<List<Act>>? acts,
    DateTime? periodStart,
    DateTime? periodEnd,
    String? statusFilter,
  }) {
    return LandfillActsState(
      acts: acts ?? this.acts,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }
}

final landfillActsControllerProvider =
    StateNotifierProvider<LandfillActsController, LandfillActsState>((ref) {
  final collection = ref.watch(actsCollectionProvider);
  return LandfillActsController(collection: collection);
});

class LandfillActsController extends StateNotifier<LandfillActsState> {
  LandfillActsController({
    required ActsCollection collection,
  })  : _collection = collection,
        super(LandfillActsState.initial()) {
    _loadData();
  }

  final ActsCollection _collection;

  Future<void> _loadData() async {
    state = state.copyWith(acts: const AsyncLoading());
    state = state.copyWith(
      acts: await AsyncValue.guard(() async {
        final result = await _collection.getLandfillActs(
          periodStart: state.periodStart,
          periodEnd: state.periodEnd,
          status: state.statusFilter,
        );

        final actsData = result['data'] as Map<String, dynamic>?;
        final actsList = actsData?['acts'] as List<dynamic>? ?? [];
        final acts = actsList
            .map((json) => Act.fromJson(json as Map<String, dynamic>))
            .toList();

        return acts;
      }),
    );
  }

  Future<void> refresh() => _loadData();

  void setDateRange(DateTime? from, DateTime? to) {
    state = state.copyWith(periodStart: from, periodEnd: to);
    _loadData();
  }

  void setStatusFilter(String? status) {
    state = state.copyWith(statusFilter: status);
    _loadData();
  }

  Future<void> approveAct(String actId, {String? comment}) async {
    try {
      await _collection.approveLandfillAct(actId, comment: comment);
      await _loadData();
    } catch (e) {
      state = state.copyWith(
        acts: AsyncValue.error(e, StackTrace.current),
      );
      rethrow;
    }
  }

  Future<void> rejectAct(String actId, {required String reason}) async {
    try {
      await _collection.rejectLandfillAct(actId, reason: reason);
      await _loadData();
    } catch (e) {
      state = state.copyWith(
        acts: AsyncValue.error(e, StackTrace.current),
      );
      rethrow;
    }
  }
}

