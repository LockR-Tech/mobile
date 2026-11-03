import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';
import 'package:smart_laundry_locker/core/routing/app_router.dart';

/// Hai văn bản pháp lý khách phải đồng ý. Nội dung nằm ở `assets/markdown/<id>.md` (tiếng Việt) và
/// `<id>_en.md` (tiếng Anh); trang `legal/*.html` (GitHub Pages) chép lại đúng nội dung này.
///
/// Mọi nơi mở văn bản (đăng ký, hộp thoại đồng ý, hồ sơ) đi qua [open] để cùng tiêu đề, cùng nội dung.
enum LegalDocument {
  terms('terms_of_service'),
  privacy('privacy_policy');

  const LegalDocument(this.id);

  /// Tên file không đuôi; cũng là đích của link giữa hai văn bản (`[Chính sách bảo mật](privacy_policy)`).
  final String id;

  String assetPath(Locale locale) =>
      'assets/markdown/$id${locale.languageCode == 'en' ? '_en' : ''}.md';

  String title(AppLocalizations l10n) => switch (this) {
    LegalDocument.terms => l10n.commonTermsOfUse,
    LegalDocument.privacy => l10n.commonPrivacyPolicy,
  };

  static LegalDocument? fromId(String? id) {
    for (final doc in values) {
      if (doc.id == id) return doc;
    }
    return null;
  }

  /// Đọc `extra` của route [AppRouter.policy]: [LegalDocument], hoặc map cũ `{assetPath}` từ bản trước.
  static LegalDocument fromRouteExtra(Object? extra) {
    if (extra is LegalDocument) return extra;
    if (extra is Map &&
        '${extra['assetPath']}'.contains(LegalDocument.terms.id)) {
      return LegalDocument.terms;
    }
    return LegalDocument.privacy;
  }

  Future<void> open(BuildContext context) =>
      context.push(AppRouter.policy, extra: this);
}
