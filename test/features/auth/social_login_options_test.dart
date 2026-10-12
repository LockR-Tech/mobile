import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/core/config/feature_flags.dart';
import 'package:smart_laundry_locker/features/auth/presentation/widgets/social_login_options.dart';
import 'package:smart_laundry_locker/firebase_options.dart';

void main() {
  test('Facebook bị ẩn theo quyết định chủ sản phẩm', () {
    expect(FeatureFlags.facebookLoginEnabled, isFalse);
    expect(SocialLoginOptions.current().facebook, isFalse);
  });

  test('Android/iOS: hiện Google + SĐT, Facebook theo cờ', () {
    final hidden = SocialLoginOptions.resolve(
      isWeb: false,
      firebaseReady: true,
      facebookEnabled: false,
    );
    expect(hidden.google, isTrue);
    expect(hidden.phone, isTrue);
    expect(hidden.facebook, isFalse);

    final enabled = SocialLoginOptions.resolve(
      isWeb: false,
      firebaseReady: true,
      facebookEnabled: true,
    );
    expect(enabled.facebook, isTrue);
  });

  test('web chưa cấu hình Firebase ⇒ ẩn mọi nút, chỉ còn đăng nhập email', () {
    final options = SocialLoginOptions.resolve(
      isWeb: true,
      firebaseReady: false,
      facebookEnabled: true,
    );
    expect(options.any, isFalse);
  });

  test('web đã cấu hình ⇒ Google + SĐT, không Facebook', () {
    final options = SocialLoginOptions.resolve(
      isWeb: true,
      firebaseReady: true,
      facebookEnabled: true,
    );
    expect(options.google, isTrue);
    expect(options.phone, isTrue);
    expect(options.facebook, isFalse);
  });

  test('isWebConfigured chỉ true khi apiKey/appId web không còn PASTE_…', () {
    const web = DefaultFirebaseOptions.web;
    expect(
      DefaultFirebaseOptions.isWebConfigured,
      !web.apiKey.startsWith('PASTE_') && !web.appId.startsWith('PASTE_'),
    );
    // Cùng project với Android (backend xác minh token của project này).
    expect(web.projectId, DefaultFirebaseOptions.android.projectId);
  });
}
