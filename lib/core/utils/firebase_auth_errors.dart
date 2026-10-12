/// Thông báo tiếng Việt cho lỗi Firebase Auth (đăng nhập SĐT / Google).
///
/// Mã lỗi tới từ nhiều nguồn: Android trả `invalid-phone-number` (FlutterFire
/// đổi từ `ERROR_INVALID_PHONE_NUMBER`), web có thể còn tiền tố `auth/`, đôi
/// khi chỉ có `unknown` kèm message gốc của Firebase (vd. `BILLING_NOT_ENABLED`).
/// Hàm thuần — không phụ thuộc plugin Firebase — để test được.
library;

/// Câu báo khi dự án Firebase chưa bật đăng nhập bằng SĐT (chưa bật provider
/// Phone hoặc chưa liên kết thanh toán Blaze).
const String phoneLoginDisabledMessage =
    'Đăng nhập bằng SĐT chưa được bật. Vui lòng dùng email để đăng nhập.';

/// Đưa mã lỗi về dạng `kebab-case` không tiền tố: `auth/too-many-requests`,
/// `ERROR_TOO_MANY_REQUESTS` → `too-many-requests`.
String normalizeFirebaseAuthCode(String? code) {
  var c = (code ?? '').trim().toLowerCase();
  if (c.startsWith('auth/')) c = c.substring(5);
  if (c.startsWith('error_')) c = c.substring(6);
  return c.replaceAll('_', '-');
}

/// Lỗi gửi/xác nhận mã OTP SĐT. [message] là message gốc của Firebase, dùng
/// khi mã lỗi chung chung (`unknown`, `internal-error`).
String phoneAuthErrorMessage(
  String? code, {
  String? message,
  String fallback = 'Không gửi được mã OTP. Vui lòng thử lại.',
}) {
  final c = normalizeFirebaseAuthCode(code);
  switch (c) {
    case 'invalid-phone-number':
    case 'missing-phone-number':
      return 'Số điện thoại không hợp lệ. Vui lòng kiểm tra lại (VD: 0912345678).';
    case 'too-many-requests':
      return 'Bạn đã yêu cầu mã quá nhiều lần. Vui lòng thử lại sau ít phút.';
    case 'quota-exceeded':
      return 'Hệ thống đã hết lượt gửi SMS trong hôm nay. '
          'Vui lòng thử lại sau hoặc đăng nhập bằng email.';
    case 'invalid-verification-code':
      return 'Mã OTP không đúng. Vui lòng kiểm tra lại.';
    case 'missing-verification-code':
      return 'Vui lòng nhập mã OTP.';
    case 'session-expired':
    case 'code-expired':
    case 'invalid-verification-id':
    case 'missing-verification-id':
      return 'Mã OTP đã hết hạn. Vui lòng bấm "Gửi lại mã".';
    case 'billing-not-enabled':
    case 'operation-not-allowed':
      return phoneLoginDisabledMessage;
    case 'app-not-authorized':
    case 'missing-client-identifier':
    case 'invalid-app-credential':
    case 'missing-app-credential':
    case 'app-not-verified':
      return 'Ứng dụng chưa được xác minh để gửi mã OTP. '
          'Vui lòng cập nhật ứng dụng hoặc dùng email để đăng nhập.';
    case 'captcha-check-failed':
      return 'Xác minh reCAPTCHA không thành công. Vui lòng thử lại.';
    case 'unauthorized-domain':
      return 'Trang web này chưa được phép đăng nhập bằng SĐT. '
          'Vui lòng dùng email để đăng nhập.';
    case 'network-request-failed':
      return 'Không có kết nối mạng. Vui lòng kiểm tra Internet rồi thử lại.';
    case 'user-disabled':
      return 'Tài khoản này đã bị khoá. Vui lòng liên hệ hỗ trợ.';
    case 'web-context-cancelled':
    case 'web-context-already-presented':
      return 'Đã huỷ xác minh. Vui lòng thử lại.';
  }

  // Mã chung chung: đoán theo message gốc của Firebase.
  final m = (message ?? '').toUpperCase();
  if (m.contains('BILLING_NOT_ENABLED') || m.contains('OPERATION_NOT_ALLOWED')) {
    return phoneLoginDisabledMessage;
  }
  if (m.contains('NOT AUTHORIZED') || m.contains('PLAY INTEGRITY')) {
    return phoneAuthErrorMessage('app-not-authorized');
  }
  if (m.contains('QUOTA')) return phoneAuthErrorMessage('quota-exceeded');
  if (m.contains('TOO_MANY') || m.contains('BLOCKED ALL REQUESTS')) {
    return phoneAuthErrorMessage('too-many-requests');
  }
  if (m.contains('NETWORK')) return phoneAuthErrorMessage('network-request-failed');
  return fallback;
}

/// `true` khi lỗi Google/OAuth chỉ là người dùng tự đóng cửa sổ đăng nhập.
bool isFirebaseAuthCancellation(String? code) {
  switch (normalizeFirebaseAuthCode(code)) {
    case 'popup-closed-by-user':
    case 'cancelled-popup-request':
    case 'user-cancelled':
    case 'web-context-cancelled':
      return true;
  }
  return false;
}

/// Lỗi đăng nhập Google qua Firebase.
String googleAuthErrorMessage(String? code) {
  switch (normalizeFirebaseAuthCode(code)) {
    case 'popup-blocked':
      return 'Trình duyệt đã chặn cửa sổ đăng nhập Google. '
          'Hãy cho phép cửa sổ bật lên rồi thử lại.';
    case 'operation-not-allowed':
      return 'Đăng nhập bằng Google chưa được bật. Vui lòng dùng email để đăng nhập.';
    case 'unauthorized-domain':
      return 'Trang web này chưa được phép đăng nhập bằng Google. '
          'Vui lòng dùng email để đăng nhập.';
    case 'account-exists-with-different-credential':
      return 'Email Google này đã gắn với cách đăng nhập khác. '
          'Vui lòng đăng nhập bằng cách bạn đã dùng trước đó.';
    case 'network-request-failed':
      return 'Không có kết nối mạng. Vui lòng kiểm tra Internet rồi thử lại.';
    case 'user-disabled':
      return 'Tài khoản này đã bị khoá. Vui lòng liên hệ hỗ trợ.';
  }
  return 'Đăng nhập Google thất bại';
}

/// Lỗi `POST /api/auth/firebase` (backend xác minh Firebase ID token).
///
/// Backend trả `AUTH_FIREBASE_INVALID` kèm message tiếng Anh "Invalid Firebase
/// ID Token: …" — thường do token hết hạn hoặc app dùng project Firebase khác
/// với backend.
String firebaseLoginBackendMessage(String raw) {
  final m = raw.trim();
  final upper = m.toUpperCase();
  if (upper.contains('AUTH_FIREBASE_INVALID') ||
      upper.contains('INVALID FIREBASE ID TOKEN')) {
    return 'Không xác thực được phiên đăng nhập. Vui lòng thử lại.';
  }
  if (m.isEmpty || m == 'Đã xảy ra lỗi.') {
    return 'Đăng nhập thất bại. Vui lòng thử lại.';
  }
  return m;
}
