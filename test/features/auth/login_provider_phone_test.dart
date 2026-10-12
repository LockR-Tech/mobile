import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:smart_laundry_locker/core/services/firebase_auth_service.dart';
import 'package:smart_laundry_locker/core/utils/firebase_auth_errors.dart';
import 'package:smart_laundry_locker/features/auth/application/use_cases/login_use_case.dart';
import 'package:smart_laundry_locker/features/auth/application/use_cases/login_with_face_use_case.dart';
import 'package:smart_laundry_locker/features/auth/application/use_cases/send_email_login_otp_use_case.dart';
import 'package:smart_laundry_locker/features/auth/application/use_cases/social_login_use_case.dart';
import 'package:smart_laundry_locker/features/auth/application/use_cases/verify_email_login_otp_use_case.dart';
import 'package:smart_laundry_locker/features/auth/domain/entities/auth_token_entity.dart';
import 'package:smart_laundry_locker/features/auth/domain/repositories/auth_repository.dart';
import 'package:smart_laundry_locker/features/auth/presentation/providers/login_provider.dart';

import '../../helpers/test_helpers.dart';

/// Firebase giả: ghi lại lời gọi, trả kết quả do test chọn.
class _FakeFirebaseAuthService extends FirebaseAuthService {
  final sendCalls = <({String phone, PhoneCodeSession? resendFrom})>[];
  FirebaseAuthException? sendError;
  FirebaseAuthException? confirmError;
  void Function(String idToken)? autoVerify;
  int _nextToken = 100;

  @override
  Future<void> sendPhoneCode({
    required String phoneE164,
    required void Function(PhoneCodeSession session) onCodeSent,
    required void Function(FirebaseAuthException error) onFailed,
    void Function(String idToken)? onAutoVerified,
    PhoneCodeSession? resendFrom,
  }) async {
    sendCalls.add((phone: phoneE164, resendFrom: resendFrom));
    autoVerify = onAutoVerified;
    if (sendError != null) {
      onFailed(sendError!);
      return;
    }
    onCodeSent(
      PhoneCodeSession(
        phoneNumber: phoneE164,
        verificationId: 'ver-${sendCalls.length}',
        resendToken: _nextToken++,
      ),
    );
  }

  @override
  Future<String?> confirmPhoneCode(
    PhoneCodeSession session,
    String smsCode,
  ) async {
    if (confirmError != null) throw confirmError!;
    return 'firebase-id-token-for-${session.verificationId}';
  }
}

/// Backend giả: chỉ `firebaseLogin` được dùng trong luồng SĐT.
class _FakeAuthRepository implements AuthRepository {
  final firebaseLogins = <String>[];
  Failure? failure;

  @override
  Future<Either<Failure, AuthTokenEntity>> firebaseLogin({
    required String idToken,
  }) async {
    firebaseLogins.add(idToken);
    // Đăng nhập thật có độ trễ mạng — để lộ lỗi đăng nhập hai lần.
    await Future<void>.delayed(const Duration(milliseconds: 10));
    if (failure != null) return Left(failure!);
    return const Right(AuthTokenEntity(accessToken: 'a', refreshToken: 'r'));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeFirebaseAuthService firebase;
  late _FakeAuthRepository repository;
  late LoginProvider provider;
  late DateTime now;

  setUp(() {
    now = DateTime(2026, 10, 12, 9);
    final mock = createMockApiClient();
    firebase = _FakeFirebaseAuthService();
    repository = _FakeAuthRepository();
    provider = LoginProvider(
      loginUseCase: LoginUseCase(repository),
      loginWithFaceUseCase: LoginWithFaceUseCase(repository),
      socialLoginUseCase: SocialLoginUseCase(repository),
      sendEmailLoginOtpUseCase: SendEmailLoginOtpUseCase(repository),
      verifyEmailLoginOtpUseCase: VerifyEmailLoginOtpUseCase(repository),
      firebaseAuthService: firebase,
      apiClient: mock.apiClient,
      clock: () => now,
    );
  });

  test('chuẩn hoá số nội địa sang E.164 trước khi gửi Firebase', () async {
    await provider.sendPhoneOtp('0912 345 678');

    expect(firebase.sendCalls.single.phone, '+84912345678');
    expect(provider.isPhoneCodeSent, isTrue);
    expect(provider.phoneNumberSentTo, '+84912345678');
    expect(provider.isLoading, isFalse);
    expect(provider.resendSecondsLeft(), greaterThan(0));
  });

  test('số sai thì báo lỗi ngay, không gọi Firebase', () async {
    await provider.sendPhoneOtp('12345');

    expect(firebase.sendCalls, isEmpty);
    expect(provider.isPhoneCodeSent, isFalse);
    expect(provider.error, phoneAuthErrorMessage('invalid-phone-number'));
  });

  test('lỗi Firebase được dịch sang tiếng Việt', () async {
    firebase.sendError = FirebaseAuthException(code: 'operation-not-allowed');

    await provider.sendPhoneOtp('0912345678');

    expect(provider.error, startsWith('Đăng nhập bằng SĐT chưa được bật'));
    expect(provider.isLoading, isFalse);
    expect(provider.isPhoneCodeSent, isFalse);
  });

  test('gửi lại mã: chờ hết đếm ngược, rồi gửi kèm forceResendingToken', () async {
    await provider.sendPhoneOtp('0912345678');
    expect(firebase.sendCalls.single.resendFrom, isNull);
    expect(provider.resendSecondsLeft(), 60);

    // Còn trong thời gian chờ ⇒ không gửi.
    now = now.add(const Duration(seconds: 30));
    expect(provider.resendSecondsLeft(), 30);
    await provider.resendPhoneOtp();
    expect(firebase.sendCalls, hasLength(1));

    // Hết 60 s ⇒ gửi lại đúng số cũ, kèm token Android của lần trước.
    now = now.add(const Duration(seconds: 30));
    expect(provider.resendSecondsLeft(), 0);
    await provider.resendPhoneOtp();
    expect(firebase.sendCalls, hasLength(2));
    expect(firebase.sendCalls.last.phone, '+84912345678');
    expect(firebase.sendCalls.last.resendFrom?.resendToken, 100);
    // Đếm ngược bắt đầu lại.
    expect(provider.resendSecondsLeft(), 60);
  });

  test('đổi số điện thoại ⇒ về bước nhập số, lần gửi mới không mang token cũ', () async {
    await provider.sendPhoneOtp('0912345678');

    provider.clearPhoneVerification();
    expect(provider.isPhoneCodeSent, isFalse);
    expect(provider.resendSecondsLeft(), 0);

    await provider.sendPhoneOtp('0987654321');
    expect(firebase.sendCalls.last.resendFrom, isNull);
    expect(firebase.sendCalls.last.phone, '+84987654321');
  });

  test('xác nhận mã đúng ⇒ đăng nhập backend, đánh dấu đăng nhập bằng SĐT', () async {
    await provider.sendPhoneOtp('0912345678');

    await provider.confirmPhoneOtp('123456');

    expect(repository.firebaseLogins, ['firebase-id-token-for-ver-1']);
    expect(provider.isSuccess, isTrue);
    expect(provider.lastLoginViaPhone, isTrue);
  });

  test('mã OTP phải đủ 6 số', () async {
    await provider.sendPhoneOtp('0912345678');

    await provider.confirmPhoneOtp('12');

    expect(provider.error, 'Mã OTP gồm 6 chữ số');
    expect(repository.firebaseLogins, isEmpty);
  });

  test('mã sai ⇒ thông báo tiếng Việt, không đăng nhập', () async {
    firebase.confirmError = FirebaseAuthException(
      code: 'invalid-verification-code',
    );
    await provider.sendPhoneOtp('0912345678');

    await provider.confirmPhoneOtp('000000');

    expect(provider.error, phoneAuthErrorMessage('invalid-verification-code'));
    expect(provider.isSuccess, isFalse);
    expect(repository.firebaseLogins, isEmpty);
  });

  test('Android tự xác minh + người dùng bấm xác nhận cùng lúc ⇒ chỉ đăng nhập một lần', () async {
    await provider.sendPhoneOtp('0912345678');

    // SMS tự đọc được đúng lúc người dùng cũng bấm "Xác nhận".
    firebase.autoVerify!('auto-token');
    await provider.confirmPhoneOtp('123456');
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(repository.firebaseLogins, ['auto-token']);
    expect(provider.isSuccess, isTrue);
  });

  test('backend từ chối token ⇒ báo lỗi, chưa đăng nhập', () async {
    repository.failure = const ValidationFailure(
      'Không xác thực được phiên đăng nhập. Vui lòng thử lại.',
    );
    await provider.sendPhoneOtp('0912345678');

    await provider.confirmPhoneOtp('123456');

    expect(provider.isSuccess, isFalse);
    expect(provider.error, contains('Không xác thực được'));
    expect(provider.lastLoginViaPhone, isFalse);
  });
}
