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

    group('TECHNICIAN (locker maintenance + IoT)', () {
      test('TECHNICIAN routes to /technician-home', () {
        expect(homeForRoles(['TECHNICIAN']), equals('/technician-home'));
      });
      test('TECHNICIAN beats CUSTOMER', () {
        expect(
          homeForRoles(['CUSTOMER', 'TECHNICIAN']),
          equals('/technician-home'),
        );
      });
    });

    group('MAINTENANCE (drone fleet)', () {
      test('MAINTENANCE routes to /maintenance-home', () {
        expect(homeForRoles(['MAINTENANCE']), equals('/maintenance-home'));
      });
      test('TECHNICIAN beats MAINTENANCE', () {
        expect(
          homeForRoles(['MAINTENANCE', 'TECHNICIAN']),
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
    });
  });
}
