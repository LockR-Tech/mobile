import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:smart_laundry_locker/core/config/feature_flags.dart';
import 'package:smart_laundry_locker/core/services/firebase_auth_service.dart';

/// Các nút "Hoặc tiếp tục với" được hiện ở màn đăng nhập/đăng ký.
class SocialLoginOptions {
  const SocialLoginOptions({
    required this.google,
    required this.facebook,
    required this.phone,
  });

  /// Quy tắc hiển thị (hàm thuần để test):
  /// - Google, SĐT cần Firebase: web chỉ khi đã cấu hình Web App ([firebaseReady]).
  /// - Facebook ẩn theo [facebookEnabled] (`FeatureFlags.facebookLoginEnabled`)
  ///   và không có trên web (chưa cấu hình Facebook JS SDK).
  factory SocialLoginOptions.resolve({
    required bool isWeb,
    required bool firebaseReady,
    required bool facebookEnabled,
  }) {
    return SocialLoginOptions(
      google: firebaseReady,
      facebook: facebookEnabled && firebaseReady && !isWeb,
      phone: firebaseReady,
    );
  }

  /// Theo nền tảng đang chạy.
  factory SocialLoginOptions.current() => SocialLoginOptions.resolve(
    isWeb: kIsWeb,
    firebaseReady: FirebaseAuthService.isSupported,
    facebookEnabled: FeatureFlags.facebookLoginEnabled,
  );

  final bool google;
  final bool facebook;
  final bool phone;

  /// Không còn nút nào ⇒ ẩn luôn dòng "Hoặc tiếp tục với".
  bool get any => google || facebook || phone;
}
