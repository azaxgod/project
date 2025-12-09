abstract class TabStorage {
  static Future<void> saveTabIndex(String pageKey, int index) async {
    throw UnimplementedError('TabStorage not implemented for this platform');
  }

  static Future<int?> getTabIndex(String pageKey) async {
    throw UnimplementedError('TabStorage not implemented for this platform');
  }

  static Future<void> clearTabIndex(String pageKey) async {
    throw UnimplementedError('TabStorage not implemented for this platform');
  }
}

