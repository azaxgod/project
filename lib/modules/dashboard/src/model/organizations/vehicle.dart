import 'package:equatable/equatable.dart';

class Vehicle extends Equatable {
  final String id;
  final String contractorId;
  final String? driverId;
  final String plateNumber;
  final String brand;
  final String model;
  final String color;
  final int year;
  final double bodyVolumeM3;
  final String? photoUrl;
  final bool isActive;

  const Vehicle({
    required this.id,
    required this.contractorId,
    required this.driverId,
    required this.plateNumber,
    required this.brand,
    required this.model,
    required this.color,
    required this.year,
    required this.bodyVolumeM3,
    this.photoUrl,
    required this.isActive,
  });

  Vehicle copyWith({
    String? id,
    String? contractorId,
    Object? driverId = _keepDriver,
    String? plateNumber,
    String? brand,
    String? model,
    String? color,
    int? year,
    double? bodyVolumeM3,
    String? photoUrl,
    bool? isActive,
  }) {
    return Vehicle(
      id: id ?? this.id,
      contractorId: contractorId ?? this.contractorId,
      driverId: driverId == _keepDriver ? this.driverId : driverId as String?,
      plateNumber: plateNumber ?? this.plateNumber,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      color: color ?? this.color,
      year: year ?? this.year,
      bodyVolumeM3: bodyVolumeM3 ?? this.bodyVolumeM3,
      photoUrl: photoUrl ?? this.photoUrl,
      isActive: isActive ?? this.isActive,
    );
  }

  static const _keepDriver = Object();

  @override
  List<Object?> get props => [
        id,
        contractorId,
        driverId,
        plateNumber,
        brand,
        model,
        color,
        year,
        bodyVolumeM3,
        photoUrl,
        isActive,
      ];
}

