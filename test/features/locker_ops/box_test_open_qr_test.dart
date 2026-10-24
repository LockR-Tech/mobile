import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/locker_ops/domain/box_test_open_qr.dart';

void main() {
  group('BoxTestOpenQr.tryParse', () {
    test('đọc tủ và ô từ link trên tờ QR mở ô', () {
      for (final raw in [
        'http://10.3.75.226:3000/admin/lockers/7/open/39',
        'https://admin.locker-drone.tech/admin/lockers/7/open/39',
        '  http://localhost:3000/admin/lockers/7/open/39/  ',
      ]) {
        final qr = BoxTestOpenQr.tryParse(raw);
        expect(qr, isNotNull, reason: raw);
        expect(qr!.lockerId, 7);
        expect(qr.boxId, 39);
      }
    });

    test('bỏ qua mã không phải link mở ô', () {
      for (final raw in [
        'lockr://kiosk-login?sid=abc&code=123456',
        'https://admin.locker-drone.tech/admin/lockers/7',
        'https://admin.locker-drone.tech/admin/lockers/7/open/abc',
        'https://admin.locker-drone.tech/admin/lockers/0/open/39',
        'ftp://host/admin/lockers/7/open/39',
        '{"type":"LOCKER_BOX","lockerId":7,"boxId":39}',
        'CAB-TU01',
      ]) {
        expect(BoxTestOpenQr.tryParse(raw), isNull, reason: raw);
      }
    });
  });
}
