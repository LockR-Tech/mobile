import 'dart:typed_data';

import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/core/services/token_service.dart';
import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:smart_laundry_locker/features/auth/domain/entities/face_verify_result_entity.dart';
import 'package:smart_laundry_locker/features/auth/application/use_cases/confirm_qr_login_use_case.dart';
import 'package:smart_laundry_locker/features/auth/application/use_cases/login_use_case.dart';
import 'package:smart_laundry_locker/features/auth/application/use_cases/login_with_face_use_case.dart';
import 'package:smart_laundry_locker/features/auth/application/use_cases/social_login_use_case.dart';
import 'package:smart_laundry_locker/features/auth/application/use_cases/send_email_login_otp_use_case.dart';
import 'package:smart_laundry_locker/features/auth/application/use_cases/verify_email_login_otp_use_case.dart';
import 'package:smart_laundry_locker/core/services/firebase_auth_service.dart';
import 'package:smart_laundry_locker/features/auth/domain/entities/auth_token_entity.dart';
import 'package:smart_laundry_locker/features/auth/infrastructure/utils/qr_session_id_parser.dart';
import 'package:flutter/foundation.dart';

class LoginProvider extends ChangeNotifier {
  final LoginUseCase _loginUseCase;
  final LoginWithFaceUseCase _loginWithFaceUseCase;
  final ConfirmQrLoginUseCase _confirmQrLoginUseCase;
  final SocialLoginUseCase _socialLoginUseCase;
  final SendEmailLoginOtpUseCase _sendEmailLoginOtpUseCase;
  final VerifyEmailLoginOtpUseCase _verifyEmailLoginOtpUseCase;
  final FirebaseAuthService _firebaseAuthService;
  final ApiClient _apiClient;

  LoginProvider({
    required LoginUseCase loginUseCase,
    required LoginWithFaceUseCase loginWithFaceUseCase,
    required ConfirmQrLoginUseCase confirmQrLoginUseCase,
    required SocialLoginUseCase socialLoginUseCase,
    required SendEmailLoginOtpUseCase sendEmailLoginOtpUseCase,
    required VerifyEmailLoginOtpUseCase verifyEmailLoginOtpUseCase,
    required FirebaseAuthService firebaseAuthService,
    required ApiClient apiClient,
  }) : _loginUseCase = loginUseCase,
       _loginWithFaceUseCase = loginWithFaceUseCase,
       _confirmQrLoginUseCase = confirmQrLoginUseCase,
       _socialLoginUseCase = socialLoginUseCase,
       _sendEmailLoginOtpUseCase = sendEmailLoginOtpUseCase,
       _verifyEmailLoginOtpUseCase = verifyEmailLoginOtpUseCase,
       _firebaseAuthService = firebaseAuthService,
       _apiClient = apiClient;

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

  bool _isQrConfirmLoading = false;
  bool get isQrConfirmLoading => _isQrConfirmLoading;

  bool? _qrConfirmSuccess;
  bool? get qrConfirmSuccess => _qrConfirmSuccess;

  String? _qrError;
  String? get qrError => _qrError;

  Future<void> onQrScanned(String qrRawContent) async {
    _isQrConfirmLoading = true;
    _qrError = null;
    _qrConfirmSuccess = null;
    notifyListeners();

    final sessionId = parseQrSessionId(qrRawContent);
    if (sessionId == null || sessionId.isEmpty) {
      _isQrConfirmLoading = false;
      _qrError = 'Không đọc được mã phiên từ QR. Vui lòng thử mã khác.';
      notifyListeners();
      return;
    }

    final result = await _confirmQrLoginUseCase(
      ConfirmQrLoginParams(sessionId: sessionId),
    );

    result.fold(_handleQrFailure, (ok) {
      _isQrConfirmLoading = false;
      _qrConfirmSuccess = ok;
      _qrError = ok ? null : 'Xác nhận thất bại.';
      notifyListeners();
    });
  }

  void _handleQrFailure(Failure failure) {
    _isQrConfirmLoading = false;
    _qrConfirmSuccess = false;
    if (failure is QrExpiredFailure) {
      _qrError = failure.message;
    } else if (failure is QrAlreadyUsedFailure) {
      _qrError = failure.message;
    } else if (failure is AuthenticationFailure) {
      _qrError = failure.message;
    } else {
      _qrError = failure.message;
    }
    notifyListeners();
  }

  void clearQrLoginState() {
    _isQrConfirmLoading = false;
    _qrConfirmSuccess = null;
    _qrError = null;
    notifyListeners();
  }

  Future<void> login({required String email, required String password}) async {
    _isLoading = true;
    _error = null;
    _isSuccess = false;
    notifyListeners();

    final params = LoginParams.fromForm(email: email, password: password);

    final result = await _loginUseCase(params);

    result.fold(_handleFailure, _handleLoginSuccess);
  }

  String? _verificationId;
  String? get verificationId => _verificationId;

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
    } catch (e) {
      _isLoading = false;
      _error = 'Đăng nhập Google thất bại';
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
      _error = 'Đăng nhập Facebook thất bại';
      notifyListeners();
    }
  }

  Future<void> sendPhoneOtp(String phoneNumber) async {
    _isLoading = true;
    _error = null;
    _verificationId = null;
    notifyListeners();

    try {
      await _firebaseAuthService.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        codeSent: (String verId) {
          _verificationId = verId;
          _isLoading = false;
          notifyListeners();
        },
        verificationFailed: (String error) {
          _error = error;
          _isLoading = false;
          notifyListeners();
        },
        autoVerified: (String idToken) async {
          // Instant verification: finish the social login automatically.
          final result = await _socialLoginUseCase(idToken);
          result.fold(_handleFailure, _handleLoginSuccess);
        },
      );
    } catch (e) {
      _isLoading = false;
      _error = 'Lỗi gửi mã OTP';
      notifyListeners();
    }
  }

  /// Clears any in-progress phone verification so a freshly opened OTP dialog
  /// starts at the "enter phone number" step.
  void clearPhoneVerification() {
    _verificationId = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> confirmPhoneOtp(String smsCode) async {
    if (_verificationId == null) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final idToken = await _firebaseAuthService.confirmOtp(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );
      if (idToken == null) {
        _isLoading = false;
        _error = 'Mã xác nhận không đúng';
        notifyListeners();
        return;
      }
      final result = await _socialLoginUseCase(idToken);
      result.fold(_handleFailure, _handleLoginSuccess);
    } catch (e) {
      _isLoading = false;
      _error = 'Mã xác nhận không đúng hoặc đã hết hạn';
      notifyListeners();
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

  Future<void> _handleLoginSuccess(AuthTokenEntity tokenEntity) async {
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
    _verificationId = null;
    _isQrConfirmLoading = false;
    _qrConfirmSuccess = null;
    _qrError = null;
    notifyListeners();
  }
}
