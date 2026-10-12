import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/core/utils/firebase_auth_errors.dart';

void main() {
  group('normalizeFirebaseAuthCode', () {
    test('bỏ tiền tố auth/ và ERROR_, đổi về kebab-case', () {
      expect(normalizeFirebaseAuthCode('auth/too-many-requests'), 'too-many-requests');
      expect(normalizeFirebaseAuthCode('ERROR_INVALID_PHONE_NUMBER'), 'invalid-phone-number');
      expect(normalizeFirebaseAuthCode(null), '');
    });
  });

  group('phoneAuthErrorMessage', () {
    test('mỗi mã lỗi Firebase có câu tiếng Việt riêng', () {
      expect(phoneAuthErrorMessage('invalid-phone-number'), contains('Số điện thoại không hợp lệ'));
      expect(phoneAuthErrorMessage('too-many-requests'), contains('quá nhiều lần'));
      expect(phoneAuthErrorMessage('quota-exceeded'), contains('hết lượt gửi SMS'));
      expect(phoneAuthErrorMessage('invalid-verification-code'), contains('Mã OTP không đúng'));
      expect(phoneAuthErrorMessage('session-expired'), contains('hết hạn'));
      expect(phoneAuthErrorMessage('app-not-authorized'), contains('chưa được xác minh'));
      expect(phoneAuthErrorMessage('network-request-failed'), contains('kết nối mạng'));
    });

    test('billing-not-enabled / operation-not-allowed ⇒ "Đăng nhập bằng SĐT chưa được bật"', () {
      for (final code in [
        'billing-not-enabled',
        'operation-not-allowed',
        'auth/operation-not-allowed',
        'ERROR_OPERATION_NOT_ALLOWED',
      ]) {
        expect(
          phoneAuthErrorMessage(code),
          startsWith('Đăng nhập bằng SĐT chưa được bật'),
          reason: code,
        );
      }
    });

    test('mã chung chung thì đoán theo message gốc của Firebase', () {
      expect(
        phoneAuthErrorMessage('unknown', message: 'An internal error has occurred. [ BILLING_NOT_ENABLED ]'),
        phoneLoginDisabledMessage,
      );
      expect(
        phoneAuthErrorMessage(
          'internal-error',
          message: 'This app is not authorized to use Firebase Authentication.',
        ),
        phoneAuthErrorMessage('app-not-authorized'),
      );
      expect(
        phoneAuthErrorMessage(
          'unknown',
          message: 'We have blocked all requests from this device due to unusual activity.',
        ),
        phoneAuthErrorMessage('too-many-requests'),
      );
    });

    test('không nhận ra ⇒ fallback, không lộ message tiếng Anh', () {
      expect(phoneAuthErrorMessage('weird', message: 'Something odd'), 'Không gửi được mã OTP. Vui lòng thử lại.');
      expect(phoneAuthErrorMessage(null, fallback: 'X'), 'X');
    });
  });

  group('Google', () {
    test('đóng popup = huỷ, không báo lỗi', () {
      expect(isFirebaseAuthCancellation('popup-closed-by-user'), isTrue);
      expect(isFirebaseAuthCancellation('auth/cancelled-popup-request'), isTrue);
      expect(isFirebaseAuthCancellation('popup-blocked'), isFalse);
    });

    test('popup bị chặn có hướng dẫn', () {
      expect(googleAuthErrorMessage('popup-blocked'), contains('chặn cửa sổ'));
      expect(googleAuthErrorMessage('whatever'), 'Đăng nhập Google thất bại');
    });
  });

  test('firebaseLoginBackendMessage dịch AUTH_FIREBASE_INVALID của backend', () {
    expect(
      firebaseLoginBackendMessage('Invalid Firebase ID Token: Firebase ID token has expired'),
      'Không xác thực được phiên đăng nhập. Vui lòng thử lại.',
    );
    expect(firebaseLoginBackendMessage('Tài khoản đã bị khoá'), 'Tài khoản đã bị khoá');
    expect(firebaseLoginBackendMessage(''), 'Đăng nhập thất bại. Vui lòng thử lại.');
  });
}
