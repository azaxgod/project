import 'package:akimat_project/modules/dashboard/src/model/organizations/organization.dart';

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
    return OrganizationDto(
      id: json['id'] as String,
      type: json['type'] as String,
      name: json['name'] as String,
      bin: json['bin'] as String,
      headFullName: json['headFullName'] as String?,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      parentOrgId: json['parentOrgId'] as String?,
      isActive: json['isActive'] as bool? ?? true,
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
        return 'TOO';
      case OrganizationType.contractor:
        return 'CONTRACTOR';
    }
  }
}

