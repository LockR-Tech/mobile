import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/sepay_payment.dart';
import 'package:smart_laundry_locker/features/payment/domain/sepay_transfer.dart';

import '../../helpers/test_helpers.dart';

class _FakeService extends LockerOpsService {
  _FakeService({this.response = const {}}) : super(dio: createMockDio().dio);

  Map<String, dynamic> response;
  final checkoutMethods = <String>[];
  String? lastDescription;
  int statusCalls = 0;
  bool paid = false;

  @override
  Future<Map<String, dynamic>> checkout(
    int orderId,
    String method, {
    String? bankCode,
    String? returnUrl,
    String? description,
  }) async {
    checkoutMethods.add(method);
    lastDescription = description;
    return {'orderId': orderId, 'method': method, ...response};
  }

  @override
  Future<bool> orderStatus(int orderId) async {
    statusCalls++;
    return paid;
  }
}

const _qrResponse = {
  'status': 'PENDING',
  'qrCodeUrl':
      'https://img.vietqr.io/image/970422-0123456789-compact2.jpg?amount=15000&addInfo=LKR7&accountName=LOCKR',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('chỉ gửi SEPAY và chỉ tạo checkout một lần dù start() gọi nhiều lần', () async {
    final service = _FakeService(response: _qrResponse);
    final controller = SepayPaymentController(
      service: service,
      orderId: 7,
      amount: 15000,
      description: 'Phí quá hạn',
    );
    addTearDown(controller.dispose);

    await Future.wait([controller.start(), controller.start()]);
    await controller.start();
    await controller.retry(); // đã có mã ⇒ không tạo lại

    expect(service.checkoutMethods, ['SEPAY']);
    expect(service.lastDescription, 'Phí quá hạn');
    expect(controller.transfer?.transferContent, 'LKR7');
    expect(controller.transfer?.amount, 15000);
    expect(controller.error, isNull);
  });

  test('server không trả mã ⇒ báo lỗi; chỉ "Thử lại" mới tạo giao dịch mới', () async {
    final service = _FakeService(response: {'status': 'PENDING'});
    final controller = SepayPaymentController(
      service: service,
      orderId: 7,
      amount: 15000,
    );
    addTearDown(controller.dispose);

    await controller.start();
    expect(controller.transfer, isNull);
    expect(controller.error, contains('chưa trả mã VietQR'));

    service.response = _qrResponse;
    await controller.retry();
    expect(service.checkoutMethods, ['SEPAY', 'SEPAY']);
    expect(controller.transfer, isA<SepayTransfer>());
    expect(controller.error, isNull);
  });

  test('cổng báo FAILED ⇒ gatewayFailed', () async {
    final service = _FakeService(response: {'status': 'FAILED'});
    final controller = SepayPaymentController(
      service: service,
      orderId: 7,
      amount: 15000,
    );
    addTearDown(controller.dispose);

    await controller.start();
    expect(controller.gatewayFailed, isTrue);
    expect(controller.transfer, isNull);
  });

  testWidgets('hỏi trạng thái ~3 s/lần và khi app quay lại; PAID thì dừng hỏi', (
    tester,
  ) async {
    final service = _FakeService(response: _qrResponse);
    final controller = SepayPaymentController(
      service: service,
      orderId: 7,
      amount: 15000,
    );
    addTearDown(controller.dispose);

    await controller.start();
    expect(service.statusCalls, 0);

    await tester.pump(const Duration(seconds: 3));
    expect(service.statusCalls, 1);
    expect(controller.paid, isFalse);

    // Khách chuyển khoản trong app ngân hàng rồi quay lại app.
    service.paid = true;
    controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await tester.pump();
    expect(controller.paid, isTrue);
    final calls = service.statusCalls;

    await tester.pump(const Duration(seconds: 9));
    expect(service.statusCalls, calls);
    expect(service.checkoutMethods, ['SEPAY']);
  });

  testWidgets('dựng lại khung QR nhiều lần không tạo thêm checkout', (tester) async {
    final service = _FakeService(response: _qrResponse);
    final controller = SepayPaymentController(
      service: service,
      orderId: 7,
      amount: 15000,
    );
    await controller.start();

    for (var i = 0; i < 3; i++) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              key: ValueKey(i),
              child: Column(
                children: [
                  SepayQrSection(controller: controller),
                  SepayPaymentActions(controller: controller),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    expect(find.text('Quét mã VietQR để thanh toán'), findsOneWidget);
    expect(find.text('LKR7'), findsOneWidget);
    expect(service.checkoutMethods, ['SEPAY']);
    await tester.pumpWidget(const SizedBox());
    // Huỷ trong thân test: bộ hỏi trạng thái định kỳ phải dừng trước khi test kết thúc.
    controller.dispose();
  });
}
