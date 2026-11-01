/// Luật nhắc sau đăng nhập — tách khỏi UI để test được.
///
/// * Điều khoản dịch vụ: khách chưa bấm "Đồng ý" ⇒ phải đồng ý mới dùng tiếp ([needsTermsConsent]).
/// * Thông tin còn thiếu (email / số điện thoại): nhắc ngay lần đăng nhập đầu, "Để sau" ⇒ nhắc lại sau
///   [reminderSnooze]; bấm "Cập nhật ngay" mà chưa lưu ⇒ nhắc lại sau [reminderSnoozeAfterOpen].
library;

import 'package:smart_laundry_locker/features/profile/domain/entities/user_profile.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

/// Phiên bản Điều khoản dịch vụ đang áp dụng (`assets/markdown/terms_of_service.md`). Đổi điều khoản thì
/// tăng số này; backend lưu phiên bản người dùng đã đồng ý.
const String currentTermsVersion = '2026-10-31';

const Duration reminderSnooze = Duration(days: 7);
const Duration reminderSnoozeAfterOpen = Duration(days: 1);

bool needsTermsConsent(UserProfile? profile) => profile != null && !profile.termsAccepted;

/// Thông tin liên hệ còn thiếu, theo tên hiển thị cho người dùng.
List<String> missingContactFields(UserProfile? profile) {
  if (profile == null) return const [];
  return [
    if (profile.email.trim().isEmpty) L10n.current.reminderFieldEmail,
    if (profile.phoneNumber.trim().isEmpty) L10n.current.reminderFieldPhone,
  ];
}

/// Đến lúc nhắc chưa: chưa nhắc lần nào (lần đăng nhập đầu) hoặc đã qua mốc hoãn.
bool reminderDue(DateTime? snoozedUntil, DateTime now) =>
    snoozedUntil == null || !now.isBefore(snoozedUntil);

String missingContactSentence(List<String> missing) => switch (missing.length) {
  0 => '',
  1 => L10n.current.reminderMissing(missing.first),
  _ => L10n.current.reminderMissing(
      '${missing.sublist(0, missing.length - 1).join(', ')}'
      '${L10n.current.rulesAnd}${missing.last}',
    ),
};
