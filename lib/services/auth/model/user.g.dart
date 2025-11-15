// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
      id: json['id'] as String,
      organizationId: json['organizationID'] as String?,
      organization: json['organization'] as String?,
      role: json['role'] as String,
      login: json['login'] as String?,
      phone: json['phone'] as String?,
      isNew: json['isNew'] as bool?,
      isActive: json['isActive'] as bool?,
    );

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'id': instance.id,
      'organization': instance.organization,
      'role': instance.role,
      'login': instance.login,
      'phone': instance.phone,
      'isNew': instance.isNew,
      'isActive': instance.isActive,
    };
