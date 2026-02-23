import 'package:equatable/equatable.dart';

enum CleaningAreaStatus { inactive, active }

class CleaningArea extends Equatable {
  final String id;
  final String name;
  final String? description;
  final List<List<double>> geometry; // GeoJSON Polygon coordinates
  final String city;
  final CleaningAreaStatus status;
  final String? defaultContractorId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CleaningArea({
    required this.id,
    required this.name,
    this.description,
    required this.geometry,
    this.city = 'Петропавловск',
    required this.status,
    this.defaultContractorId,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  CleaningArea copyWith({
    String? id,
    String? name,
    String? description,
    List<List<double>>? geometry,
    String? city,
    CleaningAreaStatus? status,
    String? defaultContractorId,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CleaningArea(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      geometry: geometry ?? this.geometry,
      city: city ?? this.city,
      status: status ?? this.status,
      defaultContractorId: defaultContractorId ?? this.defaultContractorId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        geometry,
        city,
        status,
        defaultContractorId,
        isActive,
        createdAt,
        updatedAt,
      ];
}

