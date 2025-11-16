import 'package:json_annotation/json_annotation.dart';

part 'send_code_response.g.dart';

/// Ответ от /auth/send-code
/// Не оборачивается в {"data": ...}
@JsonSerializable()
class SendCodeResponse {
  @JsonKey(name: 'masked_phone')
  final String maskedPhone;

  SendCodeResponse({
    required this.maskedPhone,
  });

  factory SendCodeResponse.fromJson(Map<String, dynamic> json) =>
      _$SendCodeResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SendCodeResponseToJson(this);
}

