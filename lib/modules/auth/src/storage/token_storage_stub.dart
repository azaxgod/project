// token_storage_stub.dart
abstract class TokenStorage {
  static Future<void> saveAccessToken(String token) =>
      throw UnimplementedError();
  static Future<String?> getAccessToken() =>
      throw UnimplementedError();
  static Future<void> saveRefreshToken(String token) =>
      throw UnimplementedError();
  static Future<String?> getRefreshToken() =>
      throw UnimplementedError();
}
