import 'package:flutter/widgets.dart';
import 'package:smart_laundry_locker/l10n/app_localizations.dart';

export 'package:smart_laundry_locker/l10n/app_localizations.dart';

/// Chuỗi giao diện theo ngôn ngữ đang chọn.
///
/// Trong widget dùng `context.l10n`; code không có `BuildContext` (nhãn trạng
/// thái trong entity, thông báo lỗi của service…) dùng [L10n.current].
/// Đổi ngôn ngữ ở [LocaleProvider] — app dựng lại nên mọi nhãn đọc lại bản mới.
class L10n {
  L10n._();

  static const vi = Locale('vi');
  static const en = Locale('en');
  static const supportedLocales = [vi, en];

  static AppLocalizations _current = lookupAppLocalizations(vi);

  static AppLocalizations get current => _current;

  static Locale get locale => Locale(_current.localeName);

  static bool get isEnglish => _current.localeName == 'en';

  static void load(Locale locale) {
    _current = lookupAppLocalizations(locale);
  }
}

extension AppLocalizationsContext on BuildContext {
  /// Cố ý không đăng ký phụ thuộc vào [Localizations]: gọi được cả trong
  /// `initState`, sau `await`, và trong widget test không có delegate. Đổi
  /// ngôn ngữ thì app dựng lại toàn bộ nên không cần widget tự rebuild.
  AppLocalizations get l10n => L10n.current;
}
