import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/locker_qr_scanner_dialog.dart';

void main() {
  group('lockerQrMatches', () {
    bool match(String raw) =>
        lockerQrMatches(raw, expectedCode: 'CAB-TU01', expectedId: 7);

    test('tem QR JSON của admin: khớp đúng id và mã tủ', () {
      expect(
        match(
          '{"app":"Lock.R","type":"LOCKER_BOX","lockerId":7,'
          '"lockerCode":"CAB-TU01","boxId":701,"boxNumber":1}',
        ),
        isTrue,
      );
      // Cùng mã nhưng sai id ⇒ không khớp.
      expect(
        match('{"type":"LOCKER_BOX","lockerId":17,"lockerCode":"CAB-TU01"}'),
        isFalse,
      );
      // Đúng id nhưng mã tủ khác ⇒ không khớp.
      expect(
        match('{"type":"LOCKER_BOX","lockerId":7,"lockerCode":"CAB-TU02"}'),
        isFalse,
      );
      expect(match('{không phải json'), isFalse);
    });

    test('mã tủ trần: so khớp chính xác, không phân biệt hoa thường', () {
      expect(match('cab-tu01'), isTrue);
      expect(match('  CAB-TU01 '), isTrue);
      // Trước đây dùng contains ⇒ "CAB-TU012" khớp nhầm.
      expect(match('CAB-TU012'), isFalse);
      expect(match('XCAB-TU01'), isFalse);
    });

    test('id tủ: tủ 7 không khớp tủ 17 hay 70', () {
      expect(match('7'), isTrue);
      expect(match('17'), isFalse);
      expect(match('70'), isFalse);
      expect(match('https://lockr.app/lockers/17'), isFalse);
      expect(match('https://lockr.app/lockers/7'), isTrue);
      expect(match('lockr://locker?lockerId=7'), isTrue);
      expect(match('lockr://locker?lockerId=77'), isFalse);
    });

    test('chuỗi rỗng hoặc chưa biết tủ thì không khớp', () {
      expect(match(''), isFalse);
      expect(lockerQrMatches('CAB-TU01', expectedCode: ''), isFalse);
    });
  });
}
