import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/core/services/firebase_messaging_service.dart';
import 'package:smart_laundry_locker/core/services/token_service.dart';

/// Đăng xuất dùng chung cho mọi vai trò (khách, KTV tủ, KTV drone).
///
/// Thứ tự: gỡ thiết bị khỏi danh sách nhận push của tài khoản và thu hồi refresh token
/// ở server, rồi mới xoá token trên máy. Hai bước gọi server là best-effort (tối đa vài
/// giây, lỗi mạng bỏ qua) để người dùng không bị kẹt ở màn đăng xuất; thiếu bước gỡ
/// push thì máy vẫn nhận thông báo của tài khoản cũ sau khi đăng xuất.
///
/// Nơi gọi tự reset provider/state của màn hình mình (vd. `ProfileProvider.reset()`).
class SessionService {
  SessionService._();

  static const _stepTimeout = Duration(seconds: 4);

  static Future<void> logout({ApiClient? apiClient}) async {
    final client = apiClient ?? ApiClient();
    final refreshToken = await TokenService.getRefreshToken();
    final fcmToken = await _quietly(FirebaseMessagingService.instance.getToken());

    await Future.wait([
      if (fcmToken != null && fcmToken.isNotEmpty)
        _quietly(client.delete<dynamic>(
          '/api/notifications/fcm-tokens',
          data: {'token': fcmToken},
        )),
      if (refreshToken != null && refreshToken.isNotEmpty)
        _quietly(client.post<dynamic>(
          '/api/auth/logout',
          data: {'refreshToken': refreshToken},
        )),
    ]);

    await TokenService.clearTokens();
  }

  static Future<T?> _quietly<T>(Future<T> call) async {
    try {
      return await call.timeout(_stepTimeout);
    } catch (e) {
      debugPrint('SessionService.logout: bỏ qua bước lỗi: $e');
      return null;
    }
  }
}
