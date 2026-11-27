import 'package:flutter/widgets.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';
import 'package:smart_laundry_locker/core/l10n/locale_provider.dart';
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

  /// Người dùng tự bấm VI/EN ở màn đăng nhập ⇒ lần đăng nhập kế tiếp giữ lựa chọn đó thay vì ngôn ngữ đã
  /// lưu của tài khoản.
  static bool _chosenBeforeLogin = false;

  static void markChosenBeforeLogin() => _chosenBeforeLogin = true;

  /// Vừa đăng nhập (F3-G15): tài khoản đã có ngôn ngữ — chọn trên máy khác hoặc web — mà khác máy này ⇒
  /// dùng ngôn ngữ của tài khoản. Tài khoản chưa có, hoặc người dùng vừa tự chọn ở màn đăng nhập ⇒ báo
  /// server ngôn ngữ của máy này. Gọi trước khi mở trang chủ để trang đầu đã đúng ngôn ngữ.
  static Future<void> adoptAccountLanguage({
    ApiClient? apiClient,
    Future<void> Function(Locale locale)? apply,
  }) async {
    final chosen = _chosenBeforeLogin;
    _chosenBeforeLogin = false;
    final client = apiClient ?? ApiClient();
    if (!chosen) {
      try {
        final res = await client
            .get<dynamic>('/api/user/profile')
            .timeout(const Duration(seconds: 4));
        final account = _languageOf(res.data);
        if (account != null && account != L10n.current.localeName) {
          _lastSynced = account;
          await (apply ?? LocaleProvider.instance.setLocale)(Locale(account));
          return;
        }
      } catch (e) {
        debugPrint('UserLanguageSync.adopt: $e');
      }
    }
    await sync(apiClient: client);
  }

  static String? _languageOf(Object? body) {
    final data = body is Map && body['data'] is Map ? body['data'] as Map : body;
    final language = data is Map ? data['language']?.toString() : null;
    return language == 'en' || language == 'vi' ? language : null;
  }

  /// Đăng xuất: tài khoản kế tiếp phải được báo lại.
  static void reset() {
    _lastSynced = null;
    _chosenBeforeLogin = false;
  }

  @visibleForTesting
  static String? get lastSynced => _lastSynced;
}
