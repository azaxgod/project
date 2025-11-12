import 'package:akimat_project/modules/dashboard/src/model/organizations/vehicle.dart';

class VehicleDto {
  VehicleDto({
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

  factory VehicleDto.fromJson(Map<String, dynamic> json) {
    return VehicleDto(
      id: json['id'] as String,
      contractorId: json['contractorId'] as String,
      driverId: json['driverId'] as String?,
      plateNumber: json['plateNumber'] as String,
      brand: json['brand'] as String,
      model: json['model'] as String,
      color: json['color'] as String,
      year: json['year'] as int,
      bodyVolumeM3: (json['bodyVolumeM3'] as num).toDouble(),
      photoUrl: json['photoUrl'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'contractorId': contractorId,
        'driverId': driverId,
        'plateNumber': plateNumber,
        'brand': brand,
        'model': model,
        'color': color,
        'year': year,
        'bodyVolumeM3': bodyVolumeM3,
        'photoUrl': photoUrl,
        'isActive': isActive,
      };

  Vehicle toDomain() {
    return Vehicle(
      id: id,
      contractorId: contractorId,
      driverId: driverId,
      plateNumber: plateNumber,
      brand: brand,
      model: model,
      color: color,
      year: year,
      bodyVolumeM3: bodyVolumeM3,
      photoUrl: photoUrl,
      isActive: isActive,
    );
  }

  VehicleDto copyWith({
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
    return VehicleDto(
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
}

