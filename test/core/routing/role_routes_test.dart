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

  group('technician notification routing', () {
    test('ticket routed to my locker opens the incidents tab', () {
      expect(
        technicianRouteForNotification('locker.report.routed'),
        equals('/technician-home?tab=incidents'),
      );
    });

    test('ticket assigned to me opens "Việc của tôi"', () {
      expect(
        technicianRouteForNotification(
          'locker.report.assigned',
          referenceType: 'LOCKER_REPORT',
        ),
        equals('/technician-home?tab=mine'),
      );
      expect(
        technicianRouteForNotification('locker.report.assigned'),
        equals('/technician-home?tab=mine'),
      );
    });

    test('locker assigned to me opens the incidents tab', () {
      expect(
        technicianRouteForNotification(
          'locker.report.assigned',
          referenceType: 'LOCKER',
        ),
        equals('/technician-home?tab=incidents'),
      );
    });

    test('due schedule opens the schedules tab', () {
      expect(
        technicianRouteForNotification('locker.schedule.due'),
        equals('/technician-home?tab=schedules'),
      );
    });

    test('other notifications are not technician routes', () {
      expect(technicianRouteForNotification('locker.report.resolved'), isNull);
      expect(technicianRouteForNotification('ORDER_STATUS_CHANGED'), isNull);
      expect(technicianRouteForNotification(null), isNull);
    });

    test('tab query maps to tab index, unknown falls back to first tab', () {
      expect(technicianTabIndex('incidents'), 1);
      expect(technicianTabIndex('mine'), 2);
      expect(technicianTabIndex('schedules'), 3);
      expect(technicianTabIndex('nope'), 0);
      expect(technicianTabIndex(null), 0);
    });
  });
}
