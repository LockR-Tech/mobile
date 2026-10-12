import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/order_payment_sheet.dart';

import '../../helpers/test_helpers.dart';

class _FakePayService extends LockerOpsService {
  _FakePayService({this.qrCodeUrl}) : super(dio: createMockDio().dio);

  final String? qrCodeUrl;
  int checkoutCalls = 0;
  String? lastMethod;
  bool paid = false;

  @override
  Future<num> walletBalance() async => 0;

  @override
  Future<Map<String, dynamic>> checkout(
    int orderId,
    String method, {
    String? bankCode,
    String? returnUrl,
    String? description,
  }) async {
    checkoutCalls++;
    lastMethod = method;
    return {
      'id': 1,
      'orderId': orderId,
      'method': method,
      'status': 'PENDING',
      if (qrCodeUrl != null) 'qrCodeUrl': qrCodeUrl,
      'content': 'LOCKR 42',
    };
  }

  @override
  Future<bool> orderStatus(int orderId) async => paid;

  @override
  Future<bool> awaitOrderPaid(
    int orderId, {
    Duration timeout = const Duration(seconds: 60),
    Duration interval = const Duration(milliseconds: 1500),
  }) async => paid;
}

Widget _host(_FakePayService service, void Function(Object?) onResult) =>
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              try {
                onResult(
                  await payOrderAndAwaitPaid(
                    context,
                    service: service,
                    orderId: 42,
                    total: 15000,
                    enabledMethods: const ['SEPAY'],
                  ),
                );
              } catch (e) {
                onResult(e);
              }
            },
            child: const Text('Trả'),
          ),
        ),
      ),
    );

void main() {
  group('checkoutQrUrl', () {
    test('lấy qrCodeUrl của response, không tự dựng', () {
      expect(
        checkoutQrUrl({'qrCodeUrl': 'https://img.vietqr.io/image/x.jpg'}),
        'https://img.vietqr.io/image/x.jpg',
      );
      expect(checkoutQrUrl({'qr': 'https://qr.example/1.png'}), isNotNull);
      expect(checkoutQrUrl({}), isNull);
      expect(checkoutQrUrl({'qrCodeUrl': ''}), isNull);
      expect(checkoutQrUrl({'qrCodeUrl': 'không phải url'}), isNull);
    });
  });

  testWidgets('SePay: đúng một checkout cho một lần trả, hiện mã của server', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final service = _FakePayService(
      qrCodeUrl: 'https://img.vietqr.io/image/x.jpg',
    );
    Object? result;
    await tester.pumpWidget(_host(service, (r) => result = r));

    await tester.tap(find.text('Trả'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SePay (VietQR)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(service.checkoutCalls, 1);
    expect(service.lastMethod, 'SEPAY');
    expect(find.text('Quét mã VietQR để thanh toán'), findsOneWidget);
    expect(find.text('Nội dung: LOCKR 42'), findsOneWidget);
    final image = tester.widget<Image>(
      find
          .descendant(of: find.byType(ClipRRect), matching: find.byType(Image))
          .first,
    );
    expect(
      (image.image as NetworkImage).url,
      'https://img.vietqr.io/image/x.jpg',
    );

    // Tiền về: sheet tự đóng, kết quả "đã thanh toán", không checkout thêm.
    service.paid = true;
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(result, OrderPaymentOutcome.paid);
    expect(service.checkoutCalls, 1);
  });

  testWidgets(
    'SePay không trả mã QR ⇒ báo lỗi, không dùng tài khoản viết sẵn',
    (tester) async {
      final service = _FakePayService();
      Object? result;
      await tester.pumpWidget(_host(service, (r) => result = r));

      await tester.tap(find.text('Trả'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('SePay (VietQR)'));
      await tester.pumpAndSettle();

      expect(service.checkoutCalls, 1);
      expect(result, isA<LockerOpsException>());
      expect(
        LockerOpsService.errorMessage(result!),
        contains('chưa trả mã VietQR'),
      );
      expect(find.text('Quét mã VietQR để thanh toán'), findsNothing);
    },
  );
}
