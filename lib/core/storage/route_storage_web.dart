import 'dart:html' as html;

abstract class RouteStorage {
  static const _lastRouteKey = 'last_route';

  static Future<void> saveLastRoute(String route) async {
    html.window.localStorage[_lastRouteKey] = route;
  }

  static Future<String?> getLastRoute() async {
    return html.window.localStorage[_lastRouteKey];
  }

  static Future<void> clearLastRoute() async {
    html.window.localStorage.remove(_lastRouteKey);
  }
}







