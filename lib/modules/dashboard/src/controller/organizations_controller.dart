import 'package:akimat_project/modules/auth/src/controller/auth_notifier.dart';
import 'package:akimat_project/modules/dashboard/src/controller/organizations_state.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/driver.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/organization.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/user_role.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/vehicle.dart';
import 'package:akimat_project/modules/dashboard/src/repository/organizations_repository.dart';
import 'package:akimat_project/modules/dashboard/src/repository/organizations_repository_impl.dart';
import 'package:akimat_project/services/organizations/module.dart';
import 'package:flutter/foundation.dart';
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
        
        // Debug logging
        debugPrint('OrganizationsController._loadData:');
        debugPrint('  - Loaded ${organizations.length} organizations');
        debugPrint('  - Loaded ${drivers.length} drivers');
        debugPrint('  - Loaded ${vehicles.length} vehicles');
        debugPrint('  - Current role: ${state.role}');
        debugPrint('  - Current organizationId: ${state.organizationId}');
        if (vehicles.isNotEmpty) {
          debugPrint('  - First vehicle contractorId: ${vehicles.first.contractorId}');
          debugPrint('  - Vehicles contractorIds: ${vehicles.map((v) => v.contractorId).toSet().join(", ")}');
        }
        
        return OrganizationsData(
          organizations: organizations,
          drivers: drivers,
          vehicles: vehicles,
        );
      }),
    );
  }

  /// Обновить данные с принудительной перезагрузкой
  Future<void> refresh() async {
    // Принудительно обновляем состояние, чтобы UI увидел изменения
    debugPrint('OrganizationsController.refresh: Starting refresh...');
    state = state.copyWith(data: const AsyncLoading());
    // Даем время на обновление UI перед загрузкой данных
    await Future.delayed(const Duration(milliseconds: 100));
    await _loadData();
    debugPrint('OrganizationsController.refresh: Data loaded, state updated');
    // Дополнительно даем время на обновление после загрузки
    await Future.delayed(const Duration(milliseconds: 150));
  }

  Future<void> createOrganization(Organization organization, {bool skipReload = false}) async {
    final result = await AsyncValue.guard(
      () => _repository.createOrganization(organization),
    );
    state = state.copyWith(
      lastAction: result.whenData((_) => null),
      message: result.hasError ? 'Ошибка при создании организации' : 'Организация создана',
    );
    if (!skipReload) {
      await _loadData();
    }
    if (result.hasError) {
      throw result.error!;
    }
  }

  Future<void> updateOrganization(Organization organization, {bool skipReload = false}) async {
    final result = await AsyncValue.guard(
      () => _repository.updateOrganization(organization),
    );
    state = state.copyWith(
      lastAction: result.whenData((_) => null),
      message: result.hasError ? 'Ошибка при обновлении организации' : 'Изменения сохранены',
    );
    if (!skipReload) {
      await _loadData();
    }
    if (result.hasError) {
      throw result.error!;
    }
  }

  Future<void> createDriver(Driver driver, {bool skipReload = false}) async {
    final result = await AsyncValue.guard(() => _repository.createDriver(driver));
    state = state.copyWith(
      lastAction: result.whenData((_) => null),
      message: result.hasError ? 'Ошибка при создании водителя' : 'Водитель создан',
    );
    if (!skipReload) {
      await _loadData();
    }
    if (result.hasError) {
      throw result.error!;
    }
  }

  Future<void> updateDriver(Driver driver, {bool skipReload = false}) async {
    final result = await AsyncValue.guard(() => _repository.updateDriver(driver));
    state = state.copyWith(
      lastAction: result.whenData((_) => null),
      message: result.hasError ? 'Ошибка при обновлении водителя' : 'Данные водителя обновлены',
    );
    if (!skipReload) {
      await _loadData();
    }
    if (result.hasError) {
      throw result.error!;
    }
  }

  Future<void> createVehicle(Vehicle vehicle, {bool skipReload = false}) async {
    final result = await AsyncValue.guard(() => _repository.createVehicle(vehicle));
    state = state.copyWith(
      lastAction: result.whenData((_) => null),
      message: result.hasError ? 'Ошибка при создании транспорта' : 'Транспорт добавлен',
    );
    if (!skipReload) {
      await _loadData();
    }
    if (result.hasError) {
      throw result.error!;
    }
  }

  Future<void> updateVehicle(Vehicle vehicle, {bool skipReload = false}) async {
    final result = await AsyncValue.guard(() => _repository.updateVehicle(vehicle));
    state = state.copyWith(
      lastAction: result.whenData((_) => null),
      message: result.hasError ? 'Ошибка при обновлении транспорта' : 'Транспорт обновлён',
    );
    if (!skipReload) {
      await _loadData();
    }
    if (result.hasError) {
      throw result.error!;
    }
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

