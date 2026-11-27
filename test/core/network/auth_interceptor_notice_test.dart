import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/core/network/auth_interceptor.dart';

/// "Phiên đăng nhập hết hạn" chỉ báo một lần dù nhiều request cùng 401 (F3-G15).
void main() {
  setUp(AuthInterceptor.resetNotice);

  test('nhiều 401 liền nhau chỉ hiện một thông báo', () {
    var shown = 0;
    final t0 = DateTime(2026, 11, 27, 9);
    for (var i = 0; i < 5; i++) {
      AuthInterceptor.sessionExpiredNotice(
        showToast: () => shown++,
        now: t0.add(Duration(seconds: i)),
      );
    }
    expect(shown, 1);
  });

  test('hết phiên lần sau (quá 30 giây) thì báo lại', () {
    var shown = 0;
    final t0 = DateTime(2026, 11, 27, 9);
    AuthInterceptor.sessionExpiredNotice(showToast: () => shown++, now: t0);
    AuthInterceptor.sessionExpiredNotice(
      showToast: () => shown++,
      now: t0.add(const Duration(seconds: 31)),
    );
    expect(shown, 2);
  });
}
