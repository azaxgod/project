import 'package:akimat_project/modules/dashboard/src/model/contracts/contract.dart';

abstract class ContractsRepository {
  /// Получить список контрактов с фильтрами
  Future<List<Contract>> loadContracts({
    String? contractorId,
    ContractWorkType? workType,
    ContractStatus? status,
    bool? onlyActive,
    DateTime? startFrom,
    DateTime? startTo,
    DateTime? endFrom,
    DateTime? endTo,
  });

  /// Получить контракт по ID
  Future<Contract> getContract(String id);

  /// Создать новый контракт
  /// Поддерживает создание контрактов CONTRACTOR_SERVICE и LANDFILL_SERVICE
  Future<Contract> createContract({
    required ContractType contractType,
    String? contractorId, // Для CONTRACTOR_SERVICE
    String? landfillId, // Для LANDFILL_SERVICE
    required String name,
    ContractWorkType? workType, // Только для CONTRACTOR_SERVICE
    required double pricePerM3,
    double? budgetTotal, // Опционально для LANDFILL_SERVICE
    double? minimalVolumeM3, // Опционально для LANDFILL_SERVICE
    List<String>? polygonIds, // Для LANDFILL_SERVICE
    double? vatRate, // Ставка НДС
    required DateTime startAt,
    required DateTime endAt,
    required bool isActive,
    String? createdByOrgId, // ID организации KGU ZKH, создающей контракт
  });

  /// Связать тикет с контрактом
  Future<void> linkTicketToContract(String ticketId, String contractId);

  /// Зафиксировать использование рейса
  Future<void> recordTripUsage({
    required String tripId,
    required String ticketId,
    required double detectedVolumeM3,
  });
}

