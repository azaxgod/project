import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart'; 

@JsonSerializable()
class User {
  final String id;
  @JsonKey(name: 'organizationID', includeFromJson: true, includeToJson: false)
  final String? organizationId;
  final String? organization;
  final String role;
  final String? login; // Может быть null в /auth/me
  final String? phone;
  final bool? isNew;
  final bool? isActive;

  User({
    required this.id,
    this.organizationId,
    this.organization,
    required this.role,
    this.login, // Может быть null
    this.phone,
    this.isNew,
    this.isActive,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Поддержка разных вариантов: organizationID, organizationId, organization_id
    final orgId = json['organizationID'] as String? ?? 
                  json['organizationId'] as String? ?? 
                  json['organization_id'] as String?;
    return User(
      id: json['id'] as String,
      organizationId: orgId,
      organization: json['organization'] as String?,
      role: json['role'] as String,
      login: json['login'] as String?,
      phone: json['phone'] as String?,
      isNew: json['isNew'] as bool? ?? json['is_new'] as bool?,
      isActive: json['isActive'] as bool? ?? json['is_active'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => _$UserToJson(this);
}
