import 'package:equatable/equatable.dart';

/// Тип акта
enum ActType {
  contractorService, // Акты КГУ ↔ подрядчики (вывоз снега)
  landfillService,   // Акты КГУ ↔ LANDFILL (приём снега)
}

/// Статус акта
enum ActStatus {
  draft,                    // DRAFT - черновик
  sentToLandfill,           // SENT_TO_LANDFILL - отправлен оператору полигона
  confirmedByLandfill,      // CONFIRMED_BY_LANDFILL - подтверждён LANDFILL
  approvedByKgu,           // APPROVED_BY_KGU - утверждён КГУ
  signed,                  // SIGNED - подписан
  rejected,                // REJECTED - отклонён
}

/// Объём по полигону (для актов приёма)
class ActPolygonVolume extends Equatable {
  final String polygonId;
  final String polygonName;
  final double volumeM3;

  const ActPolygonVolume({
    required this.polygonId,
    required this.polygonName,
    required this.volumeM3,
  });

  factory ActPolygonVolume.fromJson(Map<String, dynamic> json) {
    return ActPolygonVolume(
      polygonId: json['polygon_id'] as String,
      polygonName: json['polygon_name'] as String,
      volumeM3: (json['volume_m3'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'polygon_id': polygonId,
      'polygon_name': polygonName,
      'volume_m3': volumeM3,
    };
  }

  @override
  List<Object?> get props => [polygonId, polygonName, volumeM3];
}

/// Объём по подрядчику (информация для актов приёма)
class ActContractorVolume extends Equatable {
  final String contractorId;
  final String contractorName;
  final double volumeM3;

  const ActContractorVolume({
    required this.contractorId,
    required this.contractorName,
    required this.volumeM3,
  });

  factory ActContractorVolume.fromJson(Map<String, dynamic> json) {
    return ActContractorVolume(
      contractorId: json['contractor_id'] as String,
      contractorName: json['contractor_name'] as String,
      volumeM3: (json['volume_m3'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'contractor_id': contractorId,
      'contractor_name': contractorName,
      'volume_m3': volumeM3,
    };
  }

  @override
  List<Object?> get props => [contractorId, contractorName, volumeM3];
}

/// Акт выполненных работ
class Act extends Equatable {
  final String id;
  final String contractId; // FK → contract.id
  final ActType actType; // Тип акта: CONTRACTOR_SERVICE или LANDFILL_SERVICE
  final String? contractorId; // Для актов с подрядчиками
  final String? landfillId; // Для актов с LANDFILL
  final String actNumber; // Номер акта
  final DateTime periodStart; // Начало периода
  final DateTime periodEnd; // Конец периода
  final double totalVolumeM3; // Общий объём м³
  final double pricePerM3; // Цена за м³ (из контракта)
  final double? vatRate; // Ставка НДС
  final double totalAmount; // Общая сумма
  final double? vatAmount; // Сумма НДС
  final double totalWithVat; // Сумма с НДС
  final ActStatus status; // Статус акта
  final String? rejectionReason; // Причина отклонения (если отклонён)
  final String? approvedByOrgId; // ID организации, подтвердившей акт
  final String? approvedByUserId; // ID пользователя, подтвердившего акт
  final DateTime? approvedAt; // Дата подтверждения
  final List<ActPolygonVolume>? polygonVolumes; // Объёмы по полигонам (для актов приёма)
  final List<ActContractorVolume>? contractorVolumes; // Объёмы по подрядчикам (инфо для актов приёма)
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Act({
    required this.id,
    required this.contractId,
    required this.actType,
    this.contractorId,
    this.landfillId,
    required this.actNumber,
    required this.periodStart,
    required this.periodEnd,
    required this.totalVolumeM3,
    required this.pricePerM3,
    this.vatRate,
    required this.totalAmount,
    this.vatAmount,
    required this.totalWithVat,
    required this.status,
    this.rejectionReason,
    this.approvedByOrgId,
    this.approvedByUserId,
    this.approvedAt,
    this.polygonVolumes,
    this.contractorVolumes,
    required this.createdAt,
    this.updatedAt,
  });

  factory Act.fromJson(Map<String, dynamic> json) {
    return Act(
      id: json['id'] as String,
      contractId: json['contract_id'] as String,
      actType: _parseActType(json['act_type'] as String? ?? json['contract_type'] as String? ?? 'CONTRACTOR_SERVICE'),
      contractorId: json['contractor_id'] as String?,
      landfillId: json['landfill_id'] as String?,
      actNumber: json['act_number'] as String,
      periodStart: DateTime.parse(json['period_start'] as String),
      periodEnd: DateTime.parse(json['period_end'] as String),
      totalVolumeM3: (json['total_volume_m3'] as num).toDouble(),
      pricePerM3: (json['price_per_m3'] as num).toDouble(),
      vatRate: json['vat_rate'] != null ? (json['vat_rate'] as num).toDouble() : null,
      totalAmount: (json['total_amount'] as num).toDouble(),
      vatAmount: json['vat_amount'] != null ? (json['vat_amount'] as num).toDouble() : null,
      totalWithVat: (json['total_with_vat'] as num).toDouble(),
      status: _parseStatus(json['status'] as String),
      rejectionReason: json['rejection_reason'] as String?,
      approvedByOrgId: json['approved_by_org_id'] as String?,
      approvedByUserId: json['approved_by_user_id'] as String?,
      approvedAt: json['approved_at'] != null ? DateTime.parse(json['approved_at'] as String) : null,
      polygonVolumes: json['polygon_volumes'] != null
          ? (json['polygon_volumes'] as List<dynamic>)
              .map((v) => ActPolygonVolume.fromJson(v as Map<String, dynamic>))
              .toList()
          : null,
      contractorVolumes: json['contractor_volumes'] != null
          ? (json['contractor_volumes'] as List<dynamic>)
              .map((v) => ActContractorVolume.fromJson(v as Map<String, dynamic>))
              .toList()
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  static ActType _parseActType(String type) {
    switch (type.toUpperCase()) {
      case 'CONTRACTOR_SERVICE':
        return ActType.contractorService;
      case 'LANDFILL_SERVICE':
        return ActType.landfillService;
      default:
        return ActType.contractorService;
    }
  }

  static ActStatus _parseStatus(String status) {
    switch (status.toUpperCase()) {
      case 'DRAFT':
        return ActStatus.draft;
      case 'SENT_TO_LANDFILL':
        return ActStatus.sentToLandfill;
      case 'CONFIRMED_BY_LANDFILL':
        return ActStatus.confirmedByLandfill;
      case 'APPROVED_BY_KGU':
        return ActStatus.approvedByKgu;
      case 'SIGNED':
        return ActStatus.signed;
      case 'REJECTED':
        return ActStatus.rejected;
      default:
        return ActStatus.draft;
    }
  }

  static String statusToString(ActStatus status) {
    switch (status) {
      case ActStatus.draft:
        return 'DRAFT';
      case ActStatus.sentToLandfill:
        return 'SENT_TO_LANDFILL';
      case ActStatus.confirmedByLandfill:
        return 'CONFIRMED_BY_LANDFILL';
      case ActStatus.approvedByKgu:
        return 'APPROVED_BY_KGU';
      case ActStatus.signed:
        return 'SIGNED';
      case ActStatus.rejected:
        return 'REJECTED';
    }
  }

  @override
  List<Object?> get props => [
        id,
        contractId,
        actType,
        contractorId,
        landfillId,
        actNumber,
        periodStart,
        periodEnd,
        totalVolumeM3,
        pricePerM3,
        vatRate,
        totalAmount,
        vatAmount,
        totalWithVat,
        status,
        rejectionReason,
        approvedByOrgId,
        approvedByUserId,
        approvedAt,
        polygonVolumes,
        contractorVolumes,
        createdAt,
        updatedAt,
      ];
}






