import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/core/network/dio_client.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/pages/rent_locker_page.dart';

import '../../helpers/test_helpers.dart';

class _FakeRentLockerOpsService extends LockerOpsService {
  _FakeRentLockerOpsService() : super(dio: createMockDio().dio);

  int? createRentalBoxId;
  int checkoutCalls = 0;
  int confirmDropCalls = 0;
  int? lastCheckoutOrderId;
  int? lastConfirmOrderId;

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
  });

  testWidgets('preserves selected box, does not auto-confirm after payment, and hides deadline before start', (
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

    final payButton = find.textContaining('Đã thanh toán');
    await tester.dragUntilVisible(
      payButton,
      find.byType(Scrollable).first,
      const Offset(0, -300),
    );
    await tester.tap(payButton);
    await tester.pumpAndSettle();

    expect(service.checkoutCalls, 1);
    expect(service.lastCheckoutOrderId, 81);
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
