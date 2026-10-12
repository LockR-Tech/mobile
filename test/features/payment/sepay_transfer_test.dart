import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/payment/domain/sepay_transfer.dart';

void main() {
  const qr =
      'https://img.vietqr.io/image/970422-0123456789-compact2.jpg'
      '?amount=20000&addInfo=LKR81&accountName=LOCKR%20JSC';

  test('ưu tiên bankTransfer của backend (PR #65)', () {
    final t = SepayTransfer.fromCheckout({
      'qrCodeUrl': qr,
      'amount': 99999,
      'content': 'CU',
      'bankTransfer': {
        'bankBin': '970436',
        'accountNo': '1112223334',
        'accountName': 'CONG TY LOCKR',
        'amount': 25000,
        'transferContent': 'LKR-NEW',
      },
    });
    expect(t.qrImageUrl, qr);
    expect(t.bankBin, '970436');
    expect(t.accountNo, '1112223334');
    expect(t.accountName, 'CONG TY LOCKR');
    expect(t.amount, 25000);
    expect(t.transferContent, 'LKR-NEW');
    expect(t.isUsable, isTrue);
    expect(t.canOpenBankApp, isTrue);
  });

  test('backend cũ không có bankTransfer ⇒ đọc BIN, STK, số tiền, nội dung từ URL ảnh QR', () {
    final t = SepayTransfer.fromCheckout({'qrCodeUrl': qr, 'content': 'CU'});
    expect(t.bankBin, '970422');
    expect(t.accountNo, '0123456789');
    expect(t.amount, 20000);
    expect(t.transferContent, 'LKR81');
    expect(t.accountName, 'LOCKR JSC');
    expect(t.canOpenBankApp, isTrue);
  });

  test('QR không phải img.vietqr.io ⇒ vẫn hiện ảnh, số tiền/nội dung lấy từ payment', () {
    final t = SepayTransfer.fromCheckout(
      {'qrCodeUrl': 'https://qr.sepay.vn/img?acc=1', 'content': 'LKR9'},
      fallbackAmount: 15000.4,
    );
    expect(t.qrImageUrl, 'https://qr.sepay.vn/img?acc=1');
    expect(t.bankBin, isNull);
    expect(t.amount, 15000);
    expect(t.transferContent, 'LKR9');
    expect(t.isUsable, isTrue);
    // Thiếu ngân hàng/STK ⇒ không mở app ngân hàng được, chỉ quét QR.
    expect(t.canOpenBankApp, isFalse);
  });

  test('không QR, không bankTransfer ⇒ không dùng được (không có tài khoản viết sẵn)', () {
    final t = SepayTransfer.fromCheckout(
      {'status': 'PENDING', 'content': 'LKR1'},
      fallbackAmount: 15000,
    );
    expect(t.isUsable, isFalse);
    expect(t.accountNo, isNull);
    expect(t.bankBin, isNull);
  });

  test('chỉ có bankTransfer (chưa sinh ảnh QR) vẫn chuyển khoản được', () {
    final t = SepayTransfer.fromCheckout({
      'bankTransfer': {
        'bankBin': '970422',
        'accountNo': '0123456789',
        'amount': '15000.00',
        'transferContent': 'LKR42',
      },
    });
    expect(t.qrImageUrl, isNull);
    expect(t.amount, 15000);
    expect(t.isUsable, isTrue);
    expect(t.canOpenBankApp, isTrue);
  });
}
