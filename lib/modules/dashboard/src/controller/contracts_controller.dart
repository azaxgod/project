import 'package:akimat_project/modules/auth/src/controller/auth_notifier.dart';
import 'package:akimat_project/modules/dashboard/src/controller/contracts_state.dart';
import 'package:akimat_project/modules/dashboard/src/model/contracts/contract.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/organization.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/organization_type.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/user_role.dart';
import 'package:akimat_project/modules/dashboard/src/repository/contracts_repository.dart';
import 'package:akimat_project/modules/dashboard/src/repository/contracts_repository_impl.dart';
import 'package:akimat_project/modules/dashboard/src/controller/organizations_controller.dart';
import 'package:akimat_project/modules/dashboard/src/repository/organizations_repository.dart';
import 'package:akimat_project/services/contracts/module.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ContractsController extends StateNotifier<ContractsState> {
  ContractsController({
    required ContractsRepository contractsRepository,
    required OrganizationsRepository organizationsRepository,
    required ContractsState initialState,
  })  : _contractsRepository = contractsRepository,
        _organizationsRepository = organizationsRepository,
        super(initialState) {
    _loadData();
  }

  final ContractsRepository _contractsRepository;
  final OrganizationsRepository _organizationsRepository;

  Future<void> _loadData() async {
    state = state.copyWith(data: const AsyncLoading());
    
    try {
      // Загружаем контракты с фильтрами
      final contracts = await _contractsRepository.loadContracts(
        contractorId: state.contractorFilter,
        status: state.statusFilter,
        startFrom: state.periodStart,
        startTo: state.periodEnd,
      );

      // Загружаем подрядчиков для фильтра
      final allOrganizations = await _organizationsRepository.loadOrganizations();
      final contractors = allOrganizations
          .where((org) => org.type == OrganizationType.contractor && org.isActive)
          .toList();

      // Фильтруем контракты по роли
      List<Contract> filteredContracts = contracts;
      if (state.role == UserRole.contractorAdmin && state.organizationId != null) {
        filteredContracts = contracts
            .where((c) => c.contractorId == state.organizationId)
            .toList();
      }

      state = state.copyWith(
        data: AsyncData(
          ContractsData(
            contracts: filteredContracts,
            contractors: contractors,
          ),
        ),
      );
    } catch (e, stack) {
      state = state.copyWith(data: AsyncError(e, stack));
    }
  }

  Future<void> refresh() => _loadData();

  void setContractorFilter(String? contractorId) {
    state = state.copyWith(contractorFilter: contractorId);
    _loadData();
  }

  void setStatusFilter(ContractStatus? status) {
    state = state.copyWith(statusFilter: status);
    _loadData();
  }

  void setPeriodFilter(DateTime? start, DateTime? end) {
    state = state.copyWith(periodStart: start, periodEnd: end);
    _loadData();
  }

  Future<void> createContract({
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
  }) async {
    try {
      await _contractsRepository.createContract(
        contractorId: contractorId,
        name: name,
        workType: workType,
        pricePerM3: pricePerM3,
        budgetTotal: budgetTotal,
        minimalVolumeM3: minimalVolumeM3,
        startAt: startAt,
        endAt: endAt,
        isActive: isActive,
        createdByOrgId: createdByOrgId ?? state.organizationId, // Используем organizationId из state или переданный
      );
      await _loadData();
    } catch (e) {
      rethrow;
    }
  }
}

final contractsRepositoryProvider = Provider<ContractsRepository>((ref) {
  return ContractsRepositoryImpl(services: ref.watch(contractsServicesProvider));
});

final contractsControllerProvider =
    StateNotifierProvider<ContractsController, ContractsState>((ref) {
  final authState = ref.watch(authNotifierProvider);
  final contractsRepository = ref.watch(contractsRepositoryProvider);
  final organizationsRepository = ref.watch(organizationsRepositoryProvider);
  final role = userRoleFromString(authState.user?.role);
  final organizationId = authState.user?.organizationId;
  return ContractsController(
    contractsRepository: contractsRepository,
    organizationsRepository: organizationsRepository,
    initialState: ContractsState.initial(role: role, organizationId: organizationId),
  );
});

