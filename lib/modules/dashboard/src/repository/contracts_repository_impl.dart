import 'package:akimat_project/modules/dashboard/src/model/contracts/contract.dart';
import 'package:akimat_project/modules/dashboard/src/repository/contracts_repository.dart';
import 'package:akimat_project/services/contracts/services.dart';

class ContractsRepositoryImpl implements ContractsRepository {
  ContractsRepositoryImpl({required ContractsServices services}) : _services = services;

  final ContractsServices _services;

  String _workTypeToString(ContractWorkType type) {
    switch (type) {
      case ContractWorkType.road:
        return 'road';
      case ContractWorkType.sidewalk:
        return 'sidewalk';
      case ContractWorkType.yard:
        return 'yard';
    }
  }

  String? _statusToString(ContractStatus? status) {
    if (status == null) return null;
    switch (status) {
      case ContractStatus.planned:
        return 'PLANNED';
      case ContractStatus.active:
        return 'ACTIVE';
      case ContractStatus.expired:
        return 'EXPIRED';
      case ContractStatus.archived:
        return 'ARCHIVED';
    }
  }

  @override
  Future<List<Contract>> loadContracts({
    String? contractorId,
    ContractWorkType? workType,
    ContractStatus? status,
    bool? onlyActive,
    DateTime? startFrom,
    DateTime? startTo,
    DateTime? endFrom,
    DateTime? endTo,
  }) async {
    final dtos = await _services.collection.getContracts(
      contractorId: contractorId,
      workType: workType != null ? _workTypeToString(workType) : null,
      status: _statusToString(status),
      onlyActive: onlyActive,
      startFrom: startFrom,
      startTo: startTo,
      endFrom: endFrom,
      endTo: endTo,
    );
    return dtos.map((dto) => dto.toDomain()).toList();
  }

  @override
  Future<Contract> getContract(String id) async {
    final dto = await _services.collection.getContract(id);
    return dto.toDomain();
  }

  String _contractTypeToString(ContractType type) {
    switch (type) {
      case ContractType.contractorService:
        return 'CONTRACTOR_SERVICE';
      case ContractType.landfillService:
        return 'LANDFILL_SERVICE';
    }
  }

  @override
  Future<Contract> createContract({
    required ContractType contractType,
    String? contractorId,
    String? landfillId,
    required String name,
    ContractWorkType? workType,
    required double pricePerM3,
    double? budgetTotal,
    double? minimalVolumeM3,
    List<String>? polygonIds,
    double? vatRate,
    required DateTime startAt,
    required DateTime endAt,
    required bool isActive,
    String? createdByOrgId,
  }) async {
    final dto = await _services.collection.createContract(
      contractType: _contractTypeToString(contractType),
      contractorId: contractorId,
      landfillId: landfillId,
      name: name,
      workType: workType != null ? _workTypeToString(workType) : null,
      pricePerM3: pricePerM3,
      budgetTotal: budgetTotal,
      minimalVolumeM3: minimalVolumeM3,
      polygonIds: polygonIds,
      vatRate: vatRate,
      startAt: startAt,
      endAt: endAt,
      isActive: isActive,
      createdByOrgId: createdByOrgId,
    );
    return dto.toDomain();
  }

  @override
  Future<void> linkTicketToContract(String ticketId, String contractId) async {
    await _services.collection.linkTicketToContract(ticketId, contractId);
  }

  @override
  Future<void> recordTripUsage({
    required String tripId,
    required String ticketId,
    required double detectedVolumeM3,
  }) async {
    await _services.collection.recordTripUsage(
      tripId: tripId,
      ticketId: ticketId,
      detectedVolumeM3: detectedVolumeM3,
    );
  }
}

