// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserDto _$UserDtoFromJson(Map<String, dynamic> json) => UserDto(
      id: json['id'] as String,
      phone: json['phone'] as String,
      role: json['role'] as String,
      login: json['login'] as String?,
      organizationId: json['organizationID'] as String?,
      driverId: json['driverID'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      blockReason: json['blockReason'] as String?,
      generatedPassword: json['generatedPassword'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$UserDtoToJson(UserDto instance) => <String, dynamic>{
      'id': instance.id,
      'phone': instance.phone,
      'role': instance.role,
      'login': instance.login,
      'organizationID': instance.organizationId,
      'driverID': instance.driverId,
      'isActive': instance.isActive,
      'blockReason': instance.blockReason,
      'generatedPassword': instance.generatedPassword,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
