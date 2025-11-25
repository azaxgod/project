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
  @JsonKey(name: 'isActive', defaultValue: true)
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

  factory UserDto.fromJson(Map<String, dynamic> json) {
    // Обработка null значений с значениями по умолчанию
    // Сначала проверяем обязательные поля
    final id = json['id']?.toString();
    final phone = json['phone']?.toString();
    final role = json['role']?.toString();
    final isActiveValue = json['isActive'] ?? json['is_active'];
    
    // Если какие-то обязательные поля отсутствуют, используем безопасный метод создания
    if (id == null || phone == null || role == null) {
      return UserDto(
        id: id ?? '',
        phone: phone ?? '',
        role: role ?? 'AKIMAT_USER',
        login: json['login']?.toString(),
        organizationId: json['organizationID']?.toString() ?? json['organizationId']?.toString(),
        driverId: json['driverID']?.toString() ?? json['driverId']?.toString(),
        isActive: _parseBool(isActiveValue) ?? true,
        blockReason: json['blockReason']?.toString() ?? json['block_reason']?.toString(),
        generatedPassword: json['generatedPassword']?.toString() ?? json['generated_password']?.toString(),
        createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
        updatedAt: _parseDateTime(json['updatedAt'] ?? json['updated_at']),
      );
    }
    
    // Если все обязательные поля присутствуют, пытаемся использовать сгенерированный метод
    try {
      return _$UserDtoFromJson(json);
    } catch (e) {
      // Fallback: создаем UserDto с безопасной обработкой null значений
      return UserDto(
        id: id,
        phone: phone,
        role: role,
        login: json['login']?.toString(),
        organizationId: json['organizationID']?.toString() ?? json['organizationId']?.toString(),
        driverId: json['driverID']?.toString() ?? json['driverId']?.toString(),
        isActive: _parseBool(isActiveValue) ?? true,
        blockReason: json['blockReason']?.toString() ?? json['block_reason']?.toString(),
        generatedPassword: json['generatedPassword']?.toString() ?? json['generated_password']?.toString(),
        createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
        updatedAt: _parseDateTime(json['updatedAt'] ?? json['updated_at']),
      );
    }
  }
  
  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    return null;
  }
  
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  Map<String, dynamic> toJson() => _$UserDtoToJson(this);
}

