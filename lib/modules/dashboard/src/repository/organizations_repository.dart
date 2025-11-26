import 'package:akimat_project/modules/dashboard/src/model/organizations/driver.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/organization.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/vehicle.dart';

abstract class OrganizationsRepository {
  Future<List<Organization>> loadOrganizations();

  Future<List<Driver>> loadDrivers();

  Future<List<Vehicle>> loadVehicles();

  /// Получить организацию по ID (для DRIVER роли)
  Future<Organization> getOrganization(String id);

  /// Получить водителя по ID (для DRIVER роли)
  Future<Driver> getDriver(String id);

  /// Получить транспорт по ID (для DRIVER роли)
  Future<Vehicle> getVehicle(String id);

  Future<Organization> createOrganization(Organization organization);

  Future<Organization> updateOrganization(Organization organization);

  Future<void> deleteOrganization(String organizationId);

  Future<Driver> createDriver(Driver driver);

  Future<Driver> updateDriver(Driver driver);

  Future<Vehicle> createVehicle(Vehicle vehicle);

  Future<Vehicle> updateVehicle(Vehicle vehicle);
}

