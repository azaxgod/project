import 'package:akimat_project/modules/dashboard/src/model/organizations/organization.dart';
import 'package:akimat_project/modules/dashboard/src/model/organizations/organization_type.dart';

class OrganizationDto {
  OrganizationDto({
    required this.id,
    required this.type,
    required this.name,
    required this.bin,
    this.headFullName,
    this.address,
    this.phone,
    this.parentOrgId,
    required this.isActive,
  });

  final String id;
  final String type;
  final String name;
  final String bin;
  final String? headFullName;
  final String? address;
  final String? phone;
  final String? parentOrgId;
  final bool isActive;

  factory OrganizationDto.fromJson(Map<String, dynamic> json) {
    // Поддержка разных форматов: Type, type
    final typeValue = json['Type'] as String? ?? 
                     json['type'] as String? ?? 
                     'CONTRACTOR';
    // Нормализуем тип: KGU_ZKH должен быть с подчеркиванием
    final normalizedType = typeValue.toUpperCase().replaceAll(' ', '_');
    
    return OrganizationDto(
      id: json['ID'] as String? ?? json['id'] as String? ?? '',
      type: normalizedType,
      name: json['Name'] as String? ?? json['name'] as String? ?? '',
      bin: json['BIN'] as String? ?? json['bin'] as String? ?? '',
      headFullName: json['HeadFullName'] as String? ?? json['headFullName'] as String?,
      address: json['Address'] as String? ?? json['address'] as String?,
      phone: json['Phone'] as String? ?? json['phone'] as String?,
      parentOrgId: json['ParentOrgID'] as String? ?? 
                   json['parentOrgID'] as String? ?? 
                   json['parentOrgId'] as String?,
      isActive: json['IsActive'] as bool? ?? json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'name': name,
        'bin': bin,
        'headFullName': headFullName,
        'address': address,
        'phone': phone,
        'parentOrgId': parentOrgId,
        'isActive': isActive,
      };

  Organization toDomain() {
    return Organization(
      id: id,
      type: _mapType(type),
      name: name,
      bin: bin,
      headFullName: headFullName,
      address: address,
      phone: phone,
      parentOrgId: parentOrgId,
      isActive: isActive,
    );
  }

  static OrganizationType _mapType(String value) {
    switch (value) {
      case 'AKIMAT':
        return OrganizationType.akimat;
      case 'KGU_ZKH':
        return OrganizationType.kguZkh;
      case 'TOO':
      case 'LANDFILL': // Поддержка нового значения с сервера
        return OrganizationType.too;
      case 'CONTRACTOR':
        return OrganizationType.contractor;
      default:
        return OrganizationType.contractor;
    }
  }

  static String mapTypeToString(OrganizationType type) {
    switch (type) {
      case OrganizationType.akimat:
        return 'AKIMAT';
      case OrganizationType.kguZkh:
        return 'KGU_ZKH';
      case OrganizationType.too:
        return 'LANDFILL'; // Сервер работает с LANDFILL
      case OrganizationType.contractor:
        return 'CONTRACTOR';
    }
  }
}

