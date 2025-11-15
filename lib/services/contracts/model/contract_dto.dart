import 'package:akimat_project/modules/dashboard/src/model/contracts/contract.dart';
import 'package:json_annotation/json_annotation.dart';

part 'contract_dto.g.dart';

@JsonSerializable()
class ContractDto {
  final String id;
  @JsonKey(name: 'contractor_id')
  final String contractorId;
  @JsonKey(name: 'created_by_org_id')
  final String? createdByOrgId;
  final String name;
  @JsonKey(name: 'work_type')
  final String workType;
  @JsonKey(name: 'price_per_m3')
  final double pricePerM3;
  @JsonKey(name: 'budget_total')
  final double budgetTotal;
  @JsonKey(name: 'minimal_volume_m3')
  final double minimalVolumeM3;
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

  factory ContractDto.fromJson(Map<String, dynamic> json) =>
      _$ContractDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ContractDtoToJson(this);

  Contract toDomain() {
    return Contract(
      id: id,
      contractorId: contractorId,
      createdByOrgId: createdByOrgId,
      name: name,
      workType: _parseWorkType(workType),
      pricePerM3: pricePerM3,
      budgetTotal: budgetTotal,
      minimalVolumeM3: minimalVolumeM3,
      startAt: startAt,
      endAt: endAt,
      isActive: isActive,
      usage: usage?.toDomain(),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
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

