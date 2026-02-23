import 'package:akimat_project/modules/dashboard/src/model/organizations/user_role.dart';
import 'package:akimat_project/modules/dashboard/src/model/polygons/camera.dart';
import 'package:akimat_project/modules/dashboard/src/model/polygons/polygon.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PolygonsData {
  final List<Polygon> polygons;
  final List<Camera> cameras;

  const PolygonsData({
    required this.polygons,
    required this.cameras,
  });
}

class PolygonsState {
  final AsyncValue<PolygonsData> data;
  final UserRole role;
  final String? organizationId;
  final Polygon? selectedPolygon;

  PolygonsState({
    required this.data,
    required this.role,
    this.organizationId,
    this.selectedPolygon,
  });

  factory PolygonsState.initial({
    required UserRole role,
    String? organizationId,
  }) {
    return PolygonsState(
      data: const AsyncLoading(),
      role: role,
      organizationId: organizationId,
    );
  }

  PolygonsState copyWith({
    AsyncValue<PolygonsData>? data,
    UserRole? role,
    String? organizationId,
    Polygon? selectedPolygon,
  }) {
    return PolygonsState(
      data: data ?? this.data,
      role: role ?? this.role,
      organizationId: organizationId ?? this.organizationId,
      selectedPolygon: selectedPolygon ?? this.selectedPolygon,
    );
  }
}

