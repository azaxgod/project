import 'package:equatable/equatable.dart';

enum ContractWorkType {
  road,
  sidewalk,
  yard,
}

enum ContractStatus {
  planned,
  active,
  expired,
  archived,
}

class ContractUsage extends Equatable {
  final double totalVolumeM3;
  final double totalCost;

  const ContractUsage({
    required this.totalVolumeM3,
    required this.totalCost,
  });

  factory ContractUsage.fromJson(Map<String, dynamic> json) {
    return ContractUsage(
      totalVolumeM3: (json['total_volume_m3'] as num).toDouble(),
      totalCost: (json['total_cost'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_volume_m3': totalVolumeM3,
      'total_cost': totalCost,
    };
  }

  @override
  List<Object?> get props => [totalVolumeM3, totalCost];
}

class Contract extends Equatable {
  final String id;
  final String contractorId; // FK → organization.id (type = CONTRACTOR)
  final String? createdByOrgId; // Кто создал (Акимат/ТОО)
  final String name; // Название контракта
  final ContractWorkType workType; // Тип работ: road, sidewalk, yard
  final double pricePerM3; // Цена за кубометр
  final double budgetTotal; // Максимальная сумма по договору
  final double minimalVolumeM3; // Минимальный обязательный объём вывоза
  final DateTime startAt; // Период начала действия
  final DateTime endAt; // Период окончания действия
  final bool isActive;
  final ContractUsage? usage; // Использование контракта (вычисляемое поле)
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Contract({
    required this.id,
    required this.contractorId,
    this.createdByOrgId,
    required this.name,
    required this.workType,
    required this.pricePerM3,
    required this.budgetTotal,
    required this.minimalVolumeM3,
    required this.startAt,
    required this.endAt,
    required this.isActive,
    this.usage,
    required this.createdAt,
    this.updatedAt,
  });

  Contract copyWith({
    String? id,
    String? contractorId,
    Object? createdByOrgId = _keepCreatedByOrg,
    String? name,
    ContractWorkType? workType,
    double? pricePerM3,
    double? budgetTotal,
    double? minimalVolumeM3,
    DateTime? startAt,
    DateTime? endAt,
    bool? isActive,
    Object? usage = _keepUsage,
    DateTime? createdAt,
    Object? updatedAt = _keepUpdatedAt,
  }) {
    return Contract(
      id: id ?? this.id,
      contractorId: contractorId ?? this.contractorId,
      createdByOrgId: createdByOrgId == _keepCreatedByOrg ? this.createdByOrgId : createdByOrgId as String?,
      name: name ?? this.name,
      workType: workType ?? this.workType,
      pricePerM3: pricePerM3 ?? this.pricePerM3,
      budgetTotal: budgetTotal ?? this.budgetTotal,
      minimalVolumeM3: minimalVolumeM3 ?? this.minimalVolumeM3,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      isActive: isActive ?? this.isActive,
      usage: usage == _keepUsage ? this.usage : usage as ContractUsage?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt == _keepUpdatedAt ? this.updatedAt : updatedAt as DateTime?,
    );
  }

  static const _keepCreatedByOrg = Object();
  static const _keepUsage = Object();
  static const _keepUpdatedAt = Object();

  @override
  List<Object?> get props => [
        id,
        contractorId,
        createdByOrgId,
        name,
        workType,
        pricePerM3,
        budgetTotal,
        minimalVolumeM3,
        startAt,
        endAt,
        isActive,
        usage,
        createdAt,
        updatedAt,
      ];
}

