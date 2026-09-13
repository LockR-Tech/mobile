import 'package:shared_preferences/shared_preferences.dart';

class AppInitialTabService {
  static const String _key = 'initial_tab_index';

  static Future<void> setInitialTab(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, index);
  }

  static Future<int> getAndResetInitialTab() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_key) ?? 0;
    await prefs.setInt(_key, 0);
    return index;
  }
}
