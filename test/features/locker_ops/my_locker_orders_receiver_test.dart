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

  int detailCalls = 0;

  @override
  Future<Map<String, dynamic>> receiverOrderDetail(
    int orderId, {
    bool delegated = false,
  }) async {
    detailCalls++;
    return {
      'id': orderId,
      'orderCode': 'ORD-90',
      'type': 'SEND',
      'status': 'STORING',
      'viewerRole': 'RECEIVER',
      'senderName': 'Nguyễn An',
      'senderPhone': '0900000010',
      'lockerId': 7,
      'lockerName': 'Tủ thư viện',
      'boxNumber': 2,
      'boxSize': 'SMALL',
      'readyForPickup': true,
      'pickupPin': '246810',
      'parcel': {'description': 'Hộp quà sinh nhật'},
    };
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

  int resendEmailCalls = 0;
  String? resentEmail;

  @override
  Future<Map<String, dynamic>> sendReceiverEmail(
    int orderId, {
    String? email,
  }) async {
    resendEmailCalls++;
    resentEmail = email;
    return {
      'maskedEmail': 'mo***@example.com',
      'includesPickupCode': true,
      'sentAt': '2026-10-31T21:30:00',
    };
  }
}

/// Đơn gửi vừa tạo, chưa trả tiền: người nhận chưa được báo.
class _UnpaidSendService extends _FakeService {
  @override
  Future<List<Map<String, dynamic>>> myOrders() async {
    final base = (await super.myOrders()).single;
    return [
      {
        ...base,
        'status': 'INITIALIZED',
        'paymentStatus': 'UNPAID',
        'sendBoxId': 7003,
        'receiverEmail': 'binh@example.com',
      },
    ];
  }
}

/// Đơn của tôi có đủ phần chi tiết mới của OrderResponse.
class _RichSenderService extends _FakeService {
  @override
  Future<List<Map<String, dynamic>>> myOrders() async {
    final base = (await super.myOrders()).single;
    return [
      {
        ...base,
        'receiverEmail': 'binh@example.com',
        'delegateName': 'Chị Hoa',
        'delegatePhone': '0933444555',
        'delegateNote': 'Lấy giúp em',
        'delegatedAt': '2026-07-15T12:00:00',
        'paidAt': '2026-07-15T10:02:00',
        'parcel': {
          'description': 'Hộp bánh',
          'weightGrams': 1500,
          'fragile': true,
        },
        'milestones': [
          {
            'code': 'CREATED',
            'label': 'Đơn được tạo',
            'occurredAt': '2026-07-15T10:00:00',
          },
          {
            'code': 'STORED',
            'label': 'Hàng đã vào ô, chờ lấy',
            'occurredAt': '2026-07-15T10:30:00',
          },
        ],
      },
    ];
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

  testWidgets('gửi lại thông tin cho người nhận: sửa được email rồi gọi '
      'POST /receiver-email', (tester) async {
    final service = _FakeService();
    await _pump(tester, service);

    await tester.tap(find.text('Tủ kiểm thử'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Gửi lại thông tin cho người nhận'));
    await tester.tap(find.text('Gửi lại thông tin cho người nhận'));
    await tester.pumpAndSettle();

    // Hàng đã vào tủ ⇒ thư kèm mã; đơn chưa có email ⇒ phải nhập.
    expect(find.textContaining('gửi lại mã mở tủ hiện tại'), findsOneWidget);
    await tester.tap(find.text('Gửi email'));
    await tester.pumpAndSettle();
    expect(find.text('Nhập email người nhận'), findsOneWidget);
    expect(service.resendEmailCalls, 0);

    await tester.enterText(
      find.byKey(const ValueKey('resend-receiver-email-field')),
      'moi@example.com',
    );
    await tester.tap(find.text('Gửi email'));
    await tester.pumpAndSettle();
    expect(service.resendEmailCalls, 1);
    expect(service.resentEmail, 'moi@example.com');
    expect(find.text('Đã gửi lại mã mở tủ tới mo***@example.com.'), findsOneWidget);
  });

  testWidgets('đơn gửi chưa thanh toán ⇒ chưa có nút gửi lại cho người nhận', (
    tester,
  ) async {
    await _pump(tester, _UnpaidSendService());

    await tester.tap(find.text('Tủ kiểm thử'));
    await tester.pumpAndSettle();
    expect(find.text('Gửi lại thông tin cho người nhận'), findsNothing);
  });

  testWidgets('đơn đã ủy quyền lấy hộ ⇒ không có nút gửi lại cho người nhận', (
    tester,
  ) async {
    await _pump(tester, _RichSenderService());

    await tester.tap(find.text('Tủ kiểm thử'));
    await tester.pumpAndSettle();
    expect(find.text('Gửi lại thông tin cho người nhận'), findsNothing);
  });

  testWidgets('chạm đơn trong Hàng chờ nhận mở màn chi tiết đầy đủ', (
    tester,
  ) async {
    final service = _FakeService();
    await _pump(tester, service);

    await tester.tap(find.text('Hàng chờ nhận'));
    await tester.pumpAndSettle();
    expect(find.text('#ORD-90'), findsOneWidget);

    await tester.tap(find.text('#ORD-90'));
    await tester.pumpAndSettle();

    expect(service.detailCalls, 1);
    expect(find.text('Chi tiết đơn nhận'), findsOneWidget);
    final scroll = find.byType(Scrollable).first;
    for (final text in ['0900000010', 'Nhỏ (S)', 'Hộp quà sinh nhật']) {
      await tester.scrollUntilVisible(find.text(text), 200, scrollable: scroll);
      expect(find.text(text), findsOneWidget);
    }
  });

  testWidgets('chi tiết Đơn của tôi có kiện hàng, ủy quyền, mốc thời gian', (
    tester,
  ) async {
    await _pump(tester, _RichSenderService());

    await tester.tap(find.text('Tủ kiểm thử'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Email người nhận'));
    expect(find.text('binh@example.com'), findsOneWidget);
    expect(find.text('Ủy quyền lấy hộ cho'), findsOneWidget);
    expect(find.text('Chị Hoa · 0933444555'), findsOneWidget);
    expect(find.text('Lấy giúp em'), findsOneWidget);
    expect(find.text('Thanh toán lúc'), findsOneWidget);

    await tester.ensureVisible(find.text('Hộp bánh'));
    expect(find.text('Kiện hàng'), findsOneWidget);
    expect(find.text('1,5 kg'), findsOneWidget);
    expect(find.text('Có — nhẹ tay'), findsOneWidget);

    await tester.ensureVisible(find.text('Mốc thời gian'));
    expect(find.text('Đơn được tạo'), findsOneWidget);
    expect(find.text('Hàng đã vào ô, chờ lấy'), findsOneWidget);
    // Mã và nút chia sẻ của người gửi vẫn còn.
    await tester.ensureVisible(find.text('Chia sẻ mã cho người nhận'));
    expect(find.text('Chia sẻ mã cho người nhận'), findsOneWidget);
  });

  testWidgets('đơn cũ không có phần chi tiết ⇒ không hiện mục rỗng', (
    tester,
  ) async {
    await _pump(tester, _FakeService());

    await tester.tap(find.text('Tủ kiểm thử'));
    await tester.pumpAndSettle();

    expect(find.text('Kiện hàng'), findsNothing);
    expect(find.text('Mốc thời gian'), findsNothing);
    expect(find.text('Sự cố giao hàng'), findsNothing);
    expect(find.text('Ủy quyền lấy hộ cho'), findsNothing);
  });

  testWidgets('tab Hàng chờ nhận có các badge bộ lọc và phân loại theo ngày', (
    tester,
  ) async {
    final service = _FakeService();
    await _pump(tester, service);

    await tester.tap(find.text('Hàng chờ nhận'));
    await tester.pumpAndSettle();

    // Verify filter badges are present
    expect(find.text('Tất cả'), findsOneWidget);
    expect(find.text('Chờ lấy'), findsOneWidget);

    // Verify order and date grouping are present
    expect(find.text('#ORD-90'), findsOneWidget);
    // Since ORD-90 createdAt is 2026-07-16, it displays formatted date
    expect(find.textContaining('tháng 7'), findsWidgets);

    // Tap on 'Hoàn thành' filter badge which has 0 items
    await tester.ensureVisible(find.text('Hoàn thành'));
    await tester.tap(find.text('Hoàn thành'));
    await tester.pumpAndSettle();

    // Order should not be visible under completed filter
    expect(find.text('#ORD-90'), findsNothing);

    // Tap back to 'Tất cả'
    await tester.ensureVisible(find.text('Tất cả'));
    await tester.tap(find.text('Tất cả'));
    await tester.pumpAndSettle();
    expect(find.text('#ORD-90'), findsOneWidget);
  });
}
