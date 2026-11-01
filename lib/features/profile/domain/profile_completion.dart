/// Bước "Hoàn tất đăng ký" sau khi đăng nhập bằng SĐT.
///
/// Lần đầu đăng nhập SĐT, backend (`POST /api/auth/firebase`) tự tạo tài khoản
/// tên "User", không email. App hỏi họ tên (email tuỳ chọn) rồi lưu qua
/// `PUT /api/user/profile {firstName, lastName, email?}`. Người dùng bỏ qua
/// được; lần đăng nhập SĐT sau vẫn hỏi lại cho tới khi hồ sơ có tên thật.
library;

import 'package:smart_laundry_locker/features/profile/domain/constants/profile_constants.dart';
import 'package:smart_laundry_locker/features/profile/domain/entities/user_profile.dart';
import 'package:smart_laundry_locker/features/profile/domain/utils/person_name.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

/// `true` khi hồ sơ (đã tải từ server) còn tên trống/mặc định ("User",
/// "Customer", "Khách"…).
bool needsProfileCompletion(UserProfile? profile) =>
    profile != null && isPlaceholderName(profile.fullName);

/// Kiểm ô "Họ và tên"; `null` = hợp lệ.
String? validateCompletionFullName(String? value) {
  final name = (value ?? '').trim().replaceAll(RegExp(r'\s+'), ' ');
  if (name.isEmpty) return L10n.current.authEnterFullName;
  if (name.length < ProfileConstants.minFullNameLength) {
    return L10n.current.nameMin(ProfileConstants.minFullNameLength);
  }
  if (name.length > ProfileConstants.maxFullNameLength) {
    return L10n.current.nameMax(ProfileConstants.maxFullNameLength);
  }
  if (!ProfileConstants.fullNameRegex.hasMatch(name)) {
    return L10n.current.nameLettersOnly;
  }
  if (isPlaceholderName(name)) return L10n.current.nameRealName;
  return null;
}

final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$');

/// Email không bắt buộc: để trống hợp lệ, có nhập thì phải đúng dạng.
String? validateOptionalEmail(String? value) {
  final email = (value ?? '').trim();
  if (email.isEmpty) return null;
  if (!_emailPattern.hasMatch(email)) return L10n.current.authInvalidEmail;
  return null;
}
