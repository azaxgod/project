import 'package:json_annotation/json_annotation.dart';

part 'user_dto.g.dart';

@JsonSerializable()
class UserDto {
  final String id;
  final String phone;
  final String role;
  final String? login;
  @JsonKey(name: 'organizationID')
  final String? organizationId;
  @JsonKey(name: 'driverID')
  final String? driverId;
  @JsonKey(name: 'isActive')
  final bool isActive;
  @JsonKey(name: 'blockReason')
  final String? blockReason;
  @JsonKey(name: 'generatedPassword')
  final String? generatedPassword;
  @JsonKey(name: 'createdAt')
  final DateTime? createdAt;
  @JsonKey(name: 'updatedAt')
  final DateTime? updatedAt;

  UserDto({
    required this.id,
    required this.phone,
    required this.role,
    this.login,
    this.organizationId,
    this.driverId,
    required this.isActive,
    this.blockReason,
    this.generatedPassword,
    this.createdAt,
    this.updatedAt,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) =>
      _$UserDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UserDtoToJson(this);
}

