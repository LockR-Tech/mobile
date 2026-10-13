import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/pages/my_locker_orders_page.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/pickup_code_share_actions.dart';

import '../../helpers/test_helpers.dart';

/// Đơn của tôi: một đơn gửi đang nằm trong ô (STORING, đã trả tiền).
class _FakeService extends LockerOpsService {
  _FakeService({this.incomingError}) : super(dio: createMockDio().dio);

  final Object? incomingError;
  int delegateCalls = 0;
  String? delegatedPhone;
  int resetPinCalls = 0;

  @override
  Future<List<Map<String, dynamic>>> myOrders() async => [
    {
      'id': 61,
      'type': 'SEND',
      'status': 'STORING',
      'paymentStatus': 'PAID',
      'totalPrice': 15000,
      'lockerId': 7,
      'receiveBoxId': 7003,
      'pinCode': '654321',
      'orderCode': 'ORD-61',
      'createdAt': '2026-07-15T10:00:00',
      'userId': 99,
      'receiverName': 'Lê Bình',
      'receiverPhone': '0912000111',
    },
  ];

  @override
  Future<Map<String, dynamic>> locker(int lockerId) async => {
    'id': lockerId,
    'name': 'Tủ kiểm thử',
    'code': 'CAB-TU01',
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
  Future<List<Map<String, dynamic>>> incomingOrders({
    bool activeOnly = false,
    int? limit,
  }) async {
    final error = incomingError;
    if (error != null) throw error;
    return [
      {
        'id': 90,
        'orderCode': 'ORD-90',
        'type': 'SEND',
        'status': 'STORING',
        'senderName': 'Nguyễn An',
        'lockerId': 7,
        'lockerCode': 'CAB-TU01',
        'lockerName': 'Tủ thư viện',
        'boxNumber': 2,
        'readyForPickup': true,
        'pickupPin': '246810',
        'createdAt': '2026-07-16T10:00:00',
      },
    ];
  }

  @override
  Future<Map<String, dynamic>> delegate(
    int orderId, {
    required String phone,
    String? name,
    String? note,
  }) async {
    delegateCalls++;
    delegatedPhone = phone;
    return {'id': orderId, 'receiverPhone': phone};
  }

  @override
  Future<Map<String, dynamic>> resetPin(int orderId) async {
    resetPinCalls++;
    return {'id': orderId, 'pinCode': '111222'};
  }
}

Future<void> _pump(WidgetTester tester, LockerOpsService service) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(size: Size(390, 844)),
        child: MyLockerOrdersPage(service: service),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    mockSecureStorage({
      'access_token': makeFakeJwt(sub: '99', roles: ['CUSTOMER']),
    });
    useBusinessConfig();
  });

  testWidgets('mục Hàng chờ nhận hiện đơn gửi tới mình kèm mã lấy hàng', (
    tester,
  ) async {
    await _pump(tester, _FakeService());

    // Tab có huy hiệu đếm đơn đang chờ lấy.
    expect(find.text('Hàng chờ nhận'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    await tester.tap(find.text('Hàng chờ nhận'));
    await tester.pumpAndSettle();

    expect(find.text('#ORD-90'), findsOneWidget);
    expect(find.text('Nguyễn An'), findsOneWidget);
    expect(find.text('Mở ô số 2 lấy hàng'), findsOneWidget);
    final creds = tester.widget<AccessCredentials>(
      find.byType(AccessCredentials),
    );
    expect(creds.pin, '246810');
    // Đơn của chính mình không lẫn vào mục này.
    expect(find.text('#ORD-61'), findsNothing);
    // Mình là người nhận: không có nút chia sẻ mã cho người nhận.
    expect(find.text('Chia sẻ mã cho người nhận'), findsNothing);
    expect(find.byType(PickupCodeShareActions), findsNothing);
  });

  testWidgets('người gửi chia sẻ mã nhận hàng từ chi tiết đơn gửi đã vào ô', (
    tester,
  ) async {
    await _pump(tester, _FakeService());

    await tester.tap(find.text('Tủ kiểm thử'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Chia sẻ mã cho người nhận'));
    expect(find.text('Chia sẻ mã cho người nhận'), findsOneWidget);
    expect(find.text('Nhắn SMS'), findsOneWidget);
    expect(find.text('Sao chép tin nhắn'), findsOneWidget);
    final share = tester
        .widget<PickupCodeShareActions>(find.byType(PickupCodeShareActions))
        .share;
    expect(share.receiverPhone, '0912000111');
    expect(
      share.message,
      'Lock.R: Bạn có kiện hàng gửi tới tủ Tủ kiểm thử. Ô số 3. '
      'Mã lấy hàng: 654321. Nhập mã tại màn hình tủ (kiosk) để mở ô.',
    );
  });

  testWidgets(
    'máy chủ chưa có endpoint ⇒ báo rõ, không treo, không bịa dữ liệu',
    (tester) async {
      final notDeployed = DioException(
        requestOptions: RequestOptions(path: '/api/orders/incoming'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/orders/incoming'),
          statusCode: 404,
          data: {'status': 404, 'error': 'Not Found'},
        ),
      );
      await _pump(tester, _FakeService(incomingError: notDeployed));

      await tester.tap(find.text('Hàng chờ nhận'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Máy chủ chưa hỗ trợ mục Hàng chờ nhận'),
        findsOneWidget,
      );
      expect(find.text('Thử lại'), findsOneWidget);
      // Đơn của mình vẫn tải bình thường.
      await tester.tap(find.text('Đơn của tôi'));
      await tester.pumpAndSettle();
      expect(find.text('#ORD-61'), findsOneWidget);
    },
  );

  testWidgets('ủy quyền lấy hộ từ chi tiết đơn gọi POST /delegate', (
    tester,
  ) async {
    final service = _FakeService();
    await _pump(tester, service);

    await tester.tap(find.text('Tủ kiểm thử'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Ủy quyền lấy hộ'));
    await tester.tap(find.text('Ủy quyền lấy hộ'));
    await tester.pumpAndSettle();

    // SĐT sai ⇒ báo lỗi tại chỗ, chưa gọi server.
    await tester.enterText(find.byType(TextField).first, '0909');
    await tester.tap(find.text('Ủy quyền'));
    await tester.pumpAndSettle();
    expect(service.delegateCalls, 0);
    expect(find.textContaining('số điện thoại hợp lệ'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '0909123456');
    await tester.tap(find.text('Ủy quyền'));
    await tester.pumpAndSettle();
    expect(service.delegateCalls, 1);
    expect(service.delegatedPhone, '0909123456');
  });

  testWidgets('đổi mã PIN hỏi xác nhận rồi gọi POST /reset-pin', (
    tester,
  ) async {
    final service = _FakeService();
    await _pump(tester, service);

    await tester.tap(find.text('Tủ kiểm thử'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Đổi mã PIN'));
    await tester.tap(find.text('Đổi mã PIN'));
    await tester.pumpAndSettle();

    expect(find.text('Đổi mã PIN?'), findsOneWidget);
    await tester.tap(find.text('Đổi mã'));
    await tester.pumpAndSettle();
    expect(service.resetPinCalls, 1);
    expect(find.text('Đã đổi mã PIN mới: 111222'), findsOneWidget);
  });
}
