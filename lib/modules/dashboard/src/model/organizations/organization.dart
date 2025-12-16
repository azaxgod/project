import 'package:akimat_project/modules/dashboard/src/model/organizations/organization_type.dart';
import 'package:equatable/equatable.dart';

class Organization extends Equatable {
  final String id;
  final OrganizationType type;
  final String name;
  final String bin;
  final String? HeadFullName;
  final String? address;
  final String? phone;
  final String? parentOrgId;
  final bool isActive;

  const Organization({
    required this.id,
    required this.type,
    required this.name,
    required this.bin,
    this.HeadFullName,
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
    String? HeadFullName,
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
      HeadFullName: HeadFullName ?? this.HeadFullName,
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
        HeadFullName,
        address,
        phone,
        parentOrgId,
        isActive,
      ];
}
