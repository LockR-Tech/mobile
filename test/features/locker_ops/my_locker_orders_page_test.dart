import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

  @override
  Future<Map<String, dynamic>> extendRental(int orderId, int hours) async {
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
    String reason,
  ) async {
    reportOrderFaultCalls++;
    return {'id': orderId, 'reason': reason};
  }

  @override
  Future<Map<String, dynamic>> reportFault(int boxId, String reason) async {
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
  });

  testWidgets('wraps drone order header and hides unpaid credentials', (
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

    expect(
      find.ancestor(of: find.text('Đã tiếp nhận'), matching: find.byType(Wrap)),
      findsOneWidget,
    );

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
    expect(find.textContaining('Thanh toán'), findsNothing);

    await tester.ensureVisible(find.text('Gia hạn thuê'));
    await tester.tap(find.text('Gia hạn thuê'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Gia hạn'));
    await tester.tap(find.text('Gia hạn'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tủ thuê'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Thanh toán'), findsOneWidget);
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
}
