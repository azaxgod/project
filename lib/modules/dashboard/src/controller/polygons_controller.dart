import 'package:akimat_project/modules/auth/src/controller/auth_notifier.dart';
import 'package:akimat_project/modules/dashboard/src/controller/polygons_state.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/user_role.dart';
import 'package:akimat_project/modules/dashboard/src/model/polygons/camera.dart';
import 'package:akimat_project/modules/dashboard/src/model/polygons/polygon.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final polygonsControllerProvider = StateNotifierProvider<PolygonsController, PolygonsState>((ref) {
  final authState = ref.watch(authNotifierProvider);
  final role = userRoleFromString(authState.user?.role);
  final organizationId = authState.user?.organizationId;
  
  return PolygonsController(
    initialState: PolygonsState.initial(
      role: role,
      organizationId: organizationId,
    ),
  );
});

class PolygonsController extends StateNotifier<PolygonsState> {
  PolygonsController({
    required PolygonsState initialState,
  }) : super(initialState) {
    _loadData();
  }

  Future<void> _loadData() async {
    state = state.copyWith(data: const AsyncLoading());
    state = state.copyWith(
      data: await AsyncValue.guard(() async {
        // TODO: Load polygons and cameras from repository when implemented
        return PolygonsData(
          polygons: [],
          cameras: [],
        );
      }),
    );
  }

  Future<void> refresh() => _loadData();

  Future<void> createPolygon(Polygon polygon) async {
    final result = await AsyncValue.guard(() async {
      // TODO: Implement repository method
      return polygon;
    });
    
    if (!result.hasError) {
      await _loadData();
    }
  }

  Future<void> updatePolygon(Polygon polygon) async {
    final result = await AsyncValue.guard(() async {
      // TODO: Implement repository method
      return polygon;
    });
    
    if (!result.hasError) {
      await _loadData();
    }
  }

  Future<void> createCamera(Camera camera) async {
    final result = await AsyncValue.guard(() async {
      // TODO: Implement repository method
      return camera;
    });
    
    if (!result.hasError) {
      await _loadData();
    }
  }

  Future<void> updateCamera(Camera camera) async {
    final result = await AsyncValue.guard(() async {
      // TODO: Implement repository method
      return camera;
    });
    
    if (!result.hasError) {
      await _loadData();
    }
  }

  void selectPolygon(Polygon? polygon) {
    state = state.copyWith(selectedPolygon: polygon);
  }
}

