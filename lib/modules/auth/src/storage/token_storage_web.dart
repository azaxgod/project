import 'dart:html' as html;

abstract class TokenStorage {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  static Future<void> saveAccessToken(String token) async {
    html.window.localStorage[_accessTokenKey] = token;
  }

  static Future<String?> getAccessToken() async {
    return html.window.localStorage[_accessTokenKey];
  }

  static Future<void> saveRefreshToken(String token) async {
    html.window.localStorage[_refreshTokenKey] = token;
  }

  static Future<String?> getRefreshToken() async {
    return html.window.localStorage[_refreshTokenKey];
  }
}
