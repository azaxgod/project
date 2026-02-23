import 'package:equatable/equatable.dart';

class Polygon extends Equatable {
  final String id;
  final String name;
  final String? address;
  final String? description;
  final List<List<double>> geometry; // GeoJSON Polygon coordinates
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Polygon({
    required this.id,
    required this.name,
    this.address, 
    this.description,
    required this.geometry,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  Polygon copyWith({
    String? id,
    String? name,
    String? address,
    String? description,
    List<List<double>>? geometry,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Polygon(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      description: description ?? this.description,
      geometry: geometry ?? this.geometry,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        address,
        description,
        geometry,
        isActive,
        createdAt,
        updatedAt,
      ];
}

