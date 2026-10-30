import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/core/routing/notification_deep_link.dart';
import 'package:smart_laundry_locker/core/routing/role_routes.dart';

void main() {
  String? link(
    String? type,
    AppRole role, {
    String? referenceId,
    String? referenceType,
    String? orderId,
  }) => notificationLocation(
    type: type,
    role: role,
    referenceId: referenceId,
    referenceType: referenceType,
    orderId: orderId,
  );

  group('KTV drone', () {
    const role = AppRole.droneTechnician;

    test('phiếu được giao mở "Việc của tôi" và đúng phiếu', () {
      expect(
        link(
          'drone.report.assigned',
          role,
          referenceId: '42',
          referenceType: 'DRONE_REPORT',
        ),
        '/maintenance-home?tab=mine&reportId=42',
      );
    });

    test('phiếu định tuyến mở tab Sự cố, lịch đến hạn mở tab Định kỳ', () {
      expect(
        link('drone.report.routed', role, referenceId: '43'),
        '/maintenance-home?tab=incidents&reportId=43',
      );
      expect(
        link(
          'drone.schedule.due',
          role,
          referenceId: '71',
          referenceType: 'MAINTENANCE_SCHEDULE',
        ),
        '/maintenance-home?tab=schedules&scheduleId=71',
      );
    });

    test('đơn drone mới mở Điều phối kèm id đơn', () {
      expect(
        link('DRONE_ORDER_CREATED', role, referenceId: '21'),
        '/maintenance-home?tab=dispatch&orderId=21',
      );
    });

    test('type cũ của KTV tủ vẫn ở trang KTV drone', () {
      expect(
        link('locker.report.routed', role, referenceId: '5'),
        '/maintenance-home?tab=incidents&reportId=5',
      );
      expect(
        link('locker.schedule.due', role, referenceId: '9'),
        '/maintenance-home?tab=schedules&scheduleId=9',
      );
    });

    test('không bao giờ đưa KTV drone sang trang KTV tủ', () {
      const types = [
        'drone.report.assigned',
        'drone.report.routed',
        'drone.schedule.due',
        'locker.report.assigned',
        'locker.report.routed',
        'locker.schedule.due',
        'DRONE_PARCEL_RECOVERY_ASSIGNED',
        'drone.parcel.recovery.assigned',
        'DRONE_ORDER_CREATED',
        'DRONE_DELIVERY_STATUS_CHANGED',
        'ORDER_STATUS_CHANGED',
        'locker.report.resolved',
        'UNKNOWN',
      ];
      for (final type in types) {
        final location = link(type, role, referenceId: '1');
        expect(
          location == null || location.startsWith('/maintenance-home'),
          isTrue,
          reason: '$type ⇒ $location',
        );
      }
    });

    // KTV drone cũng được giao thu hồi kiện rơi / được báo trạm cần mang kiện tới.
    test('thu hồi kiện rơi và trạm nhận kiện mở tab Sự cố', () {
      for (final type in const [
        'DRONE_PARCEL_RECOVERY_ASSIGNED',
        'DRONE_PARCEL_RECOVERY_STATION',
      ]) {
        expect(
          link(type, role, referenceId: '7', referenceType: 'DRONE_INCIDENT'),
          '/maintenance-home?tab=incidents',
          reason: type,
        );
      }
    });
  });

  group('KTV tủ', () {
    const role = AppRole.lockerTechnician;

    test('phiếu/lịch mở đúng tab kèm id', () {
      expect(
        link('locker.report.routed', role, referenceId: '5'),
        '/technician-home?tab=incidents&reportId=5',
      );
      expect(
        link('LOCKER_REPORT_ROUTED', role, referenceId: '5'),
        '/technician-home?tab=incidents&reportId=5',
      );
      expect(
        link('locker.report.assigned', role, referenceId: '6'),
        '/technician-home?tab=mine&reportId=6',
      );
      expect(
        link('LOCKER_REPORT_ASSIGNED', role, referenceId: '6'),
        '/technician-home?tab=mine&reportId=6',
      );
      expect(
        link('locker.schedule.due', role, referenceId: '9'),
        '/technician-home?tab=schedules&scheduleId=9',
      );
      expect(
        link('LOCKER_SCHEDULE_DUE', role, referenceId: '9'),
        '/technician-home?tab=schedules&scheduleId=9',
      );
    });

    test('giao tủ (referenceType LOCKER) không coi id tủ là id phiếu', () {
      expect(
        link(
          'locker.report.assigned',
          role,
          referenceId: '3',
          referenceType: 'LOCKER',
        ),
        '/technician-home?tab=incidents',
      );
    });

    test('phân công lịch bảo trì mở tab schedules kèm scheduleId', () {
      expect(
        link(
          'locker.report.assigned',
          role,
          referenceId: '15',
          referenceType: 'MAINTENANCE_SCHEDULE',
        ),
        '/technician-home?tab=schedules&scheduleId=15',
      );
    });

    test('thu hồi kiện hàng rơi từ drone mở tab recovery', () {
      expect(
        link('DRONE_PARCEL_RECOVERY_ASSIGNED', role, referenceId: '77'),
        '/technician-home?tab=recovery',
      );
      expect(
        link(
          'UNKNOWN',
          role,
          referenceId: '77',
          referenceType: 'DRONE_PARCEL_INCIDENT',
        ),
        '/technician-home?tab=recovery',
      );
      expect(
        link(
          'DRONE_PARCEL_RECOVERY_STATION',
          role,
          referenceId: '77',
          referenceType: 'DRONE_INCIDENT',
        ),
        '/technician-home?tab=recovery',
      );
    });

    test('đánh giá của khách và báo lỗi ô mở đúng tab', () {
      expect(
        link('locker.report.rated', role, referenceId: '12'),
        '/technician-home?tab=mine&reportId=12',
      );
      expect(
        link('LOCKER_BOX_FAULT', role, referenceId: '88'),
        '/technician-home?tab=incidents&reportId=88',
      );
      expect(
        link('IOT_DEVICE_STATUS_CHANGED', role),
        '/technician-home?tab=devices',
      );
    });

    test('noti của KTV drone không mở trang nào của KTV tủ', () {
      expect(link('drone.report.assigned', role, referenceId: '1'), isNull);
    });
  });

  group('khách', () {
    const role = AppRole.customer;

    test('đơn tủ mở Đơn của tôi kèm id đơn', () {
      expect(
        link(
          'ORDER_STATUS_CHANGED',
          role,
          referenceId: '21',
          referenceType: 'ORDER',
        ),
        '/locker/my-orders?orderId=21',
      );
      expect(
        link('REFUND_COMPLETED', role, referenceId: '8', referenceType: 'ORDER'),
        '/locker/my-orders?orderId=8',
      );
      expect(
        link('FEEDBACK_REPLY', role, referenceId: '8', referenceType: 'ORDER'),
        '/locker/my-orders?orderId=8',
      );
      expect(
        link('order.status.changed', role, referenceId: '4'),
        '/locker/my-orders?orderId=4',
      );
    });

    test('mốc chặng giao drone mở màn theo dõi drone', () {
      expect(
        link(
          'ORDER_STATUS_CHANGED',
          role,
          referenceId: '21',
          referenceType: 'DELIVERY',
        ),
        '/drone-delivery?orderId=21',
      );
      expect(
        link('DRONE_DELIVERY_STATUS_CHANGED', role, referenceId: '22'),
        '/drone-delivery?orderId=22',
      );
      expect(
        link('DRONE_PARCEL_DROP_REPORTED', role, orderId: '23'),
        '/drone-delivery?orderId=23',
      );
      // Thông báo sự cố cho khách tham chiếu ĐƠN (referenceType DRONE_ORDER).
      expect(
        link(
          'DRONE_PARCEL_RECOVERY_VERIFIED',
          role,
          referenceId: '24',
          referenceType: 'DRONE_ORDER',
        ),
        '/drone-delivery?orderId=24',
      );
      expect(link('DRONE_DELIVERY_STATUS_CHANGED', role), isNull);
    });

    test('phiếu sự cố mở Báo cáo của tôi', () {
      expect(
        link('locker.report.resolved', role, referenceId: '3'),
        '/locker/my-reports?reportId=3',
      );
    });

    test('được ủy quyền lấy hộ mở Đơn ủy quyền', () {
      expect(
        link('ORDER_DELEGATED_TO_YOU', role, referenceId: '12'),
        '/my-delegations?orderId=12',
      );
    });

    test('khuyến mãi và type lạ', () {
      expect(link('OPEN_PROMOTION_TAB', role), '/promotions');
      expect(link('SOMETHING_NEW', role, referenceId: '1'), isNull);
      expect(link('drone.report.assigned', role, referenceId: '1'), isNull);
    });
  });

  test('ADMIN không có màn đích trên mobile', () {
    expect(link('ORDER_STATUS_CHANGED', AppRole.admin, referenceId: '1'), isNull);
  });

  test('trang chủ KTV mở thay stack, màn khác được đẩy lên', () {
    expect(isRoleHomeLocation('/maintenance-home?tab=mine&reportId=1'), isTrue);
    expect(isRoleHomeLocation('/technician-home'), isTrue);
    expect(isRoleHomeLocation('/locker/my-orders?orderId=1'), isFalse);
  });

  test('primaryRole theo thứ tự ưu tiên', () {
    expect(primaryRole(const ['DRONE_TECHNICIAN']), AppRole.droneTechnician);
    expect(primaryRole(const ['ROLE_DRONE_TECHNICIAN']), AppRole.droneTechnician);
    expect(
      primaryRole(const ['DRONE_TECHNICIAN', 'LOCKER_TECHNICIAN']),
      AppRole.lockerTechnician,
    );
    expect(primaryRole(const ['CUSTOMER']), AppRole.customer);
    expect(primaryRole(const ['ADMIN', 'CUSTOMER']), AppRole.admin);
  });
}
