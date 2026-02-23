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
    // API возвращает поля с заглавными буквами: Phone, Login, BlockReason, IsActive, ID
    // Поддерживаем оба формата: capitalized и snake_case
    final id = json['ID']?.toString() ?? json['id']?.toString();
    final phone = json['Phone']?.toString() ?? json['phone']?.toString();
    final role = json['Role']?.toString() ?? json['role']?.toString();
    final isActiveValue = json['IsActive'] ?? json['isActive'] ?? json['is_active'];
    
    // Если какие-то обязательные поля отсутствуют, используем безопасный метод создания
    if (id == null || id.isEmpty || phone == null || phone.isEmpty || role == null || role.isEmpty) {
      // Логируем проблему для отладки
      print('Warning: UserDto missing required fields. ID: $id, Phone: $phone, Role: $role');
      return UserDto(
        id: id ?? '',
        phone: phone ?? '',
        role: role ?? 'AKIMAT_USER',
        login: json['Login']?.toString() ?? json['login']?.toString(),
        organizationId: json['OrganizationID']?.toString() ?? json['organizationID']?.toString() ?? json['organizationId']?.toString(),
        driverId: json['DriverID']?.toString() ?? json['driverID']?.toString() ?? json['driverId']?.toString(),
        isActive: _parseBool(isActiveValue) ?? true,
        blockReason: json['BlockReason']?.toString() ?? json['blockReason']?.toString() ?? json['block_reason']?.toString(),
        generatedPassword: json['GeneratedPassword']?.toString() ?? json['generatedPassword']?.toString() ?? json['generated_password']?.toString(),
        createdAt: _parseDateTime(json['CreatedAt'] ?? json['createdAt'] ?? json['created_at']),
        updatedAt: _parseDateTime(json['UpdatedAt'] ?? json['updatedAt'] ?? json['updated_at']),
      );
    }
    
    // Нормализуем JSON для сгенерированного метода (конвертируем заглавные в нижний регистр)
    final normalizedJson = <String, dynamic>{
      'id': id,
      'phone': phone,
      'role': role,
      'login': json['Login']?.toString() ?? json['login']?.toString(),
      'organizationID': json['OrganizationID']?.toString() ?? json['organizationID']?.toString() ?? json['organizationId']?.toString(),
      'driverID': json['DriverID']?.toString() ?? json['driverID']?.toString() ?? json['driverId']?.toString(),
      'isActive': _parseBool(isActiveValue) ?? true,
      'blockReason': json['BlockReason']?.toString() ?? json['blockReason']?.toString() ?? json['block_reason']?.toString(),
      'generatedPassword': json['GeneratedPassword']?.toString() ?? json['generatedPassword']?.toString() ?? json['generated_password']?.toString(),
      'createdAt': json['CreatedAt']?.toString() ?? json['createdAt']?.toString() ?? json['created_at']?.toString(),
      'updatedAt': json['UpdatedAt']?.toString() ?? json['updatedAt']?.toString() ?? json['updated_at']?.toString(),
    };
    
    // Если все обязательные поля присутствуют, пытаемся использовать сгенерированный метод
    try {
      return _$UserDtoFromJson(normalizedJson);
    } catch (e) {
      // Fallback: создаем UserDto с безопасной обработкой null значений
      print('Error parsing UserDto with generated method: $e');
      return UserDto(
        id: id,
        phone: phone,
        role: role,
        login: normalizedJson['login']?.toString(),
        organizationId: normalizedJson['organizationID']?.toString(),
        driverId: normalizedJson['driverID']?.toString(),
        isActive: normalizedJson['isActive'] as bool? ?? true,
        blockReason: normalizedJson['blockReason']?.toString(),
        generatedPassword: normalizedJson['generatedPassword']?.toString(),
        createdAt: _parseDateTime(normalizedJson['createdAt']?.toString()),
        updatedAt: _parseDateTime(normalizedJson['updatedAt']?.toString()),
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

