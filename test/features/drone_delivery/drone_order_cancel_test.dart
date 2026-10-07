import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/widgets/drone_order_cancel.dart';

void main() {
  Future<void> pumpTrigger(
    WidgetTester tester, {
    required Future<Map<String, dynamic>> Function(int orderId) cancelOrder,
    required void Function(String? message) onResult,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async => onResult(
            await confirmAndCancelDroneOrder(
              context,
              orderId: 77,
              orderCode: 'ORD-1',
              isPaid: true,
              totalPrice: 15000,
              cancelOrder: cancelOrder,
            ),
          ),
          child: const Text('mở'),
        ),
      ),
    ),
  );

  testWidgets('giữ đơn thì không gọi huỷ', (tester) async {
    var calls = 0;
    String? result = 'chưa chạy';
    await pumpTrigger(
      tester,
      cancelOrder: (_) async {
        calls++;
        return {};
      },
      onResult: (message) => result = message,
    );

    await tester.tap(find.text('mở'));
    await tester.pumpAndSettle();
    expect(find.textContaining('15.000đ sẽ được hoàn bằng chuyển khoản'), findsOneWidget);
    await tester.tap(find.text('Giữ đơn'));
    await tester.pumpAndSettle();

    expect(calls, 0);
    expect(result, isNull);
  });

  testWidgets('xác nhận huỷ: báo theo trạng thái hoàn tiền server trả về', (
    tester,
  ) async {
    final results = <String?>[];
    var paymentStatus = 'REFUND_PENDING';
    await pumpTrigger(
      tester,
      cancelOrder: (orderId) async {
        expect(orderId, 77);
        return {'status': 'CANCELED', 'paymentStatus': paymentStatus};
      },
      onResult: results.add,
    );

    for (final status in ['REFUND_PENDING', 'REFUNDED', 'PAID', 'UNPAID']) {
      paymentStatus = status;
      await tester.tap(find.text('mở'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Huỷ đơn'));
      await tester.pumpAndSettle();
    }

    expect(results, [
      'Đã huỷ đơn. Yêu cầu hoàn tiền đã được ghi nhận, admin sẽ chuyển khoản cho bạn.',
      'Đã huỷ đơn. Tiền đã được chuyển khoản hoàn cho bạn.',
      'Đã huỷ đơn. Chưa ghi nhận được yêu cầu hoàn tiền, vui lòng liên hệ hỗ trợ.',
      'Đã huỷ đơn.',
    ]);
  });
}
