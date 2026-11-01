import 'dart:typed_data';

import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/core/services/token_service.dart';
import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:smart_laundry_locker/features/auth/domain/entities/face_verify_result_entity.dart';
import 'package:smart_laundry_locker/features/auth/application/use_cases/login_use_case.dart';
import 'package:smart_laundry_locker/features/auth/application/use_cases/login_with_face_use_case.dart';
import 'package:smart_laundry_locker/features/auth/application/use_cases/social_login_use_case.dart';
import 'package:smart_laundry_locker/features/auth/application/use_cases/send_email_login_otp_use_case.dart';
import 'package:smart_laundry_locker/features/auth/application/use_cases/verify_email_login_otp_use_case.dart';
import 'package:smart_laundry_locker/core/services/firebase_auth_service.dart';
import 'package:smart_laundry_locker/features/auth/domain/entities/auth_token_entity.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:flutter/foundation.dart';
import 'package:smart_laundry_locker/core/utils/firebase_auth_errors.dart';
import 'package:smart_laundry_locker/core/utils/phone_utils.dart';

import 'package:smart_laundry_locker/core/l10n/l10n.dart';
class LoginProvider extends ChangeNotifier {
  final LoginUseCase _loginUseCase;
  final LoginWithFaceUseCase _loginWithFaceUseCase;
  final SocialLoginUseCase _socialLoginUseCase;
  final SendEmailLoginOtpUseCase _sendEmailLoginOtpUseCase;
  final VerifyEmailLoginOtpUseCase _verifyEmailLoginOtpUseCase;
  final FirebaseAuthService _firebaseAuthService;
  final ApiClient _apiClient;

  /// Đồng hồ cho đếm ngược "Gửi lại mã" (test thay được).
  final DateTime Function() _clock;

  LoginProvider({
    required LoginUseCase loginUseCase,
    required LoginWithFaceUseCase loginWithFaceUseCase,
    required SocialLoginUseCase socialLoginUseCase,
    required SendEmailLoginOtpUseCase sendEmailLoginOtpUseCase,
    required VerifyEmailLoginOtpUseCase verifyEmailLoginOtpUseCase,
    required FirebaseAuthService firebaseAuthService,
    required ApiClient apiClient,
    DateTime Function()? clock,
  }) : _loginUseCase = loginUseCase,
       _loginWithFaceUseCase = loginWithFaceUseCase,
       _socialLoginUseCase = socialLoginUseCase,
       _sendEmailLoginOtpUseCase = sendEmailLoginOtpUseCase,
       _verifyEmailLoginOtpUseCase = verifyEmailLoginOtpUseCase,
       _firebaseAuthService = firebaseAuthService,
       _apiClient = apiClient,
       _clock = clock ?? DateTime.now;

  // Màn đăng nhập huỷ provider khi chuyển trang, nhưng callback Firebase (tự
  // xác minh SMS trên Android…) có thể về muộn hơn ⇒ bỏ qua thay vì ném lỗi
  // "used after being disposed".
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  bool _isSuccess = false;
  bool get isSuccess => _isSuccess;

  AuthTokenEntity? _authToken;
  AuthTokenEntity? get authToken => _authToken;

  String? _matchedUserId;
  String? get matchedUserId => _matchedUserId;

  bool _isFaceMatched = false;
  bool get isFaceMatched => _isFaceMatched;

  Future<void> login({required String email, required String password}) async {
    _isLoading = true;
    _error = null;
    _isSuccess = false;
    notifyListeners();

    final params = LoginParams.fromForm(email: email, password: password);

    final result = await _loginUseCase(params);

    result.fold(_handleFailure, _handleLoginSuccess);
  }

  Future<void> loginWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final idToken = await _firebaseAuthService.signInWithGoogle();
      if (idToken == null) {
        _isLoading = false;
        notifyListeners();
        return; // user cancelled
      }
      final result = await _socialLoginUseCase(idToken);
      result.fold(_handleFailure, _handleLoginSuccess);
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _error = googleAuthErrorMessage(e.code);
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = L10n.current.authGoogleLoginFailed;
      notifyListeners();
    }
  }

  Future<void> loginWithFacebook() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final idToken = await _firebaseAuthService.signInWithFacebook();
      if (idToken == null) {
        _isLoading = false;
        notifyListeners();
        return; // user cancelled
      }
      final result = await _socialLoginUseCase(idToken);
      result.fold(_handleFailure, _handleLoginSuccess);
    } catch (e) {
      _isLoading = false;
      _error = L10n.current.authFacebookLoginFailed;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Đăng nhập / đăng ký bằng SĐT (Firebase Phone Auth → POST /api/auth/firebase;
  // số chưa có tài khoản thì backend tự tạo).
  // ---------------------------------------------------------------------------

  /// Phải chờ bao lâu sau mỗi lần gửi mới được "Gửi lại mã".
  static const Duration phoneResendCooldown = Duration(seconds: 60);

  PhoneCodeSession? _phoneSession;
  DateTime? _phoneCodeSentAt;
  bool _phoneSignInInFlight = false;

  /// Đã gửi mã, đang chờ nhập OTP.
  bool get isPhoneCodeSent => _phoneSession != null;

  /// Số (E.164) vừa được gửi mã.
  String? get phoneNumberSentTo => _phoneSession?.phoneNumber;

  bool _lastLoginViaPhone = false;

  /// Lần đăng nhập thành công gần nhất là bằng SĐT ⇒ màn đăng nhập hỏi
  /// "Hoàn tất đăng ký" khi hồ sơ chưa có tên.
  bool get lastLoginViaPhone => _lastLoginViaPhone;

  /// Số giây còn phải chờ trước khi gửi lại mã (0 = gửi lại được).
  int resendSecondsLeft() {
    final sentAt = _phoneCodeSentAt;
    if (sentAt == null) return 0;
    final left = phoneResendCooldown - _clock().difference(sentAt);
    if (left <= Duration.zero) return 0;
    return (left.inMilliseconds / 1000).ceil();
  }

  /// Gửi mã OTP tới số người dùng nhập (0912…, +84912…, 84912… đều được).
  Future<void> sendPhoneOtp(String phoneNumber) async {
    final phone = toE164Phone(phoneNumber);
    if (!isLikelyValidPhone(phone)) {
      _error = phone.isEmpty
          ? L10n.current.authEnterPhone
          : phoneAuthErrorMessage('invalid-phone-number');
      notifyListeners();
      return;
    }
    await _sendPhoneCode(phone);
  }

  /// "Gửi lại mã" cho số vừa gửi, kèm `forceResendingToken` (Android).
  Future<void> resendPhoneOtp() async {
    final session = _phoneSession;
    if (session == null || _isLoading || resendSecondsLeft() > 0) return;
    await _sendPhoneCode(session.phoneNumber, resendFrom: session);
  }

  Future<void> _sendPhoneCode(
    String phone, {
    PhoneCodeSession? resendFrom,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firebaseAuthService.sendPhoneCode(
        phoneE164: phone,
        resendFrom: resendFrom,
        onCodeSent: (session) {
          _phoneSession = session;
          _phoneCodeSentAt = _clock();
          _isLoading = false;
          notifyListeners();
        },
        onFailed: (e) {
          debugPrint('Phone verification failed: ${e.code} ${e.message}');
          _error = phoneAuthErrorMessage(e.code, message: e.message);
          _isLoading = false;
          notifyListeners();
        },
        // Android tự xác minh (đọc SMS / instant verification): đăng nhập luôn.
        onAutoVerified: _completePhoneLogin,
      );
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _error = phoneAuthErrorMessage(e.code, message: e.message);
      notifyListeners();
    } catch (e) {
      debugPrint('Send phone OTP error: $e');
      _isLoading = false;
      _error = phoneAuthErrorMessage(null);
      notifyListeners();
    }
  }

  /// Clears any in-progress phone verification so a freshly opened OTP dialog
  /// starts at the "enter phone number" step.
  void clearPhoneVerification() {
    _phoneSession = null;
    _phoneCodeSentAt = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> confirmPhoneOtp(String smsCode) async {
    final session = _phoneSession;
    if (session == null || _phoneSignInInFlight || _isSuccess) return;
    final code = smsCode.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      _error = L10n.current.authOtp6DigitsShort;
      notifyListeners();
      return;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final idToken = await _firebaseAuthService.confirmPhoneCode(
        session,
        code,
      );
      if (idToken == null) {
        _isLoading = false;
        _error = phoneAuthErrorMessage('invalid-verification-code');
        notifyListeners();
        return;
      }
      await _completePhoneLogin(idToken);
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _error = phoneAuthErrorMessage(
        e.code,
        message: e.message,
        fallback: L10n.current.authOtpConfirmFailed,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Confirm phone OTP error: $e');
      _isLoading = false;
      _error = L10n.current.authOtpConfirmFailed;
      notifyListeners();
    }
  }

  /// Đổi Firebase ID token lấy token backend. Tự xác minh (Android) và người
  /// dùng bấm "Xác nhận" có thể về gần như cùng lúc ⇒ chỉ đăng nhập một lần.
  Future<void> _completePhoneLogin(String idToken) async {
    if (_disposed || _phoneSignInInFlight || _isSuccess) return;
    _phoneSignInInFlight = true;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _socialLoginUseCase(idToken);
      await result.fold<Future<void>>(
        (failure) async => _handleFailure(failure),
        (token) => _handleLoginSuccess(token, viaPhone: true),
      );
    } catch (e) {
      // Gọi từ callback tự xác minh (không ai await) ⇒ không để lỗi lọt ra.
      debugPrint('Phone login error: $e');
      if (!_isSuccess) {
        _isLoading = false;
        _error = L10n.current.authLoginFailedRetry;
        notifyListeners();
      }
    } finally {
      _phoneSignInInFlight = false;
    }
  }

  bool _isEmailOtpSent = false;
  bool get isEmailOtpSent => _isEmailOtpSent;

  Future<void> sendEmailOtp(String email) async {
    _isLoading = true;
    _error = null;
    _isEmailOtpSent = false;
    notifyListeners();

    final result = await _sendEmailLoginOtpUseCase(email);
    result.fold(
      (failure) {
        _isLoading = false;
        _error = failure.message;
        notifyListeners();
      },
      (_) {
        _isLoading = false;
        _isEmailOtpSent = true;
        notifyListeners();
      },
    );
  }

  void clearEmailVerification() {
    _isEmailOtpSent = false;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> confirmEmailOtp({required String email, required String otp}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final params = VerifyEmailLoginOtpParams(email: email, otp: otp);
    final result = await _verifyEmailLoginOtpUseCase(params);
    result.fold(_handleFailure, _handleLoginSuccess);
  }

  Future<void> loginWithFace({required Uint8List imageBytes}) async {
    _isLoading = true;
    _error = null;
    _isSuccess = false;
    _isFaceMatched = false;
    _matchedUserId = null;
    notifyListeners();

    final params = LoginWithFaceParams(imageBytes: imageBytes);
    final result = await _loginWithFaceUseCase(params);
    result.fold(_handleFailure, _handleFaceVerifySuccess);
  }

  void _handleFailure(Failure failure) {
    _isLoading = false;
    _error = failure.message;
    _isSuccess = false;
    _isFaceMatched = false;
    _matchedUserId = null;
    notifyListeners();
  }

  Future<void> _handleFaceVerifySuccess(FaceVerifyResultEntity result) async {
    _isLoading = false;
    _error = null;
    _isSuccess = false;
    _isFaceMatched = false;
    _matchedUserId = null;

    if (result.token != null) {
      _isSuccess = true;
      _authToken = result.token;

      await TokenService.saveTokens(
        result.token!.accessToken,
        result.token!.refreshToken,
      );
      _apiClient.setAuthToken(result.token!.accessToken);
    } else if (result.matchedUserId != null) {
      _isFaceMatched = true;
      _matchedUserId = result.matchedUserId;
    }

    notifyListeners();
  }

  Future<void> _handleLoginSuccess(
    AuthTokenEntity tokenEntity, {
    bool viaPhone = false,
  }) async {
    _lastLoginViaPhone = viaPhone;
    _isLoading = false;
    _error = null;
    _isSuccess = true;
    _isFaceMatched = false;
    _matchedUserId = null;
    _authToken = tokenEntity;

    await TokenService.saveTokens(
      tokenEntity.accessToken,
      tokenEntity.refreshToken,
    );

    _apiClient.setAuthToken(tokenEntity.accessToken);
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void reset() {
    _isLoading = false;
    _error = null;
    _isSuccess = false;
    _isFaceMatched = false;
    _matchedUserId = null;
    _authToken = null;
    _phoneSession = null;
    _phoneCodeSentAt = null;
    _lastLoginViaPhone = false;
    notifyListeners();
  }
}
