import 'package:akimat_project/modules/auth/src/controller/auth_notifier.dart';
import 'package:akimat_project/modules/dashboard/src/controller/areas_controller.dart';
import 'package:akimat_project/modules/dashboard/src/model/acts/act.dart';
import 'package:akimat_project/modules/dashboard/src/repository/operations_repository.dart';
import 'package:akimat_project/services/acts/collection/acts_collection.dart';
import 'package:akimat_project/services/acts/module.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LandfillHomeState {
  final AsyncValue<LandfillHomeData> data;

  const LandfillHomeState({
    required this.data,
  });

  factory LandfillHomeState.initial() {
    return const LandfillHomeState(
      data: AsyncLoading(),
    );
  }

  LandfillHomeState copyWith({
    AsyncValue<LandfillHomeData>? data,
  }) {
    return LandfillHomeState(
      data: data ?? this.data,
    );
  }
}

class LandfillHomeData {
  final int activePolygonsCount;
  final int camerasCount;
  final double monthlyVolumeM3;
  final List<Act> recentActs;

  const LandfillHomeData({
    required this.activePolygonsCount,
    required this.camerasCount,
    required this.monthlyVolumeM3,
    required this.recentActs,
  });
}

final landfillHomeControllerProvider =
    StateNotifierProvider<LandfillHomeController, LandfillHomeState>((ref) {
  final operationsRepo = ref.watch(operationsRepositoryProvider);
  final actsCollection = ref.watch(actsCollectionProvider);
  final authState = ref.watch(authNotifierProvider);
  final organizationId = authState.user?.organizationId;

  return LandfillHomeController(
    operationsRepository: operationsRepo,
    actsCollection: actsCollection,
    organizationId: organizationId,
  );
});

class LandfillHomeController extends StateNotifier<LandfillHomeState> {
  LandfillHomeController({
    required OperationsRepository operationsRepository,
    required ActsCollection actsCollection,
    String? organizationId,
  })  : _operationsRepository = operationsRepository,
        _actsCollection = actsCollection,
        _organizationId = organizationId,
        super(LandfillHomeState.initial()) {
    _loadData();
  }

  final OperationsRepository _operationsRepository;
  final ActsCollection _actsCollection;
  final String? _organizationId;

  Future<void> _loadData() async {
    state = state.copyWith(data: const AsyncLoading());
    state = state.copyWith(
      data: await AsyncValue.guard(() async {
        // Загружаем полигоны организации
        // API должен возвращать только полигоны текущей организации для LANDFILL
        final allPolygons = await _operationsRepository.loadPolygons(onlyActive: true);
        final activePolygons = allPolygons;

        // Подсчитываем камеры
        int totalCameras = 0;
        for (final polygon in activePolygons) {
          try {
            final cameras = await _operationsRepository.getPolygonCameras(polygon.id);
            totalCameras += cameras.length;
          } catch (e) {
            // Игнорируем ошибки загрузки камер
          }
        }

        // Загружаем объём за текущий месяц
        final now = DateTime.now();
        final monthStart = DateTime(now.year, now.month, 1);
        final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

        double monthlyVolume = 0.0;
        try {
          final journalData = await _operationsRepository.getLandfillReceptionJournal(
            dateFrom: monthStart,
            dateTo: monthEnd,
          );
          final tripsData = journalData['data'] as Map<String, dynamic>?;
          monthlyVolume = (tripsData?['total_volume_m3'] as num?)?.toDouble() ?? 0.0;
        } catch (e) {
          // Игнорируем ошибки загрузки журнала
        }

        // Загружаем последние акты
        List<Act> recentActs = [];
        try {
          final actsResult = await _actsCollection.getLandfillActs();
          final actsData = actsResult['data'] as Map<String, dynamic>?;
          final actsList = actsData?['acts'] as List<dynamic>? ?? [];
          recentActs = actsList
              .map((json) => Act.fromJson(json as Map<String, dynamic>))
              .toList();
          // Сортируем по дате создания (новые первыми) и берём первые 5
          recentActs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          recentActs = recentActs.take(5).toList();
        } catch (e) {
          // Игнорируем ошибки загрузки актов
        }

        return LandfillHomeData(
          activePolygonsCount: activePolygons.length,
          camerasCount: totalCameras,
          monthlyVolumeM3: monthlyVolume,
          recentActs: recentActs,
        );
      }),
    );
  }

  Future<void> refresh() => _loadData();
}

