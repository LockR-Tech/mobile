/// Thông báo tiếng Việt cho lỗi `PUT /api/user/profile`.
///
/// Backend kiểm trùng email/SĐT với người dùng khác (`USER_EMAIL_TAKEN`,
/// `USER_PHONE_TAKEN`) và với tài khoản đăng nhập (`AUTH_EMAIL_TAKEN`,
/// `AUTH_PHONE_TAKEN`) rồi mới đồng bộ sang auth-service (`AUTH_SYNC_FAILED`).
/// Message backend đã là tiếng Việt kèm giá trị bị trùng nên giữ nguyên; chỉ
/// thay khi nhận được mã trần hoặc thông báo chung chung.
String profileUpdateErrorMessage(String raw) {
  final m = raw.trim();
  final upper = m.toUpperCase();
  if (upper == 'USER_PHONE_TAKEN' || upper == 'AUTH_PHONE_TAKEN') {
    return 'Số điện thoại này đã được dùng cho tài khoản khác';
  }
  if (upper == 'USER_EMAIL_TAKEN' || upper == 'AUTH_EMAIL_TAKEN') {
    return 'Email này đã được dùng cho tài khoản khác';
  }
  if (upper == 'AUTH_SYNC_FAILED') {
    return 'Không cập nhật được tài khoản đăng nhập, vui lòng thử lại';
  }
  if (m.isEmpty || m == 'Đã xảy ra lỗi.') {
    return 'Cập nhật hồ sơ thất bại. Vui lòng thử lại.';
  }
  return m;
}
