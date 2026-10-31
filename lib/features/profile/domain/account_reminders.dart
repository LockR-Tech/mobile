/// Luật nhắc sau đăng nhập — tách khỏi UI để test được.
///
/// * Điều khoản dịch vụ: khách chưa bấm "Đồng ý" ⇒ phải đồng ý mới dùng tiếp ([needsTermsConsent]).
/// * Thông tin còn thiếu (email / số điện thoại): nhắc ngay lần đăng nhập đầu, "Để sau" ⇒ nhắc lại sau
///   [reminderSnooze]; bấm "Cập nhật ngay" mà chưa lưu ⇒ nhắc lại sau [reminderSnoozeAfterOpen].
library;

import 'package:smart_laundry_locker/features/profile/domain/entities/user_profile.dart';

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
    if (profile.email.trim().isEmpty) 'email',
    if (profile.phoneNumber.trim().isEmpty) 'số điện thoại',
  ];
}

/// Đến lúc nhắc chưa: chưa nhắc lần nào (lần đăng nhập đầu) hoặc đã qua mốc hoãn.
bool reminderDue(DateTime? snoozedUntil, DateTime now) =>
    snoozedUntil == null || !now.isBefore(snoozedUntil);

String missingContactSentence(List<String> missing) => switch (missing.length) {
  0 => '',
  1 => 'Tài khoản của bạn chưa có ${missing.first}.',
  _ => 'Tài khoản của bạn chưa có ${missing.sublist(0, missing.length - 1).join(', ')} '
      'và ${missing.last}.',
};
