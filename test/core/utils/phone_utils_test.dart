import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/core/utils/phone_utils.dart';

void main() {
  group('toE164Phone (mặc định +84)', () {
    test('số nội địa 0xxx → +84xxx', () {
      expect(toE164Phone('0912345678'), '+84912345678');
      expect(toE164Phone('0912 345 678'), '+84912345678');
      expect(toE164Phone('091-234-5678'), '+84912345678');
      expect(toE164Phone('(091) 234.5678'), '+84912345678');
    });

    test('đã có +84 thì giữ nguyên, bỏ số 0 thừa sau mã nước', () {
      expect(toE164Phone('+84912345678'), '+84912345678');
      expect(toE164Phone('+84 0912 345 678'), '+84912345678');
    });

    test('84xxx thiếu dấu + và tiền tố quốc tế 00', () {
      expect(toE164Phone('84912345678'), '+84912345678');
      expect(toE164Phone('0084912345678'), '+84912345678');
      expect(toE164Phone('00840912345678'), '+84912345678');
    });

    test('số thuê bao 9 số bắt đầu bằng 84 (Vinaphone 084…) không bị coi là mã nước', () {
      expect(toE164Phone('845123456'), '+84845123456');
    });

    test('số thuê bao trần → thêm +84', () {
      expect(toE164Phone('912345678'), '+84912345678');
    });

    test('số nước khác giữ nguyên', () {
      expect(toE164Phone('+14155552671'), '+14155552671');
    });

    test('chuỗi rỗng', () {
      expect(toE164Phone('   '), '');
    });
  });

  group('isLikelyValidPhone', () {
    test('di động Việt Nam hợp lệ', () {
      for (final phone in [
        '0912345678',
        '0381234567',
        '0561234567',
        '0701234567',
        '0845123456',
        '+84912345678',
      ]) {
        expect(isLikelyValidPhone(phone), isTrue, reason: phone);
      }
    });

    test('sai độ dài / số bàn / ký tự lạ bị loại', () {
      for (final phone in [
        '',
        '091234567', // thiếu 1 số
        '09123456789', // thừa 1 số
        '02412345678', // số bàn Hà Nội — không nhận SMS OTP
        '0112345678', // đầu số không tồn tại
        'abc',
      ]) {
        expect(isLikelyValidPhone(phone), isFalse, reason: phone);
      }
    });

    test('số quốc tế khác kiểm dạng E.164', () {
      expect(isLikelyValidPhone('+14155552671'), isTrue);
      expect(isLikelyValidPhone('+1415'), isFalse);
    });
  });

  test('displayPhone hiển thị số Việt dạng 0xxx xxx xxx', () {
    expect(displayPhone('+84912345678'), '0912 345 678');
    expect(displayPhone('+14155552671'), '+14155552671');
  });
}
