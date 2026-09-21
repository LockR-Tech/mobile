import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/core/config/business_config.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/pages/my_locker_orders_page.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';

import '../../helpers/test_helpers.dart';

class _FakeLockerOpsService extends LockerOpsService {
  _FakeLockerOpsService() : super(dio: createMockDio().dio);

  @override
  Future<List<Map<String, dynamic>>> myOrders() async => [
    {
      'id': 21,
      'type': 'DRONE_DELIVERY',
      'status': 'ACCEPTED',
      'deliveryStage': 'ACCEPTED',
      'paymentStatus': 'UNPAID',
      'pinCode': '123456',
      'qrToken': 'QR-123',
      'lockerId': 5,
      'orderCode': 'ORD-21',
      'createdAt': '2026-07-15T09:00:00',
    },
  ];

  @override
  Future<Map<String, dynamic>> locker(int lockerId) async => {
    'id': lockerId,
    'name': 'Tủ demo',
  };

  @override
  Future<Map<String, dynamic>> layout(int lockerId) async => {
    'cells': [
      {'id': 5001, 'boxNumber': 1},
    ],
  };

  @override
  Future<List<Map<String, dynamic>>> myReports() async => const [];
}

class _FakeRentalExtendLockerOpsService extends LockerOpsService {
  _FakeRentalExtendLockerOpsService() : super(dio: createMockDio().dio);

  final Map<String, dynamic> _order = {
    'id': 31,
    'type': 'RENTAL',
    'status': 'STORING',
    'paymentStatus': 'PAID',
    'totalPrice': 10000,
    'pickupDeadline': '2026-07-15T12:00:00',
    'lockerId': 5,
    'sendBoxId': 5001,
    'pinCode': '654321',
    'orderCode': 'ORD-31',
    'createdAt': '2026-07-15T09:00:00',
  };

  @override
  Future<List<Map<String, dynamic>>> myOrders() async => [Map.of(_order)];

  @override
  Future<Map<String, dynamic>> locker(int lockerId) async => {
    'id': lockerId,
    'name': 'Tủ thuê',
  };

  @override
  Future<Map<String, dynamic>> layout(int lockerId) async => {
    'cells': [
      {'id': 5001, 'boxNumber': 8},
    ],
  };

  int? lastExtendHours;

  @override
  Future<Map<String, dynamic>> extendRental(int orderId, int hours) async {
    lastExtendHours = hours;
    _order['paymentStatus'] = 'UNPAID';
    _order['totalPrice'] = (_order['totalPrice'] as int) + 5000 * hours;
    return Map.of(_order);
  }

  @override
  Future<List<Map<String, dynamic>>> myReports() async => const [];
}

class _FakeFaultyOrderLockerOpsService extends LockerOpsService {
  _FakeFaultyOrderLockerOpsService() : super(dio: createMockDio().dio);

  int reportOrderFaultCalls = 0;
  int reportFaultCalls = 0;

  @override
  Future<List<Map<String, dynamic>>> myOrders() async => [
    {
      'id': 41,
      'type': 'SEND',
      'status': 'INITIALIZED',
      'paymentStatus': 'UNPAID',
      'totalPrice': 15000,
      'lockerId': 7,
      'sendBoxId': 7003,
      'pinCode': '888999',
      'orderCode': 'ORD-41',
      'createdAt': '2026-07-15T09:00:00',
    },
  ];

  @override
  Future<Map<String, dynamic>> locker(int lockerId) async => {
    'id': lockerId,
    'name': 'Tủ lỗi',
  };

  @override
  Future<Map<String, dynamic>> layout(int lockerId) async => {
    'cells': [
      {'id': 7003, 'boxNumber': 3},
    ],
  };

  @override
  Future<List<Map<String, dynamic>>> myReports() async => [
    {
      'id': 901,
      'boxId': 7003,
      'boxNumber': 3,
      'lockerId': 7,
      'status': 'OPEN',
      'description': 'Kẹt cửa',
    },
  ];

  @override
  Future<Map<String, dynamic>> reportOrderFault(
    int orderId,
    String reason, {
    List<Map<String, dynamic>>? attachments,
  }) async {
    reportOrderFaultCalls++;
    return {'id': orderId, 'reason': reason};
  }

  @override
  Future<Map<String, dynamic>> reportFault(
    int boxId,
    String reason, {
    List<Map<String, dynamic>>? attachments,
  }) async {
    reportFaultCalls++;
    return {'boxId': boxId, 'reason': reason};
  }
}

class _FakeRentalCompletionLockerOpsService extends LockerOpsService {
  _FakeRentalCompletionLockerOpsService() : super(dio: createMockDio().dio);

  int endRentalCalls = 0;

  @override
  Future<List<Map<String, dynamic>>> myOrders() async => [
    {
      'id': 51,
      'type': 'RENTAL',
      'status': 'STORING',
      'paymentStatus': 'PAID',
      'totalPrice': 25000,
      'pickupDeadline': '2026-07-15T12:00:00',
      'lockerId': 9,
      'sendBoxId': 9002,
      'pinCode': '112233',
      'qrToken': 'QR-RENTAL-51',
      'orderCode': 'ORD-51',
      'createdAt': '2026-07-15T09:00:00',
    },
  ];

  @override
  Future<Map<String, dynamic>> locker(int lockerId) async => {
    'id': lockerId,
    'name': 'Tủ thuê kiosk',
  };

  @override
  Future<Map<String, dynamic>> layout(int lockerId) async => {
    'cells': [
      {'id': 9002, 'boxNumber': 12},
    ],
  };

  @override
  Future<List<Map<String, dynamic>>> myReports() async => const [];

  @override
  Future<Map<String, dynamic>> endRental(int orderId) async {
    endRentalCalls++;
    return {'id': orderId};
  }
}

void main() {
  setUp(() {
    mockSecureStorage({
      'access_token': makeFakeJwt(sub: '99', roles: ['CUSTOMER']),
    });
    useBusinessConfig();
  });

  testWidgets('chỉ hiện phương thức thanh toán admin đang bật', (tester) async {
    useBusinessConfig(
      BusinessConfig.fromPublicMaps(
        payment: {'app.payment.enabled-methods': 'VNPAY,CASH'},
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(390, 844)),
          child: MyLockerOrdersPage(service: _FakeFaultyOrderLockerOpsService()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tủ lỗi'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Thanh toán 15.000đ'));
    await tester.tap(find.text('Thanh toán 15.000đ'));
    await tester.pumpAndSettle();

    expect(find.text('Chọn phương thức thanh toán'), findsOneWidget);
    expect(find.text('VNPay'), findsOneWidget);
    expect(find.text('Tiền mặt'), findsOneWidget);
    expect(find.text('Ví của tôi'), findsNothing);
    expect(find.text('MoMo'), findsNothing);
  });

  testWidgets('gia hạn dùng số giờ mặc định và tối đa theo cấu hình admin', (
    tester,
  ) async {
    useBusinessConfig(
      BusinessConfig.fromPublicMaps(
        order: {
          'app.order.extend-default-hours': 3,
          'app.order.extend-max-hours': 6,
        },
      ),
    );
    final service = _FakeRentalExtendLockerOpsService();

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(390, 844)),
          child: MyLockerOrdersPage(service: service),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tủ thuê'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Gia hạn thuê'));
    await tester.tap(find.text('Gia hạn thuê'));
    await tester.pumpAndSettle();

    expect(find.text('Thêm 3 giờ'), findsOneWidget);
    expect(find.text('Tối đa 6 giờ mỗi lần gia hạn'), findsOneWidget);
    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.min, 1);
    expect(slider.max, 6);

    await tester.tap(find.text('Gia hạn'));
    await tester.pumpAndSettle();

    expect(service.lastExtendHours, 3);
  });

  testWidgets('drone order header fits a narrow screen and hides unpaid credentials', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(320, 640)),
          child: MyLockerOrdersPage(service: _FakeLockerOpsService()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Header thẻ đơn: mã đơn co lại bằng ellipsis, nhãn trạng thái luôn hiện đủ —
    // ở 320px không được tràn (RenderFlex overflow sẽ thành exception).
    expect(find.text('Đã tiếp nhận'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Tủ demo'));
    await tester.pumpAndSettle();

    expect(find.byType(AccessCredentials), findsNothing);
  });

  testWidgets('shows pay action after extending a previously paid rental', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(390, 844)),
          child: MyLockerOrdersPage(
            service: _FakeRentalExtendLockerOpsService(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tủ thuê'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Gia hạn thuê'));
    expect(find.text('Gia hạn thuê'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(OpsPrimaryButton),
        matching: find.textContaining('Thanh toán'),
      ),
      findsNothing,
    );

    await tester.ensureVisible(find.text('Gia hạn thuê'));
    await tester.tap(find.text('Gia hạn thuê'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Gia hạn'));
    await tester.tap(find.text('Gia hạn'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tủ thuê'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(OpsPrimaryButton),
        matching: find.textContaining('Thanh toán'),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'shows a fault warning for an order whose box was reported faulty',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(390, 844)),
            child: MyLockerOrdersPage(
              service: _FakeFaultyOrderLockerOpsService(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ô số 3 đã được báo lỗi.'), findsOneWidget);
      expect(find.text('Hãy hủy đơn này và đặt ô khác.'), findsOneWidget);
    },
  );

  testWidgets('reports fault through the order endpoint from order detail', (
    tester,
  ) async {
    final service = _FakeFaultyOrderLockerOpsService();
    useBusinessConfig(
      BusinessConfig.fromPublicMaps(
        locker: {'app.maintenance.report-photos-per-request-reporter': 3},
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(390, 844)),
          child: MyLockerOrdersPage(service: service),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tủ lỗi'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Báo ô lỗi'));
    await tester.tap(find.text('Báo ô lỗi'));
    await tester.pumpAndSettle();

    // Giới hạn ảnh hiện trường lấy từ cấu hình admin.
    expect(
      find.text('Ảnh hiện trường (không bắt buộc, tối đa 3)'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField).last, 'Ô không mở được');
    await tester.tap(find.text('Gửi báo lỗi'));
    await tester.pumpAndSettle();

    expect(service.reportOrderFaultCalls, 1);
    expect(service.reportFaultCalls, 0);
  });

  testWidgets('hides direct open action and stages rental completion', (
    tester,
  ) async {
    final service = _FakeRentalCompletionLockerOpsService();

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(390, 844)),
          child: MyLockerOrdersPage(service: service),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tủ thuê kiosk'));
    await tester.pumpAndSettle();

    expect(find.text('Mở tủ'), findsNothing);
    expect(find.text('Kết thúc thuê & lấy đồ'), findsOneWidget);

    await tester.ensureVisible(find.text('Kết thúc thuê & lấy đồ'));
    await tester.tap(find.text('Kết thúc thuê & lấy đồ'));
    await tester.pumpAndSettle();

    expect(find.text('Lấy đồ tại kiosk'), findsOneWidget);
    expect(
      find.textContaining('Dùng mã này tại kiosk để mở ô'),
      findsOneWidget,
    );
    expect(service.endRentalCalls, 0);

    await tester.ensureVisible(find.text('Đã lấy đồ và đóng tủ'));
    await tester.tap(find.text('Đã lấy đồ và đóng tủ'));
    await tester.pumpAndSettle();

    expect(service.endRentalCalls, 1);
  });

  testWidgets(
    'shows direct open locker button for paid drop-off and storing orders',
    (tester) async {
      final service = _FakePaidDropOrderLockerOpsService();

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(390, 844)),
            child: MyLockerOrdersPage(service: service),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Đơn mới hơn (ORD-62, STORING) hiển thị trước
      await tester.tap(find.text('Tủ kiểm thử').first);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.textContaining('để lấy đồ'));
      expect(find.textContaining('để lấy đồ'), findsOneWidget);

      // Đóng sheet
      Navigator.of(tester.element(find.textContaining('để lấy đồ'))).pop();
      await tester.pumpAndSettle();

      // Đơn cũ hơn (ORD-61, INITIALIZED) hiển thị sau
      await tester.tap(find.text('Tủ kiểm thử').last);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.textContaining('để bỏ đồ'));
      expect(find.textContaining('để bỏ đồ'), findsOneWidget);
    },
  );

  testWidgets('shows direct mobile open option in rental completion sheet', (
    tester,
  ) async {
    final service = _FakeRentalCompletionLockerOpsService();

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(390, 844)),
          child: MyLockerOrdersPage(service: service),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tủ thuê kiosk'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Kết thúc thuê & lấy đồ'));
    await tester.tap(find.text('Kết thúc thuê & lấy đồ'));
    await tester.pumpAndSettle();

    expect(find.text('Lấy đồ tại kiosk'), findsOneWidget);
    expect(find.textContaining('trên điện thoại'), findsOneWidget);
  });

  testWidgets(
    'prioritizes receiveBox and destinationLocker for multi-locker storing pickup',
    (tester) async {
      final service = _FakeMultiLockerTransferOpsService();

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(390, 844)),
            child: MyLockerOrdersPage(service: service),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tủ đích'));
      await tester.pumpAndSettle();

      // Phải chọn đúng ô nhận (ô số 8 tại tủ đích), không lấy nhầm ô gửi (ô số 1 tại tủ gửi)
      expect(find.text('Mở Ô số 8 để lấy đồ'), findsOneWidget);
    },
  );

  testWidgets(
    'allows free order with 0 vnd to open box for drop-off even when unpaid',
    (tester) async {
      final service = _FakeFreeOrderLockerOpsService();

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(390, 844)),
            child: MyLockerOrdersPage(service: service),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tủ miễn phí'));
      await tester.pumpAndSettle();

      expect(find.text('Mở Ô số 5 để bỏ đồ'), findsOneWidget);
    },
  );
}

class _FakePaidDropOrderLockerOpsService extends LockerOpsService {
  _FakePaidDropOrderLockerOpsService() : super(dio: createMockDio().dio);

  @override
  Future<List<Map<String, dynamic>>> myOrders() async => [
    {
      'id': 61,
      'type': 'SEND',
      'status': 'INITIALIZED',
      'paymentStatus': 'PAID',
      'totalPrice': 15000,
      'lockerId': 7,
      'sendBoxId': 7003,
      'pinCode': '123456',
      'orderCode': 'ORD-61',
      'createdAt': '2026-07-15T09:00:00',
    },
    {
      'id': 62,
      'type': 'SEND',
      'status': 'STORING',
      'paymentStatus': 'PAID',
      'totalPrice': 15000,
      'lockerId': 7,
      'receiveBoxId': 7003,
      'pinCode': '654321',
      'orderCode': 'ORD-62',
      'createdAt': '2026-07-15T10:00:00',
    },
  ];

  @override
  Future<Map<String, dynamic>> locker(int lockerId) async => {
    'id': lockerId,
    'name': 'Tủ kiểm thử',
    'code': 'LOC-07',
    'latitude': 10.8231,
    'longitude': 106.6297,
  };

  @override
  Future<Map<String, dynamic>> layout(int lockerId) async => {
    'cells': [
      {'id': 7003, 'boxNumber': 3},
    ],
  };

  @override
  Future<List<Map<String, dynamic>>> myReports() async => const [];

  @override
  Future<Map<String, dynamic>> unlock(
    int lockerId,
    int boxId,
    String pinCode,
  ) async => {'accepted': true, 'message': 'Unlocked successfully'};
}

class _FakeMultiLockerTransferOpsService extends LockerOpsService {
  _FakeMultiLockerTransferOpsService() : super(dio: createMockDio().dio);

  @override
  Future<List<Map<String, dynamic>>> myOrders() async => [
    {
      'id': 71,
      'type': 'SEND',
      'status': 'STORING',
      'paymentStatus': 'PAID',
      'totalPrice': 20000,
      'lockerId': 1,
      'destinationLockerId': 2,
      'sendBoxId': 101,
      'receiveBoxId': 202,
      'pinCode': '998877',
      'orderCode': 'ORD-71',
      'createdAt': '2026-07-15T09:00:00',
    },
  ];

  @override
  Future<Map<String, dynamic>> locker(int lockerId) async => {
    'id': lockerId,
    'name': lockerId == 1 ? 'Tủ gửi' : 'Tủ đích',
    'code': lockerId == 1 ? 'LOC-01' : 'LOC-02',
    'latitude': 10.8000,
    'longitude': 106.6000,
  };

  @override
  Future<Map<String, dynamic>> layout(int lockerId) async => {
    'cells': lockerId == 1
        ? [{'id': 101, 'boxNumber': 1}]
        : [{'id': 202, 'boxNumber': 8}],
  };

  @override
  Future<List<Map<String, dynamic>>> myReports() async => const [];
}

class _FakeFreeOrderLockerOpsService extends LockerOpsService {
  _FakeFreeOrderLockerOpsService() : super(dio: createMockDio().dio);

  @override
  Future<List<Map<String, dynamic>>> myOrders() async => [
    {
      'id': 81,
      'type': 'SEND',
      'status': 'INITIALIZED',
      'paymentStatus': 'UNPAID',
      'totalPrice': 0,
      'paymentRequired': false,
      'lockerId': 3,
      'sendBoxId': 305,
      'pinCode': '111222',
      'orderCode': 'ORD-81',
      'createdAt': '2026-07-15T09:00:00',
    },
  ];

  @override
  Future<Map<String, dynamic>> locker(int lockerId) async => {
    'id': lockerId,
    'name': 'Tủ miễn phí',
    'code': 'LOC-03',
  };

  @override
  Future<Map<String, dynamic>> layout(int lockerId) async => {
    'cells': [
      {'id': 305, 'boxNumber': 5},
    ],
  };

  @override
  Future<List<Map<String, dynamic>>> myReports() async => const [];
}

