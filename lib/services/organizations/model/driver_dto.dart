import 'package:akimat_project/modules/dashboard/src/model/organizations/driver.dart';

class DriverDto {
  DriverDto({
    required this.id,
    required this.contractorId,
    required this.fullName,
    required this.iin,
    this.birthYear,
    required this.phone,
    required this.isActive,
  });

  final String id;
  final String contractorId;
  final String fullName;
  final String iin;
  final int? birthYear;
  final String phone;
  final bool isActive;

  factory DriverDto.fromJson(Map<String, dynamic> json) {
    return DriverDto(
      id: json['id'] as String? ?? '',
      contractorId: json['contractorID'] as String? ?? json['contractorId'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      iin: json['iin'] as String? ?? '',
      birthYear: json['birthYear'] as int?,
      phone: json['phone'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'contractorId': contractorId,
        'fullName': fullName,
        'iin': iin,
        'birthYear': birthYear,
        'phone': phone,
        'isActive': isActive,
      };

  Driver toDomain() {
    return Driver(
      id: id,
      contractorId: contractorId,
      fullName: fullName,
      iin: iin,
      birthYear: birthYear,
      phone: phone,
      isActive: isActive,
    );
  }

  DriverDto copyWith({
    String? id,
    String? contractorId,
    String? fullName,
    String? iin,
    int? birthYear,
    String? phone,
    bool? isActive,
  }) {
    return DriverDto(
      id: id ?? this.id,
      contractorId: contractorId ?? this.contractorId,
      fullName: fullName ?? this.fullName,
      iin: iin ?? this.iin,
      birthYear: birthYear ?? this.birthYear,
      phone: phone ?? this.phone,
      isActive: isActive ?? this.isActive,
    );
  }
}

