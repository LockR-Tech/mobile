import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

/// Ngôn ngữ giao diện người dùng chọn ở Hồ sơ. Mặc định tiếng Việt, không
/// theo ngôn ngữ máy — khách chủ yếu là người Việt.
class LocaleProvider extends ChangeNotifier {
  LocaleProvider._();

  static final instance = LocaleProvider._();

  static const _key = 'app_locale';

  Locale get locale => L10n.locale;

  bool get isEnglish => L10n.isEnglish;

  /// Gọi trong `main()` trước `runApp` để khung hình đầu đã đúng ngôn ngữ.
  Future<void> restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_key);
      if (saved == L10n.en.languageCode) L10n.load(L10n.en);
    } catch (_) {
      // Không đọc được thì giữ tiếng Việt.
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (locale.languageCode == L10n.locale.languageCode) return;
    L10n.load(locale);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale.languageCode);
  }
}
