import 'package:akimat_project/modules/dashboard/src/model/organizations/driver.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/organization.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/vehicle.dart';

abstract class OrganizationsRepository {
  Future<List<Organization>> loadOrganizations();

  Future<List<Driver>> loadDrivers();

  Future<List<Vehicle>> loadVehicles();

  Future<Organization> createOrganization(Organization organization);

  Future<Organization> updateOrganization(Organization organization);

  Future<void> deleteOrganization(String organizationId);

  Future<Driver> createDriver(Driver driver);

  Future<Driver> updateDriver(Driver driver);

  Future<Vehicle> createVehicle(Vehicle vehicle);

  Future<Vehicle> updateVehicle(Vehicle vehicle);
}

