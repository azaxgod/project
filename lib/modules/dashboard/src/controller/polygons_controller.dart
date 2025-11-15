import 'package:akimat_project/modules/auth/src/controller/auth_notifier.dart';
import 'package:akimat_project/modules/dashboard/src/controller/areas_controller.dart';
import 'package:akimat_project/modules/dashboard/src/controller/polygons_state.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/user_role.dart';
import 'package:akimat_project/modules/dashboard/src/model/polygons/camera.dart';
import 'package:akimat_project/modules/dashboard/src/model/polygons/polygon.dart';
import 'package:akimat_project/modules/dashboard/src/repository/operations_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final polygonsControllerProvider = StateNotifierProvider<PolygonsController, PolygonsState>((ref) {
  final authState = ref.watch(authNotifierProvider);
  final role = userRoleFromString(authState.user?.role);
  final organizationId = authState.user?.organizationId;
  
  return PolygonsController(
    repository: ref.watch(operationsRepositoryProvider),
    initialState: PolygonsState.initial(
      role: role,
      organizationId: organizationId,
    ),
  );
});

class PolygonsController extends StateNotifier<PolygonsState> {
  PolygonsController({
    required OperationsRepository repository,
    required PolygonsState initialState,
  })  : _repository = repository,
        super(initialState) {
    _loadData();
  }

  final OperationsRepository _repository;

  Future<void> _loadData() async {
    state = state.copyWith(data: const AsyncLoading());
    state = state.copyWith(
      data: await AsyncValue.guard(() async {
        // Load polygons from operations service
        final polygons = await _repository.loadPolygons(onlyActive: true);
        
        // Load cameras for selected polygon or all polygons
        final cameras = <Camera>[];
        if (state.selectedPolygon != null) {
          final polygonCameras = await _repository.getPolygonCameras(
            state.selectedPolygon!.id,
          );
          cameras.addAll(polygonCameras);
        }
        
        return PolygonsData(
          polygons: polygons,
          cameras: cameras,
        );
      }),
    );
  }

  Future<void> refresh() => _loadData();

  Future<void> createPolygon(Polygon polygon) async {
    final result = await AsyncValue.guard(() async {
      return await _repository.createPolygon(
        name: polygon.name,
        address: polygon.address,
        description: polygon.description,
        geometry: polygon.geometry,
        isActive: polygon.isActive,
      );
    });
    
    if (!result.hasError) {
      await _loadData();
    }
  }

  Future<void> updatePolygon(Polygon polygon) async {
    final result = await AsyncValue.guard(() async {
      return await _repository.updatePolygon(
        polygon.id,
        name: polygon.name,
        address: polygon.address,
        description: polygon.description,
        isActive: polygon.isActive,
      );
    });
    
    if (!result.hasError) {
      await _loadData();
    }
  }

  Future<void> createCamera(Camera camera) async {
    final result = await AsyncValue.guard(() async {
      return await _repository.createCamera(
        polygonId: camera.polygonId,
        type: camera.type,
        name: camera.name,
        location: camera.location,
        isActive: camera.isActive,
      );
    });
    
    if (!result.hasError) {
      await _loadData();
    }
  }

  Future<void> updateCamera(Camera camera) async {
    final result = await AsyncValue.guard(() async {
      return await _repository.updateCamera(
        camera.polygonId,
        camera.id,
        type: camera.type,
        name: camera.name,
        location: camera.location,
        isActive: camera.isActive,
      );
    });
    
    if (!result.hasError) {
      await _loadData();
    }
  }

  void selectPolygon(Polygon? polygon) {
    state = state.copyWith(selectedPolygon: polygon);
  }
}

