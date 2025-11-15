import 'dart:math';

import 'package:akimat_project/modules/dashboard/src/model/organizations/driver.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/organization.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/vehicle.dart';
import 'package:akimat_project/modules/dashboard/src/repository/organizations_repository.dart';
import 'package:akimat_project/services/organizations/model/driver_dto.dart';
import 'package:akimat_project/services/organizations/model/organization_dto.dart';
import 'package:akimat_project/services/organizations/model/vehicle_dto.dart';
import 'package:akimat_project/services/organizations/services.dart';

class OrganizationsRepositoryImpl implements OrganizationsRepository {
  OrganizationsRepositoryImpl({required OrganizationsServices services})
      : _services = services,
        _random = Random();

  final OrganizationsServices _services;
  final Random _random;

  @override
  Future<List<Organization>> loadOrganizations() async {
    // Используем реальный API roles-service
    final dtos = await _services.rolesCollection.getOrganizations();
    return dtos.map((dto) => dto.toDomain()).toList();
  }

  @override
  Future<List<Driver>> loadDrivers() async {
    // Используем реальный API roles-service
    final dtos = await _services.rolesCollection.getDrivers();
    return dtos.map((dto) => dto.toDomain()).toList();
  }

  @override
  Future<List<Vehicle>> loadVehicles() async {
    // Используем реальный API roles-service
    final dtos = await _services.rolesCollection.getVehicles(onlyActive: true);
    return dtos.map((dto) => dto.toDomain()).toList();
  }

  @override
  Future<Organization> createOrganization(Organization organization) async {
    // Для создания организации нужен телефон администратора
    // Используем phone организации как adminPhone, если он указан
    if (organization.phone == null || organization.phone!.isEmpty) {
      throw Exception('Телефон обязателен для создания организации');
    }
    
    final result = await _services.rolesCollection.createOrganization(
      name: organization.name,
      type: OrganizationDto.mapTypeToString(organization.type),
      bin: organization.bin,
      headFullName: organization.headFullName,
      address: organization.address,
      phone: organization.phone,
      parentOrgId: organization.parentOrgId, // Передаем parentOrgId для подрядчиков
      adminPhone: organization.phone!, // Телефон администратора = телефон организации
    );
    return result.organization.toDomain();
  }

  @override
  Future<Organization> updateOrganization(Organization organization) async {
    final dto = await _services.rolesCollection.updateOrganization(
      organization.id,
      name: organization.name,
      type: OrganizationDto.mapTypeToString(organization.type),
      bin: organization.bin,
      headFullName: organization.headFullName,
      address: organization.address,
      phone: organization.phone,
    );
    return dto.toDomain();
  }

  @override
  Future<void> deleteOrganization(String organizationId) {
    return _services.rolesCollection.deleteOrganization(organizationId);
  }

  @override
  Future<Driver> createDriver(Driver driver) async {
    final result = await _services.rolesCollection.createDriver(
      fullName: driver.fullName,
      iin: driver.iin,
      birthYear: driver.birthYear ?? DateTime.now().year - 30,
      phone: driver.phone,
    );
    return result.driver.toDomain();
  }

  @override
  Future<Driver> updateDriver(Driver driver) async {
    final dto = await _services.rolesCollection.updateDriver(
      driver.id,
      fullName: driver.fullName,
      phone: driver.phone,
      birthYear: driver.birthYear,
      iin: driver.iin,
    );
    return dto.toDomain();
  }

  @override
  Future<Vehicle> createVehicle(Vehicle vehicle) async {
    final dto = await _services.rolesCollection.createVehicle(
      plateNumber: vehicle.plateNumber,
      brand: vehicle.brand,
      model: vehicle.model,
      color: vehicle.color,
      year: vehicle.year,
      bodyVolumeM3: vehicle.bodyVolumeM3,
      photoUrl: vehicle.photoUrl,
      driverId: vehicle.driverId,
    );
    return dto.toDomain();
  }

  @override
  Future<Vehicle> updateVehicle(Vehicle vehicle) async {
    final dto = await _services.rolesCollection.updateVehicle(
      vehicle.id,
      color: vehicle.color,
      bodyVolumeM3: vehicle.bodyVolumeM3,
      driverId: vehicle.driverId ?? '', // Пустая строка для отвязки, если null
    );
    return dto.toDomain();
  }

  OrganizationDto _organizationToDto(Organization organization, {bool ensureId = false}) {
    return OrganizationDto(
      id: ensureId ? _ensureId(organization.id) : organization.id,
      type: OrganizationDto.mapTypeToString(organization.type),
      name: organization.name,
      bin: organization.bin,
      headFullName: organization.headFullName,
      address: organization.address,
      phone: organization.phone,
      parentOrgId: organization.parentOrgId,
      isActive: organization.isActive,
    );
  }

  DriverDto _driverToDto(Driver driver, {bool ensureId = false}) {
    return DriverDto(
      id: ensureId ? _ensureId(driver.id) : driver.id,
      contractorId: driver.contractorId,
      fullName: driver.fullName,
      iin: driver.iin,
      birthYear: driver.birthYear,
      phone: driver.phone,
      isActive: driver.isActive,
    );
  }

  VehicleDto _vehicleToDto(Vehicle vehicle, {bool ensureId = false}) {
    return VehicleDto(
      id: ensureId ? _ensureId(vehicle.id) : vehicle.id,
      contractorId: vehicle.contractorId,
      driverId: vehicle.driverId,
      plateNumber: vehicle.plateNumber,
      brand: vehicle.brand,
      model: vehicle.model,
      color: vehicle.color,
      year: vehicle.year,
      bodyVolumeM3: vehicle.bodyVolumeM3,
      photoUrl: vehicle.photoUrl,
      isActive: vehicle.isActive,
    );
  }

  String _ensureId(String source) {
    if (source.isNotEmpty) return source;
    return '${DateTime.now().microsecondsSinceEpoch}_${_random.nextInt(9999)}';
  }
}

