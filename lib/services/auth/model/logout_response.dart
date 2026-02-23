import 'package:json_annotation/json_annotation.dart';

part 'logout_response.g.dart';

/// Ответ от /auth/logout
/// Не оборачивается в {"data": ...}
@JsonSerializable()
class LogoutResponse {
  final bool success;

  LogoutResponse({
    required this.success,
  });

  factory LogoutResponse.fromJson(Map<String, dynamic> json) =>
      _$LogoutResponseFromJson(json);

  Map<String, dynamic> toJson() => _$LogoutResponseToJson(this);
}

