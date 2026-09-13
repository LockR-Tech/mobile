import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Khóa ứng dụng bằng sinh trắc học thiết bị (vân tay / khuôn mặt hệ điều hành).
///
/// Đây là app-lock: khi bật, mỗi lần mở app với phiên đăng nhập còn hiệu lực,
/// người dùng phải xác thực sinh trắc trước khi vào Home. Khác với
/// "nhận diện khuôn mặt AI" (backend, đang tắt bằng feature flag).
class BiometricService {
  BiometricService._();

  static const String _prefKey = 'biometric_lock_enabled';
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Thiết bị có hỗ trợ sinh trắc học (đã đăng ký vân tay/khuôn mặt) không.
  static Future<bool> isSupported() async {
    try {
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      return supported && canCheck;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey) ?? false;
  }

  static Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, value);
  }

  /// Hiện prompt sinh trắc của hệ điều hành. Trả về true nếu xác thực thành công.
  static Future<bool> authenticate({
    String reason = 'Xác thực để mở ứng dụng',
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // cho phép fallback PIN/mật khẩu thiết bị
        ),
      );
    } on PlatformException {
      return false;
    }
  }
}
