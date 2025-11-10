import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart'; 

@JsonSerializable()
class User {
  final String id;
  final String? organizationId;
  final String? organization;
  final String role;
  final String login;
  final String? phone;
  final bool? isNew;
  final bool? isActive;

  User({
    required this.id,
    this.organizationId,
    this.organization,
    required this.role,
    required this.login,
    this.phone,
    this.isNew,
    this.isActive,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);
}
