import 'package:equatable/equatable.dart';

enum OrganizationType { akimat, too, contractor }

class Organization extends Equatable {
  final String id;
  final OrganizationType type;
  final String name;
  final String bin;
  final String? headFullName;
  final String? address;
  final String? phone;
  final String? parentOrgId;
  final bool isActive;

  const Organization({
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

  Organization copyWith({
    String? id,
    OrganizationType? type,
    String? name,
    String? bin,
    String? headFullName,
    String? address,
    String? phone,
    String? parentOrgId,
    bool? isActive,
  }) {
    return Organization(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      bin: bin ?? this.bin,
      headFullName: headFullName ?? this.headFullName,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      parentOrgId: parentOrgId ?? this.parentOrgId,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        name,
        bin,
        headFullName,
        address,
        phone,
        parentOrgId,
        isActive,
      ];
}

extension OrganizationTypeX on OrganizationType {
  String get label {
    switch (this) {
      case OrganizationType.akimat:
        return 'AKIMAT';
      case OrganizationType.too:
        return 'TOO';
      case OrganizationType.contractor:
        return 'CONTRACTOR';
    }
  }
}

