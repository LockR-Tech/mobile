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

  group('technician notification routing', () {
    test('parcel recovery assignment opens recovery tab', () {
      expect(
        technicianRouteForNotification('DRONE_PARCEL_RECOVERY_ASSIGNED'),
        '/technician-home?tab=recovery',
      );
      expect(technicianTabIndex('recovery'), 5);
    });
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

  group('requiresSignIn — màn cần đăng nhập', () {
    test('gửi/thuê tủ, đơn, báo sự cố, thông báo, ủy quyền, ưu đãi đã lưu', () {
      for (final path in const [
        '/locker/send-parcel',
        '/locker/rent',
        '/locker/my-orders',
        '/locker/my-reports',
        '/maintenance/create-report',
        '/notifications',
        '/my-delegations',
        '/my-vouchers',
        '/drone-delivery',
        '/maintenance-home',
        '/technician-home',
        '/drone/flight-data',
      ]) {
        expect(requiresSignIn(path), isTrue, reason: path);
      }
    });

    test('trang chủ, cửa hàng, khuyến mãi vẫn công khai', () {
      for (final path in const ['/home', '/stores', '/promotions', '/policy']) {
        expect(requiresSignIn(path), isFalse, reason: path);
      }
    });
  });

  group('routeRedirect — chặn theo vai trò', () {
    String? redirect(String location, List<String> roles, {bool signedIn = true}) =>
        routeRedirect(Uri.parse(location), signedIn: signedIn, roles: roles);

    test('chưa đăng nhập ⇒ màn đăng nhập thay vì lỗi 401', () {
      expect(redirect('/locker/send-parcel', const [], signedIn: false),
          '/onboarding');
      expect(redirect('/maintenance-home', const [], signedIn: false),
          '/onboarding');
      expect(redirect('/home', const [], signedIn: false), isNull);
    });

    test('khách không vào được trang KTV và công cụ bay', () {
      const roles = ['CUSTOMER'];
      expect(redirect('/technician-home', roles), '/home');
      expect(redirect('/maintenance-home', roles), '/home');
      expect(redirect('/technician-profile', roles), '/home');
      expect(redirect('/drone/flight-data', roles), '/home');
      expect(redirect('/drone/mission-planner', roles), '/home');
      expect(redirect('/locker/my-orders', roles), isNull);
    });

    test('KTV drone bị đưa từ trang KTV tủ sang trang của mình, giữ tab chung', () {
      const roles = ['DRONE_TECHNICIAN'];
      expect(redirect('/maintenance-home?tab=mine&reportId=7', roles), isNull);
      expect(redirect('/drone/flight-data', roles), isNull);
      expect(redirect('/technician-profile', roles), isNull);
      expect(
        redirect('/technician-home?tab=mine&reportId=7', roles),
        '/maintenance-home?tab=mine&reportId=7',
      );
      expect(redirect('/technician-home?tab=recovery', roles),
          '/maintenance-home');
    });

    test('KTV tủ không vào trang KTV drone và công cụ bay', () {
      const roles = ['LOCKER_TECHNICIAN'];
      expect(redirect('/technician-home?tab=incidents', roles), isNull);
      expect(
        redirect('/maintenance-home?tab=schedules&scheduleId=3', roles),
        '/technician-home?tab=schedules&scheduleId=3',
      );
      expect(redirect('/maintenance-home?tab=dispatch&orderId=9', roles),
          '/technician-home');
      expect(redirect('/drone/flight-data', roles), '/technician-home');
    });

    test('ADMIN được đưa về thông báo dùng web', () {
      expect(redirect('/maintenance-home', const ['ADMIN']), '/admin-web-notice');
      expect(redirect('/technician-home', const ['ADMIN']), '/admin-web-notice');
    });
  });

  group('deep link trang KTV drone', () {
    test('tab theo tên, tên lạ về Điều phối', () {
      expect(maintenanceTabIndex('dispatch'), 0);
      expect(maintenanceTabIndex('fleet'), 1);
      expect(maintenanceTabIndex('incidents'), 2);
      expect(maintenanceTabIndex('mine'), 3);
      expect(maintenanceTabIndex('schedules'), 4);
      expect(maintenanceTabIndex('tools'), 5);
      expect(maintenanceTabIndex('recovery'), 0);
      expect(maintenanceTabIndex(null), 0);
    });

    test('id trong query phải là số dương', () {
      expect(queryId(const {'reportId': '42'}, 'reportId'), 42);
      expect(queryId(const {'reportId': 'abc'}, 'reportId'), isNull);
      expect(queryId(const {'reportId': '0'}, 'reportId'), isNull);
      expect(queryId(const {}, 'reportId'), isNull);
    });

    test('ticket routed with an id carries reportId', () {
      expect(
        technicianRouteForNotification(
          'locker.report.routed',
          referenceId: '5',
        ),
        '/technician-home?tab=incidents&reportId=5',
      );
    });
  });
}
