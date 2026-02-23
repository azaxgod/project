import 'package:equatable/equatable.dart';

enum ContractWorkType {
  road,
  sidewalk,
  yard,
}

enum ContractType {
  contractorService, // CONTRACTOR_SERVICE - контракт с подрядчиком (вывоз снега)
  landfillService,  // LANDFILL_SERVICE - контракт с оператором полигона (приём снега)
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
  final String? contractorId; // FK → organization.id (type = CONTRACTOR) - для CONTRACTOR_SERVICE
  final String? landfillId; // FK → organization.id (type = LANDFILL) - для LANDFILL_SERVICE
  final String? createdByOrgId; // Кто создал (KGU ZKH)
  final String name; // Название контракта
  final ContractType contractType; // Тип контракта: CONTRACTOR_SERVICE или LANDFILL_SERVICE
  final ContractWorkType? workType; // Тип работ: road, sidewalk, yard (только для CONTRACTOR_SERVICE)
  final double pricePerM3; // Цена за кубометр
  final double? budgetTotal; // Максимальная сумма по договору (опционально для LANDFILL_SERVICE)
  final double? minimalVolumeM3; // Минимальный обязательный объём (опционально для LANDFILL_SERVICE)
  final List<String>? polygonIds; // Список ID полигонов (только для LANDFILL_SERVICE)
  final double? vatRate; // Ставка НДС (опционально)
  final DateTime startAt; // Период начала действия
  final DateTime endAt; // Период окончания действия
  final bool isActive;
  final ContractUsage? usage; // Использование контракта (вычисляемое поле)
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Contract({
    required this.id,
    this.contractorId,
    this.landfillId,
    this.createdByOrgId,
    required this.name,
    required this.contractType,
    this.workType,
    required this.pricePerM3,
    this.budgetTotal,
    this.minimalVolumeM3,
    this.polygonIds,
    this.vatRate,
    required this.startAt,
    required this.endAt,
    required this.isActive,
    this.usage,
    required this.createdAt,
    this.updatedAt,
  });

  Contract copyWith({
    String? id,
    Object? contractorId = _keepContractorId,
    Object? landfillId = _keepLandfillId,
    Object? createdByOrgId = _keepCreatedByOrg,
    String? name,
    ContractType? contractType,
    Object? workType = _keepWorkType,
    double? pricePerM3,
    Object? budgetTotal = _keepBudgetTotal,
    Object? minimalVolumeM3 = _keepMinimalVolumeM3,
    Object? polygonIds = _keepPolygonIds,
    Object? vatRate = _keepVatRate,
    DateTime? startAt,
    DateTime? endAt,
    bool? isActive,
    Object? usage = _keepUsage,
    DateTime? createdAt,
    Object? updatedAt = _keepUpdatedAt,
  }) {
    return Contract(
      id: id ?? this.id,
      contractorId: contractorId == _keepContractorId ? this.contractorId : contractorId as String?,
      landfillId: landfillId == _keepLandfillId ? this.landfillId : landfillId as String?,
      createdByOrgId: createdByOrgId == _keepCreatedByOrg ? this.createdByOrgId : createdByOrgId as String?,
      name: name ?? this.name,
      contractType: contractType ?? this.contractType,
      workType: workType == _keepWorkType ? this.workType : workType as ContractWorkType?,
      pricePerM3: pricePerM3 ?? this.pricePerM3,
      budgetTotal: budgetTotal == _keepBudgetTotal ? this.budgetTotal : budgetTotal as double?,
      minimalVolumeM3: minimalVolumeM3 == _keepMinimalVolumeM3 ? this.minimalVolumeM3 : minimalVolumeM3 as double?,
      polygonIds: polygonIds == _keepPolygonIds ? this.polygonIds : polygonIds as List<String>?,
      vatRate: vatRate == _keepVatRate ? this.vatRate : vatRate as double?,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      isActive: isActive ?? this.isActive,
      usage: usage == _keepUsage ? this.usage : usage as ContractUsage?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt == _keepUpdatedAt ? this.updatedAt : updatedAt as DateTime?,
    );
  }

  static const _keepContractorId = Object();
  static const _keepLandfillId = Object();
  static const _keepCreatedByOrg = Object();
  static const _keepWorkType = Object();
  static const _keepBudgetTotal = Object();
  static const _keepMinimalVolumeM3 = Object();
  static const _keepPolygonIds = Object();
  static const _keepVatRate = Object();
  static const _keepUsage = Object();
  static const _keepUpdatedAt = Object();

  @override
  List<Object?> get props => [
        id,
        contractorId,
        landfillId,
        createdByOrgId,
        name,
        contractType,
        workType,
        pricePerM3,
        budgetTotal,
        minimalVolumeM3,
        polygonIds,
        vatRate,
        startAt,
        endAt,
        isActive,
        usage,
        createdAt,
        updatedAt,
      ];
}

