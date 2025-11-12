import 'package:akimat_project/modules/dashboard/src/model/organizations/organization.dart';
import 'package:akimat_project/services/organizations/model/driver_dto.dart';
import 'package:akimat_project/services/organizations/model/organization_dto.dart';
import 'package:akimat_project/services/organizations/model/vehicle_dto.dart';

/// Temporary in-memory data source emulating remote API responses.
class OrganizationsCollection {
  OrganizationsCollection() {
    _seed();
  }

  final List<OrganizationDto> _organizations = [];
  final List<DriverDto> _drivers = [];
  final List<VehicleDto> _vehicles = [];

  Future<List<OrganizationDto>> fetchOrganizations() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return List.unmodifiable(_organizations);
  }

  Future<List<DriverDto>> fetchDrivers() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return List.unmodifiable(_drivers);
  }

  Future<List<VehicleDto>> fetchVehicles() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return List.unmodifiable(_vehicles);
  }

  Future<OrganizationDto> createOrganization(OrganizationDto dto) async {
    _organizations.add(dto);
    return dto;
  }

  Future<OrganizationDto> updateOrganization(OrganizationDto dto) async {
    final index = _organizations.indexWhere((item) => item.id == dto.id);
    if (index != -1) {
      _organizations[index] = dto;
    }
    return dto;
  }

  Future<void> deleteOrganization(String id) async {
    _organizations.removeWhere((element) => element.id == id);
  }

  Future<DriverDto> createDriver(DriverDto dto) async {
    _drivers.add(dto);
    return dto;
  }

  Future<DriverDto> updateDriver(DriverDto dto) async {
    final index = _drivers.indexWhere((item) => item.id == dto.id);
    if (index != -1) {
      _drivers[index] = dto;
    }
    return dto;
  }

  Future<VehicleDto> createVehicle(VehicleDto dto) async {
    _vehicles.add(dto);
    return dto;
  }

  Future<VehicleDto> updateVehicle(VehicleDto dto) async {
    final index = _vehicles.indexWhere((item) => item.id == dto.id);
    if (index != -1) {
      _vehicles[index] = dto;
    }
    return dto;
  }

  void _seed() {
    const akimatId = 'org_akimat';
    const tooId = 'org_too_1';
    const contractor1 = 'org_contractor_1';
    const contractor2 = 'org_contractor_2';

    _organizations
      ..addAll([
        OrganizationDto(
          id: akimatId,
          type: OrganizationDto.mapTypeToString(OrganizationType.akimat),
          name: 'Акимат г. Алматы',
          bin: '900900900900',
          headFullName: 'Аким города',
          address: 'пр. Достык, 1',
          phone: '+7 727 000 00 00',
          parentOrgId: null,
          isActive: true,
        ),
        OrganizationDto(
          id: tooId,
          type: OrganizationDto.mapTypeToString(OrganizationType.too),
          name: 'ТОО «SnowTech»',
          bin: '123456789012',
          headFullName: 'Иванов Сергей',
          address: 'ул. Назарбаева, 10',
          phone: '+7 701 111 22 33',
          parentOrgId: akimatId,
          isActive: true,
        ),
        OrganizationDto(
          id: contractor1,
          type: OrganizationDto.mapTypeToString(OrganizationType.contractor),
          name: 'Транспорт-Сервис',
          bin: '770155550011',
          headFullName: 'Петров Андрей',
          address: 'ул. Гагарина, 5',
          phone: '+7 701 444 55 66',
          parentOrgId: tooId,
          isActive: true,
        ),
        OrganizationDto(
          id: contractor2,
          type: OrganizationDto.mapTypeToString(OrganizationType.contractor),
          name: 'Shine Roads',
          bin: '770155550022',
          headFullName: 'Садыкова Алия',
          address: 'ул. Абая, 120',
          phone: '+7 777 888 99 00',
          parentOrgId: tooId,
          isActive: true,
        ),
      ]);

    _drivers
      ..addAll([
        DriverDto(
          id: 'driver_1',
          contractorId: contractor1,
          fullName: 'Нурлан Сеитов',
          iin: '900101350123',
          birthYear: 1990,
          phone: '+7 707 100 20 30',
          isActive: true,
        ),
        DriverDto(
          id: 'driver_2',
          contractorId: contractor2,
          fullName: 'Алексей Зуев',
          iin: '880505450987',
          birthYear: 1988,
          phone: '+7 705 555 66 77',
          isActive: true,
        ),
      ]);

    _vehicles
      ..addAll([
        VehicleDto(
          id: 'vehicle_1',
          contractorId: contractor1,
          driverId: null,
          plateNumber: '123 ABC 02',
          brand: 'KamAZ',
          model: '6520',
          color: 'Оранжевый',
          year: 2022,
          bodyVolumeM3: 12.0,
          photoUrl: 'https://example.com/kamaz6520.jpg',
          isActive: true,
        ),
        VehicleDto(
          id: 'vehicle_2',
          contractorId: contractor2,
          driverId: 'driver_2',
          plateNumber: '789 XYZ 02',
          brand: 'MAN',
          model: 'TGS',
          color: 'Серый',
          year: 2021,
          bodyVolumeM3: 10.5,
          photoUrl: 'https://example.com/man_tgs.jpg',
          isActive: true,
        ),
      ]);
  }
}

