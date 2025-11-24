// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contract_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContractDto _$ContractDtoFromJson(Map<String, dynamic> json) => ContractDto(
      id: json['id'] as String,
      contractorId: json['contractor_id'] as String?,
      landfillId: json['landfill_id'] as String?,
      createdByOrgId: json['created_by_org_id'] as String?,
      name: json['name'] as String,
      contractType: json['contract_type'] as String?,
      workType: json['work_type'] as String?,
      pricePerM3: (json['price_per_m3'] as num).toDouble(),
      budgetTotal: (json['budget_total'] as num?)?.toDouble(),
      minimalVolumeM3: (json['minimal_volume_m3'] as num?)?.toDouble(),
      polygonIds: (json['polygon_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      vatRate: (json['vat_rate'] as num?)?.toDouble(),
      startAt: DateTime.parse(json['start_at'] as String),
      endAt: DateTime.parse(json['end_at'] as String),
      isActive: json['is_active'] as bool,
      usage: json['usage'] == null
          ? null
          : ContractUsageDto.fromJson(json['usage'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$ContractDtoToJson(ContractDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'contractor_id': instance.contractorId,
      'landfill_id': instance.landfillId,
      'created_by_org_id': instance.createdByOrgId,
      'name': instance.name,
      'contract_type': instance.contractType,
      'work_type': instance.workType,
      'price_per_m3': instance.pricePerM3,
      'budget_total': instance.budgetTotal,
      'minimal_volume_m3': instance.minimalVolumeM3,
      'polygon_ids': instance.polygonIds,
      'vat_rate': instance.vatRate,
      'start_at': instance.startAt.toIso8601String(),
      'end_at': instance.endAt.toIso8601String(),
      'is_active': instance.isActive,
      'usage': instance.usage,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

ContractUsageDto _$ContractUsageDtoFromJson(Map<String, dynamic> json) =>
    ContractUsageDto(
      totalVolumeM3: (json['total_volume_m3'] as num).toDouble(),
      totalCost: (json['total_cost'] as num).toDouble(),
    );

Map<String, dynamic> _$ContractUsageDtoToJson(ContractUsageDto instance) =>
    <String, dynamic>{
      'total_volume_m3': instance.totalVolumeM3,
      'total_cost': instance.totalCost,
    };
