import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/core/config/business_config.dart';
import 'package:smart_laundry_locker/core/network/dio_client.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/pages/rent_locker_page.dart';

import '../../helpers/test_helpers.dart';

class _FakeRentLockerOpsService extends LockerOpsService {
  _FakeRentLockerOpsService() : super(dio: createMockDio().dio);

  int? createRentalBoxId;
  int checkoutCalls = 0;
  int confirmDropCalls = 0;
  int unlockCalls = 0;
  int? lastCheckoutOrderId;
  String? lastCheckoutMethod;
  int? lastConfirmOrderId;

  @override
  Future<num> walletBalance() async => 50000;

  @override
  Future<bool> awaitOrderPaid(
    int orderId, {
    Duration timeout = const Duration(seconds: 20),
    Duration interval = const Duration(milliseconds: 1500),
  }) async =>
      checkoutCalls > 0;

  @override
  Future<Map<String, dynamic>> order(int orderId) async => {
        ..._createdOrder,
        'id': orderId,
        'paymentStatus': checkoutCalls > 0 ? 'PAID' : 'UNPAID',
      };

  @override
  Future<Map<String, dynamic>> unlock(int lockerId, int boxId, String pinCode) async {
    unlockCalls++;
    return {'accepted': true, 'nextStep': 'CONFIRM_DROP'};
  }

  final Map<String, dynamic> _createdOrder = {
    'id': 81,
    'type': 'RENTAL',
    'status': 'INITIALIZED',
    'paymentStatus': 'UNPAID',
    'totalPrice': 20000,
    'lockerId': 5,
    'sendBoxId': 5004,
    'pinCode': '490912',
    'qrToken': 'QR-490912',
    'orderCode': 'ORD-81',
    'createdAt': '2026-07-24T09:00:00',
    'pickupDeadline': null,
  };

  @override
  Future<Map<String, dynamic>> createRental({
    required int lockerId,
    required String cellType,
    required int hours,
    String? note,
    String? promotionCode,
    int? boxId,
  }) async {
    createRentalBoxId = boxId;
    return Map.of(_createdOrder);
  }

  @override
  Future<Map<String, dynamic>> checkout(
    int orderId,
    String method, {
    String? bankCode,
    String? returnUrl,
  }) async {
    checkoutCalls++;
    lastCheckoutOrderId = orderId;
    lastCheckoutMethod = method;
    return {
      'id': 991,
      'orderId': orderId,
      'method': method,
      'status': 'COMPLETED',
    };
  }

  @override
  Future<Map<String, dynamic>> confirmDrop(int orderId) async {
    confirmDropCalls++;
    lastConfirmOrderId = orderId;
    return {
      ..._createdOrder,
      'id': orderId,
      'status': 'STORING',
      'paymentStatus': 'UNPAID',
      'pickupDeadline': '2026-07-24T13:00:00',
    };
  }

  @override
  Future<List<Map<String, dynamic>>> paymentsByOrder(int orderId) async {
    if (checkoutCalls > 0) {
      return [
        {
          'id': 991,
          'orderId': orderId,
          'status': 'COMPLETED',
          'amount': 20000,
        }
      ];
    }
    return const [];
  }
}

void main() {
  setUp(() {
    DioClient.instance.init(baseUrl: kTestBaseUrl);
    mockSecureStorage({
      'access_token': makeFakeJwt(sub: '99', roles: ['CUSTOMER']),
    });
    useBusinessConfig();
  });

  testWidgets('hiển thị giá, kích thước ô và giờ thuê theo cấu hình admin', (
    tester,
  ) async {
    useBusinessConfig(
      BusinessConfig.fromPublicMaps(
        order: {
          'app.order.rental-rate-standard': 6000,
          'app.order.rental-rate-xl': 12000,
          'app.order.rental-min-hours': 2,
          'app.order.rental-max-hours': 12,
          'app.order.rental-default-hours': 3,
          'app.order.rental-quick-hours': [3, 6, 48],
          'app.order.pickup-overtime-fee-per-hour': 1000,
          'app.order.pickup-max-overtime-fee': 30000,
          'app.order.pickup-max-overtime-percent': 40,
        },
        locker: {
          'app.locker.cell-dimensions-standard': '40 × 40 × 40 cm',
          'app.locker.cell-dimensions-xl': '60 × 90 × 50 cm',
        },
      ),
    );
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: RentLockerPage(
          initialLockerId: 5,
          initialLockerName: 'Tủ demo',
          service: _FakeRentLockerOpsService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('6.000đ/giờ'), findsOneWidget);
    expect(find.text('12.000đ/giờ'), findsOneWidget);
    expect(find.text('40 × 40 × 40 cm'), findsOneWidget);
    expect(find.text('60 × 90 × 50 cm'), findsOneWidget);
    // Nút nhanh ngoài [min, max] bị bỏ.
    expect(find.text('3h'), findsOneWidget);
    expect(find.text('6h'), findsOneWidget);
    expect(find.text('48h'), findsNothing);
    expect(find.text('3 giờ'), findsOneWidget);
    expect(find.text('18.000đ'), findsOneWidget);

    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.min, 2);
    expect(slider.max, 12);
    expect(
      find.textContaining(
        'Thuê từ 2 đến 12 giờ. Phí quá giờ 1.000đ/giờ '
        '(tối đa 30.000đ và 40% giá trị đơn).',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('6h'));
    await tester.pumpAndSettle();
    expect(find.text('36.000đ'), findsOneWidget);
  });

  testWidgets('pays for real, opens the box, then confirms — never auto-confirms', (
    tester,
  ) async {
    final service = _FakeRentLockerOpsService();

    await tester.pumpWidget(
      MaterialApp(
        home: RentLockerPage(
          initialLockerId: 5,
          initialLockerName: 'Tủ demo',
          locationName: 'Cửa hàng A',
          initialCellType: 'STANDARD',
          initialBoxId: 5004,
          initialBoxNumber: 4,
          service: service,
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Thuê ngay'));
    await tester.pumpAndSettle();

    expect(service.createRentalBoxId, 5004);
    expect(find.textContaining('mở ô số 4'), findsOneWidget);
    expect(find.textContaining('Hết hạn thuê:'), findsNothing);
    // Chưa trả tiền thì chưa có nút mở ô / xác nhận.
    expect(find.text('Mở ô để bỏ đồ'), findsNothing);

    final payButton = find.text('Thanh toán 20.000đ');
    await tester.dragUntilVisible(
      payButton,
      find.byType(Scrollable).first,
      const Offset(0, -300),
    );
    await tester.tap(payButton);
    // Nút hiện spinner suốt lúc bảng chọn mở ⇒ không dùng pumpAndSettle ở đây.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // App khách không tự xác nhận tiền mặt.
    expect(find.text('Tiền mặt'), findsNothing);
    await tester.tap(find.text('Ví của tôi'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(service.checkoutCalls, 1);
    expect(service.lastCheckoutOrderId, 81);
    expect(service.lastCheckoutMethod, 'WALLET');
    expect(service.confirmDropCalls, 0);

    final openButton = find.text('Mở ô để bỏ đồ');
    await tester.dragUntilVisible(
      openButton,
      find.byType(Scrollable).first,
      const Offset(0, -300),
    );
    // SnackBar "Thanh toán thành công" có thể che nút ⇒ gọi thẳng onTap.
    tester
        .widget<InkWell>(find.ancestor(of: openButton, matching: find.byType(InkWell)).first)
        .onTap
        ?.call();
    await tester.pump();
    await tester.pumpAndSettle();
    expect(service.unlockCalls, 1);
    expect(service.confirmDropCalls, 0);

    final confirmButton = find.text('Tôi đã bỏ đồ — bắt đầu kỳ thuê');
    await tester.dragUntilVisible(
      confirmButton,
      find.byType(Scrollable).first,
      const Offset(0, -300),
    );
    final confirmInkWell = tester.widget<InkWell>(
      find.ancestor(of: confirmButton, matching: find.byType(InkWell)).first,
    );
    confirmInkWell.onTap?.call();
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(service.lastConfirmOrderId, 81);
    expect(service.confirmDropCalls, 1);
    expect(find.textContaining('Đã thanh toán'), findsOneWidget);
    expect(find.textContaining('Mock Ví'), findsNothing);
    expect(
      find.textContaining('Hết hạn thuê'),
      findsOneWidget,
    );
  });
}
