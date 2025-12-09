import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:akimat_project/modules/dashboard/src/model/organizations/driver.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/organization.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/vehicle.dart';
import 'package:akimat_project/modules/dashboard/src/repository/organizations_repository.dart';
import 'package:akimat_project/services/organizations/model/driver_dto.dart';
import 'package:akimat_project/services/organizations/model/organization_dto.dart';
import 'package:akimat_project/services/organizations/model/vehicle_dto.dart';
import 'package:akimat_project/services/organizations/services.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

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
  Future<Driver> getDriver(String id) async {
    // Используем реальный API roles-service для получения конкретного водителя
    final dto = await _services.rolesCollection.getDriver(id);
    return dto.toDomain();
  }

  @override
  Future<Organization> getOrganization(String id) async {
    // Используем реальный API roles-service для получения конкретной организации
    final dto = await _services.rolesCollection.getOrganization(id);
    return dto.toDomain();
  }

  @override
  Future<Vehicle> getVehicle(String id) async {
    // Используем реальный API roles-service для получения конкретного транспорта
    final dto = await _services.rolesCollection.getVehicle(id);
    return dto.toDomain();
  }

  @override
  Future<Organization> createOrganization(Organization organization) async {
    // Для создания организации нужен телефон администратора
    // Используем phone организации как adminPhone, если он указан
    if (organization.phone == null || organization.phone!.isEmpty) {
      throw Exception('Телефон обязателен для создания организации');
    }
    
    // Отладочный вывод
    debugPrint('=== REPOSITORY ===');
    debugPrint('organization.headFullName: "${organization.headFullName}"');
    debugPrint('organization.address: "${organization.address}"');
    
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
      isActive: organization.isActive,
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
    // Извлекаем bytes и filename из photoUrl если это временные данные
    Uint8List? photoBytes;
    String? photoFileName;
    String? existingPhotoUrl; // Сохраняем существующий URL фото
    bool shouldDeletePhoto = false;
    bool keepExistingPhoto = false; // Флаг для сохранения существующего фото
    
    // Если photoUrl = null, это означает что нужно удалить фото (использовать дефолтную иконку)
    if (vehicle.photoUrl == null) {
      shouldDeletePhoto = true;
    }
    // Если photoUrl содержит временные данные (data URL), извлекаем bytes
    else if (vehicle.photoUrl!.startsWith('data:image/')) {
      try {
        final dataUrl = vehicle.photoUrl!;
        final parts = dataUrl.split(',');
        if (parts.length < 2) {
          throw Exception('Invalid data URL format');
        }
        
        final base64String = parts[1];
        if (base64String.isEmpty) {
          throw Exception('Base64 string is empty');
        }
        
        photoBytes = base64Decode(base64String);
        
        // Проверяем, что декодированные данные не пусты и имеют минимальный размер
        if (photoBytes.isEmpty || photoBytes.length < 100) {
          throw Exception('Decoded photo bytes are empty or too small');
        }
        
        // Проверяем, что это действительно изображение (magic bytes)
        final isValidImage = (photoBytes.length >= 4 && 
          ((photoBytes[0] == 0xFF && photoBytes[1] == 0xD8) || // JPEG
           (photoBytes[0] == 0x89 && photoBytes[1] == 0x50 && photoBytes[2] == 0x4E && photoBytes[3] == 0x47) || // PNG
           (photoBytes[0] == 0x47 && photoBytes[1] == 0x49 && photoBytes[2] == 0x46) || // GIF
           (photoBytes[0] == 0x52 && photoBytes[1] == 0x49 && photoBytes[2] == 0x46 && photoBytes[8] == 0x57 && photoBytes[9] == 0x45 && photoBytes[10] == 0x42 && photoBytes[11] == 0x50))); // WEBP
        
        if (!isValidImage) {
          throw Exception('Invalid image format');
        }
        
        // Определяем расширение из MIME типа
        final mimeType = dataUrl.split(';')[0].split(':')[1];
        String extension = 'png';
        if (mimeType.contains('jpeg') || mimeType.contains('jpg')) {
          extension = 'jpg';
        } else if (mimeType.contains('png')) {
          extension = 'png';
        } else if (mimeType.contains('webp')) {
          extension = 'webp';
        } else if (mimeType.contains('gif')) {
          extension = 'gif';
        }
        photoFileName = 'photo.$extension';
      } catch (e) {
        debugPrint('Error processing photo data URL: $e');
        // Если не удалось декодировать, считаем что это обычный URL
        // Сохраняем существующее фото, не передавая новое
        keepExistingPhoto = true;
        photoBytes = null;
        photoFileName = null;
      }
    }
    // Если photoUrl это обычный URL (существующее фото), загружаем его с сервера
    // чтобы отправить обратно (сервер требует файл в поле photo)
    else if (vehicle.photoUrl!.isNotEmpty && !vehicle.photoUrl!.startsWith('data:image/')) {
      keepExistingPhoto = true;
      existingPhotoUrl = vehicle.photoUrl; // Сохраняем существующий URL
      
      // Загружаем существующее фото с сервера, чтобы отправить его обратно
      try {
        final dio = Dio();
        final response = await dio.get<Uint8List>(
          vehicle.photoUrl!,
          options: Options(responseType: ResponseType.bytes),
        );
        
        if (response.data != null && response.data!.isNotEmpty) {
          photoBytes = response.data;
          
          // Определяем расширение из URL
          String extension = 'png';
          final urlPath = vehicle.photoUrl!.toLowerCase();
          if (urlPath.contains('.jpg') || urlPath.contains('.jpeg')) {
            extension = 'jpg';
          } else if (urlPath.contains('.png')) {
            extension = 'png';
          } else if (urlPath.contains('.webp')) {
            extension = 'webp';
          } else if (urlPath.contains('.gif')) {
            extension = 'gif';
          }
          photoFileName = 'photo.$extension';
        }
      } catch (e) {
        debugPrint('Error downloading existing photo: $e');
        // Если не удалось загрузить, продолжаем без фото
        // Сервер может принять запрос без фото или вернуть ошибку
      }
    }
    
    final dto = await _services.rolesCollection.updateVehicle(
      vehicle.id,
      plateNumber: vehicle.plateNumber,
      brand: vehicle.brand,
      model: vehicle.model,
      color: vehicle.color,
      year: vehicle.year,
      bodyVolumeM3: vehicle.bodyVolumeM3,
      photoBytes: photoBytes,
      photoFileName: photoFileName,
      existingPhotoUrl: existingPhotoUrl,
      shouldDeletePhoto: shouldDeletePhoto,
      keepExistingPhoto: keepExistingPhoto,
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

