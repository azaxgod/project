import 'package:akimat_project/modules/auth/src/controller/auth_notifier.dart';
import 'package:akimat_project/modules/dashboard/src/controller/organizations_state.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/driver.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/organization.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/user_role.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/vehicle.dart';
import 'package:akimat_project/modules/dashboard/src/repository/organizations_repository.dart';
import 'package:akimat_project/modules/dashboard/src/repository/organizations_repository_impl.dart';
import 'package:akimat_project/services/organizations/module.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OrganizationsController extends StateNotifier<OrganizationsState> {
  OrganizationsController({
    required OrganizationsRepository repository,
    required OrganizationsState initialState,
  })  : _repository = repository,
        super(initialState) {
    _loadData();
  }

  final OrganizationsRepository _repository;

  Future<void> _loadData() async {
    state = state.copyWith(data: const AsyncLoading());
    state = state.copyWith(
      data: await AsyncValue.guard(() async {
        final organizations = await _repository.loadOrganizations();
        final drivers = await _repository.loadDrivers();
        final vehicles = await _repository.loadVehicles();
        return OrganizationsData(
          organizations: organizations,
          drivers: drivers,
          vehicles: vehicles,
        );
      }),
    );
  }

  Future<void> refresh() => _loadData();

  Future<void> createOrganization(Organization organization) async {
    final result = await AsyncValue.guard(
      () => _repository.createOrganization(organization),
    );
    state = state.copyWith(
      lastAction: result.whenData((_) => null),
      message: result.hasError ? 'Ошибка при создании организации' : 'Организация создана',
    );
    await _loadData();
  }

  Future<void> updateOrganization(Organization organization) async {
    final result = await AsyncValue.guard(
      () => _repository.updateOrganization(organization),
    );
    state = state.copyWith(
      lastAction: result.whenData((_) => null),
      message: result.hasError ? 'Ошибка при обновлении организации' : 'Изменения сохранены',
    );
    await _loadData();
  }

  Future<void> createDriver(Driver driver) async {
    final result = await AsyncValue.guard(() => _repository.createDriver(driver));
    state = state.copyWith(
      lastAction: result.whenData((_) => null),
      message: result.hasError ? 'Ошибка при создании водителя' : 'Водитель создан',
    );
    await _loadData();
  }

  Future<void> updateDriver(Driver driver) async {
    final result = await AsyncValue.guard(() => _repository.updateDriver(driver));
    state = state.copyWith(
      lastAction: result.whenData((_) => null),
      message: result.hasError ? 'Ошибка при обновлении водителя' : 'Данные водителя обновлены',
    );
    await _loadData();
  }

  Future<void> createVehicle(Vehicle vehicle) async {
    final result = await AsyncValue.guard(() => _repository.createVehicle(vehicle));
    state = state.copyWith(
      lastAction: result.whenData((_) => null),
      message: result.hasError ? 'Ошибка при создании транспорта' : 'Транспорт добавлен',
    );
    await _loadData();
  }

  Future<void> updateVehicle(Vehicle vehicle) async {
    final result = await AsyncValue.guard(() => _repository.updateVehicle(vehicle));
    state = state.copyWith(
      lastAction: result.whenData((_) => null),
      message: result.hasError ? 'Ошибка при обновлении транспорта' : 'Транспорт обновлён',
    );
    await _loadData();
  }
}

final organizationsRepositoryProvider = Provider<OrganizationsRepository>((ref) {
  final services = ref.watch(organizationsServicesProvider);
  return OrganizationsRepositoryImpl(services: services);
});

final organizationsControllerProvider =
    StateNotifierProvider<OrganizationsController, OrganizationsState>((ref) {
  final authState = ref.watch(authNotifierProvider);
  final repository = ref.watch(organizationsRepositoryProvider);
  final role = userRoleFromString(authState.user?.role);
  final organizationId = authState.user?.organizationId;
  return OrganizationsController(
    repository: repository,
    initialState: OrganizationsState.initial(role: role, organizationId: organizationId),
  );
});

