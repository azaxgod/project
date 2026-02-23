import 'dart:html' as html;

abstract class TabStorage {
  static Future<void> saveTabIndex(String pageKey, int index) async {
    final key = 'tab_index_$pageKey';
    html.window.localStorage[key] = index.toString();
  }

  static Future<int?> getTabIndex(String pageKey) async {
    final key = 'tab_index_$pageKey';
    final value = html.window.localStorage[key];
    if (value == null) return null;
    return int.tryParse(value);
  }

  static Future<void> clearTabIndex(String pageKey) async {
    final key = 'tab_index_$pageKey';
    html.window.localStorage.remove(key);
  }
}



