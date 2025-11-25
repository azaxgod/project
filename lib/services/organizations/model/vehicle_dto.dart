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
    // Поддержка разных вариантов названий полей (ID/ContractorID от API и id/contractorId от клиента)
    final id = json['ID'] as String? ?? 
               json['id'] as String? ?? 
               '';
    final contractorId = json['ContractorID'] as String? ?? 
                        json['contractor_id'] as String? ?? 
                        json['contractorId'] as String? ?? 
                        '';
    final driverId = json['DriverID'] as String? ?? 
                    json['driver_id'] as String? ?? 
                    json['driverId'] as String?;
    final plateNumber = json['PlateNumber'] as String? ?? 
                       json['plate_number'] as String? ?? 
                       json['plateNumber'] as String? ?? 
                       '';
    final brand = json['Brand'] as String? ?? 
                 json['brand'] as String? ?? 
                 '';
    final model = json['Model'] as String? ?? 
                 json['model'] as String? ?? 
                 '';
    final color = json['Color'] as String? ?? 
                 json['color'] as String? ?? 
                 '';
    final year = json['Year'] as int? ?? 
                json['year'] as int? ?? 
                0;
    final bodyVolumeM3 = (json['BodyVolumeM3'] as num?)?.toDouble() ?? 
                        (json['body_volume_m3'] as num?)?.toDouble() ?? 
                        (json['bodyVolumeM3'] as num?)?.toDouble() ?? 
                        0.0;
    final photoUrl = json['PhotoURL'] as String? ?? 
                    json['photo_url'] as String? ?? 
                    json['photoUrl'] as String?;
    final isActive = json['IsActive'] as bool? ?? 
                    json['is_active'] as bool? ?? 
                    json['isActive'] as bool? ?? 
                    true;
    
    return VehicleDto(
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

