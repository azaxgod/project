import 'package:equatable/equatable.dart';

class Driver extends Equatable {
  final String id;
  final String contractorId;
  final String fullName;
  final String iin;
  final int? birthYear;
  final String phone;
  final bool isActive;

  const Driver({
    required this.id,
    required this.contractorId,
    required this.fullName,
    required this.iin,
    this.birthYear,
    required this.phone,
    required this.isActive,
  });

  Driver copyWith({
    String? id,
    String? contractorId,
    String? fullName,
    String? iin,
    int? birthYear,
    String? phone,
    bool? isActive,
  }) {
    return Driver(
      id: id ?? this.id,
      contractorId: contractorId ?? this.contractorId,
      fullName: fullName ?? this.fullName,
      iin: iin ?? this.iin,
      birthYear: birthYear ?? this.birthYear,
      phone: phone ?? this.phone,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
        id,
        contractorId,
        fullName,
        iin,
        birthYear,
        phone,
        isActive,
      ];
}

