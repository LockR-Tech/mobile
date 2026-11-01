/// Quy tắc đổi / đặt mật khẩu (`PUT /api/user/password`).
///
/// Backend (auth-service) bắt buộc `currentPassword` khi tài khoản đã có mật
/// khẩu (`hasPassword` của `GET /api/user/profile`). Tài khoản Google/OTP chưa
/// từng đặt mật khẩu (`hasPassword == false`) thì đặt mật khẩu lần đầu, không
/// cần mật khẩu cũ. Mọi thứ đi trong MỘT lời gọi — không còn "kiểm mật khẩu
/// bằng cách đăng nhập lại" như trước.
library;

import 'package:smart_laundry_locker/core/l10n/l10n.dart';

/// Màn bảo mật hiển thị form nào.
enum PasswordFormMode {
  /// Đổi mật khẩu: mật khẩu hiện tại + mật khẩu mới.
  change,

  /// Đặt mật khẩu lần đầu: chỉ mật khẩu mới.
  set,
}

/// Độ dài tối thiểu, khớp kiểm tra cũ của màn bảo mật và form đăng ký.
const int kMinPasswordLength = 6;

PasswordFormMode passwordFormModeFor({required bool hasPassword}) =>
    hasPassword ? PasswordFormMode.change : PasswordFormMode.set;

/// Mật khẩu luôn được cắt khoảng trắng hai đầu — giống form đăng ký, đăng nhập
/// và quên mật khẩu, để mật khẩu đặt ở đâu cũng đăng nhập được ở chỗ khác.
String normalizePassword(String raw) => raw.trim();

/// Body gửi `PUT /api/user/password`.
Map<String, dynamic> buildPasswordChangeBody({
  required PasswordFormMode mode,
  String? currentPassword,
  required String newPassword,
}) {
  return {
    if (mode == PasswordFormMode.change)
      'currentPassword': normalizePassword(currentPassword ?? ''),
    'newPassword': normalizePassword(newPassword),
  };
}

/// Lỗi của form (tiếng Việt) hoặc `null` khi gửi được.
String? validatePasswordForm({
  required PasswordFormMode mode,
  String? currentPassword,
  required String newPassword,
  required String confirmPassword,
}) {
  final current = normalizePassword(currentPassword ?? '');
  final next = normalizePassword(newPassword);
  final confirm = normalizePassword(confirmPassword);

  if (mode == PasswordFormMode.change && current.isEmpty) {
    return L10n.current.pwEnterCurrent;
  }
  if (next.isEmpty) return L10n.current.pwEnterNew;
  if (next.length < kMinPasswordLength) {
    return L10n.current.pwMinLength(kMinPasswordLength);
  }
  if (mode == PasswordFormMode.change && next == current) {
    return L10n.current.pwSameAsCurrent;
  }
  if (confirm != next) return L10n.current.pwConfirmMismatch;
  return null;
}

/// Kết quả đổi mật khẩu. Backend thu hồi refresh token của mọi máy và trả cặp
/// token mới cho máy đang đổi — app phải lưu lại, nếu không lần làm mới token
/// kế tiếp sẽ thất bại và người dùng bị đăng xuất.
class PasswordChangeResult {
  final String? accessToken;
  final String? refreshToken;

  const PasswordChangeResult({this.accessToken, this.refreshToken});

  bool get hasTokens =>
      (accessToken ?? '').isNotEmpty && (refreshToken ?? '').isNotEmpty;

  /// Đọc `data` của response. Backend cũ trả `data` rỗng ⇒ không có token.
  factory PasswordChangeResult.fromResponse(dynamic body) {
    final data = body is Map ? (body['data'] is Map ? body['data'] : body) : null;
    if (data is! Map) return const PasswordChangeResult();
    final access = data['accessToken']?.toString();
    final refresh = data['refreshToken']?.toString();
    return PasswordChangeResult(accessToken: access, refreshToken: refresh);
  }
}

/// Thông báo tiếng Việt cho lỗi đổi mật khẩu theo mã/message backend.
String passwordChangeErrorMessage(String raw) {
  final m = raw.trim();
  final upper = m.toUpperCase();
  if (upper.contains('AUTH_INVALID_PASSWORD')) {
    return L10n.current.pwCurrentWrong;
  }
  if (upper.contains('AUTH_CURRENT_PASSWORD_REQUIRED')) {
    return L10n.current.pwEnterCurrent;
  }
  if (upper.contains('AUTH_NEW_PASSWORD_REQUIRED')) {
    return L10n.current.pwEnterNew;
  }
  if (m.isEmpty || m == 'Đã xảy ra lỗi.') {
    return L10n.current.pwChangeFailed;
  }
  return m;
}
