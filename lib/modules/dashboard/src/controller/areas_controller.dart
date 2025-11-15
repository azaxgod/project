import 'package:akimat_project/modules/dashboard/src/controller/areas_state.dart';
import 'package:akimat_project/modules/dashboard/src/model/areas/cleaning_area.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/organization.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/user_role.dart';
import 'package:akimat_project/modules/auth/src/controller/auth_notifier.dart';
import 'package:akimat_project/modules/dashboard/src/repository/organizations_repository.dart';
import 'package:akimat_project/modules/dashboard/src/repository/organizations_repository_impl.dart';
import 'package:akimat_project/services/organizations/module.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final areasControllerProvider = StateNotifierProvider<AreasController, AreasState>((ref) {
  final authState = ref.watch(authNotifierProvider);
  final role = userRoleFromString(authState.user?.role);
  final organizationId = authState.user?.organizationId;
  
  return AreasController(
    repository: OrganizationsRepositoryImpl(
      services: ref.watch(organizationsServicesProvider),
    ),
    initialState: AreasState.initial(
      role: role,
      organizationId: organizationId,
    ),
  );
});

class AreasController extends StateNotifier<AreasState> {
  AreasController({
    required OrganizationsRepository repository,
    required AreasState initialState,
  })  : _repository = repository,
        super(initialState) {
    _loadData();
  }

  final OrganizationsRepository _repository;

  Future<void> _loadData() async {
    state = state.copyWith(data: const AsyncLoading());
    state = state.copyWith(
      data: await AsyncValue.guard(() async {
        // Load contractors for filter
        final organizations = await _repository.loadOrganizations();
        final contractors = organizations
            .where((org) => org.type == OrganizationType.contractor)
            .toList();
        
        // TODO: Load areas from repository when implemented
        final areas = <CleaningArea>[];
        
        return AreasData(
          areas: areas,
          contractors: contractors,
        );
      }),
    );
  }

  Future<void> refresh() => _loadData();

  Future<void> createArea(CleaningArea area) async {
    final result = await AsyncValue.guard(() async {
      // TODO: Implement repository method
      return area;
    });
    
    if (!result.hasError) {
      await _loadData();
    }
  }

  Future<void> updateArea(CleaningArea area) async {
    final result = await AsyncValue.guard(() async {
      // TODO: Implement repository method
      return area;
    });
    
    if (!result.hasError) {
      await _loadData();
    }
  }

  void setStatusFilter(CleaningAreaStatus? status) {
    state = state.copyWith(statusFilter: status);
  }

  void setContractorFilter(String? contractorId) {
    state = state.copyWith(contractorFilter: contractorId);
  }

  void selectArea(CleaningArea? area) {
    state = state.copyWith(selectedArea: area);
  }
}

