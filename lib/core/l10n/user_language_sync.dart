import 'package:flutter/foundation.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';
import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/core/services/token_service.dart';

/// Báo server ngôn ngữ app đang chọn (`PUT /api/user/language`) để thư và SMS
/// gửi ngoài app — mã mở tủ, đơn drone, sự cố… — soạn đúng ngôn ngữ (ADR-0010).
/// Gọi sau khi tải hồ sơ (đăng nhập / mở app) và mỗi lần đổi ngôn ngữ; chỉ gửi
/// khi khác lần gửi thành công gần nhất. Lỗi mạng bỏ qua — lần sau gửi lại.
class UserLanguageSync {
  UserLanguageSync._();

  static String? _lastSynced;

  static Future<void> sync({ApiClient? apiClient}) async {
    final language = L10n.current.localeName;
    if (language == _lastSynced) return;
    try {
      if (!await TokenService.isLoggedIn()) return;
      await (apiClient ?? ApiClient()).put<dynamic>(
        '/api/user/language',
        data: {'language': language},
      );
      _lastSynced = language;
    } catch (e) {
      debugPrint('UserLanguageSync: $e');
    }
  }

  /// Đăng xuất: tài khoản kế tiếp phải được báo lại.
  static void reset() => _lastSynced = null;

  @visibleForTesting
  static String? get lastSynced => _lastSynced;
}
