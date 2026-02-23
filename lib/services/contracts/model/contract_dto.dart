import 'package:akimat_project/modules/dashboard/src/model/contracts/contract.dart';
import 'package:json_annotation/json_annotation.dart';

part 'contract_dto.g.dart';

@JsonSerializable()
class ContractDto {
  final String id;
  @JsonKey(name: 'contractor_id')
  final String? contractorId;
  @JsonKey(name: 'landfill_id')
  final String? landfillId;
  @JsonKey(name: 'created_by_org_id')
  final String? createdByOrgId;
  final String name;
  @JsonKey(name: 'contract_type')
  final String? contractType; // "CONTRACTOR_SERVICE" или "LANDFILL_SERVICE" (опционально для обратной совместимости)
  @JsonKey(name: 'work_type')
  final String? workType; // Опционально, только для CONTRACTOR_SERVICE
  @JsonKey(name: 'price_per_m3')
  final double pricePerM3;
  @JsonKey(name: 'budget_total')
  final double? budgetTotal; // Опционально для LANDFILL_SERVICE
  @JsonKey(name: 'minimal_volume_m3')
  final double? minimalVolumeM3; // Опционально для LANDFILL_SERVICE
  @JsonKey(name: 'polygon_ids')
  final List<String>? polygonIds; // Список ID полигонов для LANDFILL_SERVICE
  @JsonKey(name: 'vat_rate')
  final double? vatRate; // Ставка НДС
  @JsonKey(name: 'start_at')
  final DateTime startAt;
  @JsonKey(name: 'end_at')
  final DateTime endAt;
  @JsonKey(name: 'is_active')
  final bool isActive;
  final ContractUsageDto? usage;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  ContractDto({
    required this.id,
    this.contractorId,
    this.landfillId,
    this.createdByOrgId,
    required this.name,
    String? contractType, // Опционально для обратной совместимости
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
  }) : contractType = contractType ?? 
            (contractorId != null ? 'CONTRACTOR_SERVICE' : 'LANDFILL_SERVICE');

  factory ContractDto.fromJson(Map<String, dynamic> json) =>
      _$ContractDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ContractDtoToJson(this);

  Contract toDomain() {
    // Если contractType отсутствует (старые данные), определяем по наличию contractorId
    final type = (contractType?.isNotEmpty ?? false)
        ? contractType!
        : (contractorId != null ? 'CONTRACTOR_SERVICE' : 'LANDFILL_SERVICE');
    
    return Contract(
      id: id,
      contractorId: contractorId,
      landfillId: landfillId,
      createdByOrgId: createdByOrgId,
      name: name,
      contractType: _parseContractType(type),
      workType: workType != null ? _parseWorkType(workType!) : null,
      pricePerM3: pricePerM3,
      budgetTotal: budgetTotal,
      minimalVolumeM3: minimalVolumeM3,
      polygonIds: polygonIds,
      vatRate: vatRate,
      startAt: startAt,
      endAt: endAt,
      isActive: isActive,
      usage: usage?.toDomain(),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  ContractType _parseContractType(String type) {
    switch (type.toUpperCase()) {
      case 'CONTRACTOR_SERVICE':
        return ContractType.contractorService;
      case 'LANDFILL_SERVICE':
        return ContractType.landfillService;
      default:
        return ContractType.contractorService;
    }
  }

  ContractWorkType _parseWorkType(String type) {
    switch (type.toLowerCase()) {
      case 'road':
        return ContractWorkType.road;
      case 'sidewalk':
        return ContractWorkType.sidewalk;
      case 'yard':
        return ContractWorkType.yard;
      default:
        return ContractWorkType.road;
    }
  }

  static String contractTypeToString(ContractType type) {
    switch (type) {
      case ContractType.contractorService:
        return 'CONTRACTOR_SERVICE';
      case ContractType.landfillService:
        return 'LANDFILL_SERVICE';
    }
  }

  static String workTypeToString(ContractWorkType type) {
    switch (type) {
      case ContractWorkType.road:
        return 'road';
      case ContractWorkType.sidewalk:
        return 'sidewalk';
      case ContractWorkType.yard:
        return 'yard';
    }
  }
}

@JsonSerializable()
class ContractUsageDto {
  @JsonKey(name: 'total_volume_m3')
  final double totalVolumeM3;
  @JsonKey(name: 'total_cost')
  final double totalCost;

  ContractUsageDto({
    required this.totalVolumeM3,
    required this.totalCost,
  });

  factory ContractUsageDto.fromJson(Map<String, dynamic> json) =>
      _$ContractUsageDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ContractUsageDtoToJson(this);

  ContractUsage toDomain() {
    return ContractUsage(
      totalVolumeM3: totalVolumeM3,
      totalCost: totalCost,
    );
  }
}

