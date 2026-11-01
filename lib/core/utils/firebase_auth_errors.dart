/// Thông báo tiếng Việt cho lỗi Firebase Auth (đăng nhập SĐT / Google).
///
/// Mã lỗi tới từ nhiều nguồn: Android trả `invalid-phone-number` (FlutterFire
/// đổi từ `ERROR_INVALID_PHONE_NUMBER`), web có thể còn tiền tố `auth/`, đôi
/// khi chỉ có `unknown` kèm message gốc của Firebase (vd. `BILLING_NOT_ENABLED`).
/// Hàm thuần — không phụ thuộc plugin Firebase — để test được.
library;

import 'package:smart_laundry_locker/core/l10n/l10n.dart';

/// Câu báo khi dự án Firebase chưa bật đăng nhập bằng SĐT (chưa bật provider
/// Phone hoặc chưa liên kết thanh toán Blaze).
String get phoneLoginDisabledMessage => L10n.current.authPhoneLoginDisabled;

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
  String? fallback,
}) {
  final c = normalizeFirebaseAuthCode(code);
  switch (c) {
    case 'invalid-phone-number':
    case 'missing-phone-number':
      return L10n.current.authInvalidPhone;
    case 'too-many-requests':
      return L10n.current.authTooManyRequests;
    case 'quota-exceeded':
      return L10n.current.authSmsQuotaExceeded;
    case 'invalid-verification-code':
      return L10n.current.authOtpWrong;
    case 'missing-verification-code':
      return L10n.current.authEnterOtpCode;
    case 'session-expired':
    case 'code-expired':
    case 'invalid-verification-id':
    case 'missing-verification-id':
      return L10n.current.authOtpExpired;
    case 'billing-not-enabled':
    case 'operation-not-allowed':
      return phoneLoginDisabledMessage;
    case 'app-not-authorized':
    case 'missing-client-identifier':
    case 'invalid-app-credential':
    case 'missing-app-credential':
    case 'app-not-verified':
      return L10n.current.authAppNotVerified;
    case 'captcha-check-failed':
      return L10n.current.authRecaptchaFailed;
    case 'unauthorized-domain':
      return L10n.current.authSitePhoneNotAllowed;
    case 'network-request-failed':
      return L10n.current.authNoNetwork;
    case 'user-disabled':
      return L10n.current.authAccountDisabled;
    case 'web-context-cancelled':
    case 'web-context-already-presented':
      return L10n.current.authVerificationCancelled;
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
  return fallback ?? L10n.current.authOtpSendFailed;
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
      return L10n.current.authGooglePopupBlocked;
    case 'operation-not-allowed':
      return L10n.current.authGoogleLoginDisabled;
    case 'unauthorized-domain':
      return L10n.current.authSiteGoogleNotAllowed;
    case 'account-exists-with-different-credential':
      return L10n.current.authGoogleEmailOtherProvider;
    case 'network-request-failed':
      return L10n.current.authNoNetwork;
    case 'user-disabled':
      return L10n.current.authAccountDisabled;
  }
  return L10n.current.authGoogleLoginFailed;
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
    return L10n.current.authSessionVerifyFailed;
  }
  if (m.isEmpty || m == 'Đã xảy ra lỗi.') {
    return L10n.current.authLoginFailedRetry;
  }
  return m;
}
