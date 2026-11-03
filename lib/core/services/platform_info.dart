import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Thông tin nền tảng đọc một lần lúc mở app (kênh `lockr/platform` trong `MainActivity.kt`).
class PlatformInfo {
  PlatformInfo._();

  static const _channel = MethodChannel('lockr/platform');

  /// Phiên bản Android (`Build.VERSION.SDK_INT`); 0 khi không phải Android hoặc chưa đọc được.
  static int androidSdk = 0;

  static Future<void> init() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      androidSdk = await _channel.invokeMethod<int>('sdkInt') ?? 0;
    } catch (_) {
      androidSdk = 0;
    }
  }

  /// Android 13+ tự hiện ô "Đã sao chép" của hệ thống mỗi lần app ghi clipboard ⇒ app không báo thêm,
  /// tránh hai thông báo chồng nhau.
  static bool get systemShowsCopyConfirmation => androidSdk >= 33;
}
