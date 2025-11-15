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
  Future<Contract> createContract({
    required String contractorId,
    required String name,
    required ContractWorkType workType,
    required double pricePerM3,
    required double budgetTotal,
    required double minimalVolumeM3,
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

