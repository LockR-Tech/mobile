import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:smart_laundry_locker/core/config/env_config.dart';
import 'package:smart_laundry_locker/core/utils/firebase_auth_errors.dart';
import 'package:smart_laundry_locker/firebase_options.dart';

/// Một lần gửi mã OTP SĐT đang chờ người dùng nhập mã.
///
/// Mobile giữ [verificationId] (+ [resendToken] của Android để "Gửi lại mã");
/// web giữ [webConfirmation] của `signInWithPhoneNumber`.
class PhoneCodeSession {
  const PhoneCodeSession({
    required this.phoneNumber,
    this.verificationId,
    this.resendToken,
    this.webConfirmation,
  });

  /// Số E.164 (+84…) đã gửi mã.
  final String phoneNumber;
  final String? verificationId;

  /// `forceResendingToken` Android cấp trong `codeSent` — gửi lại mã kèm token
  /// này để Firebase không coi là yêu cầu mới (tránh bị chặn/reCAPTCHA lại).
  final int? resendToken;
  final ConfirmationResult? webConfirmation;
}

/// Wraps Firebase Auth so phone + Google all yield a single Firebase ID token
/// that the backend verifies via `POST /api/auth/firebase` (lần đầu backend tự
/// tạo tài khoản).
class FirebaseAuthService {
  FirebaseAuthService({FirebaseAuth? auth}) : _auth = auth;

  final FirebaseAuth? _auth;

  // Lấy lười: trên web chưa cấu hình Firebase, `FirebaseAuth.instance` ném
  // `[core/no-app]` — lấy ngay khi tạo service làm hỏng cả màn đăng nhập.
  FirebaseAuth get _firebaseAuth => _auth ?? FirebaseAuth.instance;

  /// Đăng nhập SĐT/Google dùng được trên nền tảng này. Android/iOS luôn có
  /// Firebase; web chỉ khi đã dán cấu hình Web App và Firebase khởi tạo xong.
  static bool get isSupported {
    if (!kIsWeb) return true;
    if (!DefaultFirebaseOptions.isWebConfigured) return false;
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  bool _googleInitialized = false;

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    // google_sign_in v7 requires an explicit initialize() before authenticate().
    // serverClientId (Web client ID) makes Google return an ID token whose
    // audience the backend / Firebase can verify.
    await GoogleSignIn.instance.initialize(
      serverClientId: EnvConfig.googleWebClientId,
    );
    _googleInitialized = true;
  }

  Future<String?> _signInForIdToken(AuthCredential credential) async {
    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    return userCredential.user?.getIdToken();
  }

  /// Google sign-in -> Firebase credential -> Firebase ID token.
  /// Returns null when the user cancels the Google chooser.
  Future<String?> signInWithGoogle() async {
    if (kIsWeb) return _signInWithGooglePopup();
    try {
      await _ensureGoogleInitialized();

      final GoogleSignInAccount googleUser =
          await GoogleSignIn.instance.authenticate();
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final String? googleIdToken = googleAuth.idToken;
      if (googleIdToken == null) {
        throw Exception('Google ID Token is null');
      }

      return await _signInForIdToken(
        GoogleAuthProvider.credential(idToken: googleIdToken),
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return null; // Cancelled by user
      }
      debugPrint('Google Sign In Error: $e');
      rethrow;
    } catch (e) {
      debugPrint('Google Sign In Error: $e');
      rethrow;
    }
  }

  /// Web: google_sign_in không trả ID token qua `authenticate()` ⇒ dùng popup
  /// của Firebase Auth. Người dùng đóng popup ⇒ `null`.
  Future<String?> _signInWithGooglePopup() async {
    try {
      final userCredential = await _firebaseAuth.signInWithPopup(
        GoogleAuthProvider(),
      );
      return await userCredential.user?.getIdToken();
    } on FirebaseAuthException catch (e) {
      if (isFirebaseAuthCancellation(e.code)) return null;
      debugPrint('Google popup sign-in error: ${e.code}');
      rethrow;
    }
  }

  /// Facebook sign-in -> Firebase credential -> Firebase ID token.
  /// Returns null when the user cancels.
  ///
  /// Đang ẩn khỏi giao diện (`FeatureFlags.facebookLoginEnabled`), giữ code để
  /// bật lại khi cần.
  Future<String?> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();
      if (result.status == LoginStatus.cancelled) {
        return null; // Cancelled by user
      }
      final AccessToken? accessToken = result.accessToken;
      if (result.status != LoginStatus.success || accessToken == null) {
        throw Exception('Facebook login failed: ${result.message}');
      }

      return await _signInForIdToken(
        FacebookAuthProvider.credential(accessToken.tokenString),
      );
    } catch (e) {
      debugPrint('Facebook Sign In Error: $e');
      rethrow;
    }
  }

  /// Gửi mã OTP tới [phoneE164] (đã chuẩn hoá +84…).
  ///
  /// - Android/iOS: `verifyPhoneNumber`. [resendFrom] là phiên trước khi bấm
  ///   "Gửi lại mã" — gửi kèm `forceResendingToken`. Android có thể tự xác minh
  ///   (đọc SMS / instant verification) ⇒ [onAutoVerified] nhận luôn Firebase
  ///   ID token, người dùng không phải nhập mã.
  /// - Web: `signInWithPhoneNumber` với reCAPTCHA vô hình (web không hỗ trợ
  ///   luồng `verifyPhoneNumber` như mobile). Không truyền verifier ⇒ FlutterFire
  ///   tự tạo `RecaptchaVerifier` dạng invisible rồi dọn sau khi gửi.
  Future<void> sendPhoneCode({
    required String phoneE164,
    required void Function(PhoneCodeSession session) onCodeSent,
    required void Function(FirebaseAuthException error) onFailed,
    void Function(String idToken)? onAutoVerified,
    PhoneCodeSession? resendFrom,
  }) async {
    if (kIsWeb) {
      try {
        final confirmation = await _firebaseAuth.signInWithPhoneNumber(
          phoneE164,
        );
        onCodeSent(
          PhoneCodeSession(
            phoneNumber: phoneE164,
            webConfirmation: confirmation,
          ),
        );
      } on FirebaseAuthException catch (e) {
        onFailed(e);
      }
      return;
    }

    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneE164,
      forceResendingToken: resendFrom?.resendToken,
      verificationCompleted: (PhoneAuthCredential credential) async {
        if (onAutoVerified == null) return;
        try {
          final idToken = await _signInForIdToken(credential);
          if (idToken != null) onAutoVerified(idToken);
        } on FirebaseAuthException catch (e) {
          onFailed(e);
        } catch (e) {
          debugPrint('Phone auto-verification error: $e');
        }
      },
      verificationFailed: onFailed,
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(
          PhoneCodeSession(
            phoneNumber: phoneE164,
            verificationId: verificationId,
            // iOS không cấp token ⇒ giữ token cũ (nếu có).
            resendToken: resendToken ?? resendFrom?.resendToken,
          ),
        );
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  /// Xác nhận mã OTP của [session] ⇒ Firebase ID token. Mã sai/hết hạn ném
  /// [FirebaseAuthException] (`invalid-verification-code`, `session-expired`…).
  Future<String?> confirmPhoneCode(
    PhoneCodeSession session,
    String smsCode,
  ) async {
    final webConfirmation = session.webConfirmation;
    if (webConfirmation != null) {
      final userCredential = await webConfirmation.confirm(smsCode);
      return userCredential.user?.getIdToken();
    }
    final verificationId = session.verificationId;
    if (verificationId == null) {
      throw FirebaseAuthException(code: 'missing-verification-id');
    }
    return _signInForIdToken(
      PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      ),
    );
  }
}
