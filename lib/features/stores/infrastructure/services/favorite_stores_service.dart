import 'package:shared_preferences/shared_preferences.dart';

/// Local, device-only favourite stores, ported from the legacy React Native
/// customer app (which kept favourites in AsyncStorage). There is no backend
/// favourites endpoint, so this persists a simple set of store ids.
class FavoriteStoresService {
  static const String _key = 'favorite_store_ids';

  Future<Set<int>> getFavoriteIds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? const <String>[];
    return raw.map(int.tryParse).whereType<int>().toSet();
  }

  Future<bool> isFavorite(int id) async {
    return (await getFavoriteIds()).contains(id);
  }

  /// Toggles [id] and returns the new state (`true` = now a favourite).
  Future<bool> toggle(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = (prefs.getStringList(_key) ?? const <String>[]).toSet();
    final key = '$id';
    final nowFavorite = !ids.contains(key);
    if (nowFavorite) {
      ids.add(key);
    } else {
      ids.remove(key);
    }
    await prefs.setStringList(_key, ids.toList());
    return nowFavorite;
  }
}
