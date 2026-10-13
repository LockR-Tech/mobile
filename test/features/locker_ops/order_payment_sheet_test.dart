import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/order_payment_sheet.dart';

import '../../helpers/test_helpers.dart';

class _FakePayService extends LockerOpsService {
  _FakePayService({this.qrCodeUrl, this.bankTransfer})
    : super(dio: createMockDio().dio);

  final String? qrCodeUrl;
  final Map<String, dynamic>? bankTransfer;
  int checkoutCalls = 0;
  String? lastMethod;
  bool paid = false;

  @override
  Future<num> walletBalance() async => 999999;

  @override
  Future<Map<String, dynamic>> checkout(
    int orderId,
    String method, {
    String? bankCode,
    String? returnUrl,
    String? description,
    String? orderCode,
  }) async {
    checkoutCalls++;
    lastMethod = method;
    return {
      'id': 1,
      'orderId': orderId,
      'method': method,
      'status': 'PENDING',
      if (qrCodeUrl != null) 'qrCodeUrl': qrCodeUrl,
      if (bankTransfer != null) 'bankTransfer': bankTransfer,
    };
  }

  @override
  Future<bool> orderStatus(int orderId) async => paid;
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

/// Mã QR có vòng chờ chạy liên tục ⇒ chỉ pump theo khung, không pumpAndSettle.
Future<void> _settleSheet(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

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

  testWidgets(
    'chỉ SePay: bấm trả là vào thẳng mã VietQR (không bảng chọn, không ví), đúng một checkout',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final service = _FakePayService(
        qrCodeUrl:
            'https://img.vietqr.io/image/970422-0123456789-compact2.jpg?amount=15000&addInfo=LKR42&accountName=LOCKR',
        bankTransfer: {
          'bankBin': '970422',
          'accountNo': '0123456789',
          'accountName': 'LOCKR',
          'amount': 15000,
          'transferContent': 'LKR42',
        },
      );
      Object? result;
      await tester.pumpWidget(_host(service, (r) => result = r));

      await tester.tap(find.text('Trả'));
      await _settleSheet(tester);

      expect(service.checkoutCalls, 1);
      expect(service.lastMethod, 'SEPAY');
      expect(find.text('Chọn phương thức thanh toán'), findsNothing);
      expect(find.text('Ví của tôi'), findsNothing);
      expect(find.text('Quét mã VietQR để thanh toán'), findsOneWidget);
      expect(find.text('LKR42'), findsOneWidget);
      expect(find.text('Sao chép'), findsOneWidget);
      expect(find.text('Thanh toán bằng app ngân hàng'), findsOneWidget);
      expect(find.text('Tôi đã chuyển khoản — Kiểm tra ngay'), findsNothing);
      final image = tester.widget<Image>(
        find
            .descendant(of: find.byType(ClipRRect), matching: find.byType(Image))
            .first,
      );
      expect(
        (image.image as NetworkImage).url,
        startsWith('https://img.vietqr.io/image/970422-0123456789'),
      );

      // Tiền về: lần hỏi kế tiếp (~3 s) thấy PAID, bảng tự đóng.
      service.paid = true;
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
      expect(find.text('Thanh toán thành công!'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(result, OrderPaymentOutcome.paid);
      expect(service.checkoutCalls, 1);
    },
  );

  testWidgets('server không trả QR lẫn bankTransfer ⇒ báo lỗi, không dùng tài khoản viết sẵn', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final service = _FakePayService();
    Object? result;
    await tester.pumpWidget(_host(service, (r) => result = r));

    await tester.tap(find.text('Trả'));
    await _settleSheet(tester);

    expect(service.checkoutCalls, 1);
    expect(find.textContaining('chưa trả mã VietQR'), findsOneWidget);
    expect(find.text('Quét mã VietQR để thanh toán'), findsNothing);
    expect(find.text('Thử lại'), findsOneWidget);

    // "Thử lại" là lần duy nhất được tạo giao dịch mới.
    await tester.tap(find.text('Thử lại'));
    await _settleSheet(tester);
    expect(service.checkoutCalls, 2);

    Navigator.of(tester.element(find.text('Thử lại'))).pop();
    await tester.pumpAndSettle();
    expect(result, OrderPaymentOutcome.cancelled);
  });

  testWidgets('đóng bảng khi đã có mã mà tiền chưa về ⇒ "đang chờ"', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final service = _FakePayService(
      bankTransfer: {
        'bankBin': '970422',
        'accountNo': '0123456789',
        'amount': 15000,
        'transferContent': 'LKR42',
      },
    );
    Object? result;
    await tester.pumpWidget(_host(service, (r) => result = r));

    await tester.tap(find.text('Trả'));
    await _settleSheet(tester);
    // Không có ảnh QR nhưng có STK ⇒ vẫn chuyển khoản được.
    expect(find.text('Quét mã VietQR để thanh toán'), findsOneWidget);
    expect(find.textContaining('0123456789'), findsOneWidget);

    Navigator.of(tester.element(find.text('LKR42'))).pop();
    await tester.pumpAndSettle();
    expect(result, OrderPaymentOutcome.pending);
    expect(service.checkoutCalls, 1);
  });
}
