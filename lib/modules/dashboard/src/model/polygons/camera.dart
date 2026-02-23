import 'package:equatable/equatable.dart';

enum CameraType { lpr, volume }

class Camera extends Equatable {
  final String id;
  final String polygonId;
  final CameraType type;
  final String name;
  final List<double>? location; // [longitude, latitude] for POINT
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Camera({
    required this.id,
    required this.polygonId,
    required this.type,
    required this.name,
    this.location,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  Camera copyWith({
    String? id,
    String? polygonId,
    CameraType? type,
    String? name,
    List<double>? location,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Camera(
      id: id ?? this.id,
      polygonId: polygonId ?? this.polygonId,
      type: type ?? this.type,
      name: name ?? this.name,
      location: location ?? this.location,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        polygonId,
        type,
        name,
        location,
        isActive,
        createdAt,
        updatedAt,
      ];
}

