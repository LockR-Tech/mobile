import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/core/routing/role_routes.dart';

void main() {
  group('homeForRoles', () {
    group('ADMIN (web-only console)', () {
      test('ADMIN routes to /admin-web-notice', () {
        expect(homeForRoles(['ADMIN']), equals('/admin-web-notice'));
      });
      test('ADMIN+CUSTOMER routes to /admin-web-notice (ADMIN wins)', () {
        expect(
          homeForRoles(['CUSTOMER', 'ADMIN']),
          equals('/admin-web-notice'),
        );
      });
      test('ADMIN does NOT land on customer home', () {
        expect(homeForRoles(['ADMIN']), isNot(equals('/home')));
      });
    });

    group('LOCKER_TECHNICIAN (kỹ thuật viên tủ: locker maintenance + IoT)', () {
      test('LOCKER_TECHNICIAN routes to /technician-home', () {
        expect(
          homeForRoles(['LOCKER_TECHNICIAN']),
          equals('/technician-home'),
        );
      });
      test('LOCKER_TECHNICIAN beats CUSTOMER', () {
        expect(
          homeForRoles(['CUSTOMER', 'LOCKER_TECHNICIAN']),
          equals('/technician-home'),
        );
      });
    });

    group('DRONE_TECHNICIAN (kỹ thuật viên drone: drone fleet)', () {
      test('DRONE_TECHNICIAN routes to /maintenance-home', () {
        expect(
          homeForRoles(['DRONE_TECHNICIAN']),
          equals('/maintenance-home'),
        );
      });
      test('LOCKER_TECHNICIAN beats DRONE_TECHNICIAN', () {
        expect(
          homeForRoles(['DRONE_TECHNICIAN', 'LOCKER_TECHNICIAN']),
          equals('/technician-home'),
        );
      });
    });

    group('customer fallback', () {
      test('CUSTOMER routes to /home', () {
        expect(homeForRoles(['CUSTOMER']), equals('/home'));
      });
      test('empty roles routes to /home', () {
        expect(homeForRoles([]), equals('/home'));
      });
      test('unknown role routes to /home', () {
        expect(homeForRoles(['UNKNOWN']), equals('/home'));
      });
      test('retired roles MANAGER/STAFF fall back to /home', () {
        expect(homeForRoles(['MANAGER']), equals('/home'));
        expect(homeForRoles(['STAFF']), equals('/home'));
      });
      test('tên role cũ trước khi đổi không còn được chấp nhận', () {
        expect(homeForRoles(['TECHNICIAN']), equals('/home'));
        expect(homeForRoles(['MAINTENANCE']), equals('/home'));
      });
    });
  });

  group('requiresSignIn', () {
    test('trợ lý hỏi đáp và lịch sử cần đăng nhập', () {
      expect(requiresSignIn('/assistant'), isTrue);
      expect(requiresSignIn('/assistant/history'), isTrue);
    });

    test('giữ các màn cần đăng nhập sẵn có', () {
      expect(requiresSignIn('/transactions'), isTrue);
      expect(requiresSignIn('/top-up'), isTrue);
    });

    test('màn công khai không bị chặn', () {
      expect(requiresSignIn('/'), isFalse);
      expect(requiresSignIn('/onboarding'), isFalse);
      expect(requiresSignIn('/home'), isFalse);
      expect(requiresSignIn('/assistant-foo'), isFalse);
    });
  });
}
