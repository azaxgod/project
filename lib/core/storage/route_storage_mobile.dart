import 'package:shared_preferences/shared_preferences.dart';

abstract class RouteStorage {
  static const _lastRouteKey = 'last_route';

  static Future<void> saveLastRoute(String route) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastRouteKey, route);
  }

  static Future<String?> getLastRoute() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastRouteKey);
  }

  static Future<void> clearLastRoute() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastRouteKey);
  }
}








