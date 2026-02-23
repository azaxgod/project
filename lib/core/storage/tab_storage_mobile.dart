import 'package:shared_preferences/shared_preferences.dart';

abstract class TabStorage {
  static Future<void> saveTabIndex(String pageKey, int index) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'tab_index_$pageKey';
    await prefs.setInt(key, index);
  }

  static Future<int?> getTabIndex(String pageKey) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'tab_index_$pageKey';
    return prefs.getInt(key);
  }

  static Future<void> clearTabIndex(String pageKey) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'tab_index_$pageKey';
    await prefs.remove(key);
  }
}






