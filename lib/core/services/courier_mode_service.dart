import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CourierModeService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _key = 'courier_mode';
  static const String _isCourierUserKey = 'is_courier_user';

  static Future<bool> getCourierMode() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return false;
    return raw == '1' || raw.toLowerCase() == 'true';
  }

  static Future<void> setCourierMode(bool value) async {
    await _storage.write(key: _key, value: value ? '1' : '0');
  }

  static Future<bool?> getIsCourierUser() async {
    final raw = await _storage.read(key: _isCourierUserKey);
    if (raw == null) return null;
    return raw == '1' || raw.toLowerCase() == 'true';
  }

  static Future<void> setIsCourierUser(bool value) async {
    await _storage.write(key: _isCourierUserKey, value: value ? '1' : '0');
  }
}
