import 'package:flutter/foundation.dart';
import '../config/env_config.dart';

/// Địa chỉ backend Lock.R. Đường dẫn API nằm ngay tại service gọi nó
/// (vd. `LockerOpsService`); các hằng số endpoint của template cũ (Revoland:
/// `/properties`, `/api/provinces`, `/orders/me`...) đã gỡ vì backend không có.
class ApiConstants {
  static String get apiBaseUrl {
    final url = EnvConfig.apiBaseUrl;
    // Handle web platform where 10.0.2.2 (Android emulator localhost alias) doesn't work
    if (kIsWeb && url.contains('10.0.2.2')) {
      return url.replaceAll('10.0.2.2', 'localhost');
    }
    return url;
  }
}
