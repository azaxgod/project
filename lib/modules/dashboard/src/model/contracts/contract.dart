import 'package:equatable/equatable.dart';

class Contract extends Equatable {
  final String id;
  final String contractorId; // FK → organization.id (type = CONTRACTOR)
  final String contractNumber; // Номер договора
  final DateTime startDate;
  final DateTime endDate;
  final String? description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Contract({
    required this.id,
    required this.contractorId,
    required this.contractNumber,
    required this.startDate,
    required this.endDate,
    this.description,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  Contract copyWith({
    String? id,
    String? contractorId,
    String? contractNumber,
    DateTime? startDate,
    DateTime? endDate,
    Object? description = _keepDescription,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Contract(
      id: id ?? this.id,
      contractorId: contractorId ?? this.contractorId,
      contractNumber: contractNumber ?? this.contractNumber,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      description: description == _keepDescription ? this.description : description as String?,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static const _keepDescription = Object();

  @override
  List<Object?> get props => [
        id,
        contractorId,
        contractNumber,
        startDate,
        endDate,
        description,
        isActive,
        createdAt,
        updatedAt,
      ];
}

