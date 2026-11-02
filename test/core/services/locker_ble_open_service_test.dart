import 'dart:convert';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/core/services/locker_ble_open_service.dart';

void main() {
  group('LockerBleOpenService.parseResult', () {
    List<int> reply(Map<String, Object?> m) => utf8.encode(jsonEncode(m));

    test('OK của đúng nonce', () {
      final o = LockerBleOpenService.parseResult(reply({'nonce': 'ABCD', 'result': 'OK', 'box': 3}), 'abcd');
      expect(o!.isOk, isTrue);
      expect(o.boxNumber, 3);
    });

    test('lỗi Pi trả về giữ nguyên mã', () {
      final o = LockerBleOpenService.parseResult(
          reply({'nonce': 'ab', 'result': 'FAIL', 'error': 'EXPIRED'}), 'ab');
      expect(o!.isOk, isFalse);
      expect(o.error, 'EXPIRED');
      expect(o.message, contains('hết hạn'));
    });

    test('bỏ qua kết quả của lần mở khác hoặc dữ liệu rác', () {
      expect(LockerBleOpenService.parseResult(reply({'nonce': 'zz', 'result': 'OK'}), 'ab'), isNull);
      expect(LockerBleOpenService.parseResult(utf8.encode('{}'), 'ab'), isNull);
      expect(LockerBleOpenService.parseResult([0xff, 0x00], 'ab'), isNull);
    });
  });

  test('BleOpenTicket giải mã base64url không padding (91 byte)', () {
    final bytes = List<int>.generate(91, (i) => i);
    final token = base64Url.encode(bytes).replaceAll('=', '');
    final t = BleOpenTicket.fromJson({
      'token': token,
      'nonce': 'A1B2',
      'deviceName': 'LOCKR_CAB-TU01',
      'lockerCode': 'CAB-TU01',
      'lockerId': 7,
      'boxNumber': 3,
      'serviceUuid': '06776521-9674-432d-b886-5e951244ffa3',
      'openCharUuid': '54af4ad7-dcde-47dc-ad44-fa2c7438dd36',
      'resultCharUuid': '8a6e33a5-1b26-4e80-8faa-026bab93ad4e',
      'boxStatus': 'OCCUPIED',
    });
    expect(t.token, bytes);
    expect(t.nonce, 'a1b2');
    expect(t.boxNumber, 3);
    expect(t.boxStatus, 'OCCUPIED');
  });

  group('chọn đúng tủ khi quét', () {
    const serviceUuid = '06776521-9674-432d-b886-5e951244ffa3';
    const ticket = BleOpenTicket(
      token: [],
      nonce: 'ab',
      deviceName: 'LOCKR_CAB-TU01',
      lockerCode: 'CAB-TU01',
      lockerId: 7,
      boxNumber: 3,
      serviceUuid: serviceUuid,
      openCharUuid: '54af4ad7-dcde-47dc-ad44-fa2c7438dd36',
      resultCharUuid: '8a6e33a5-1b26-4e80-8faa-026bab93ad4e',
    );
    BleMatch? level(String adv, {String platform = '', bool service = false}) =>
        LockerBleOpenService.matchLevel(
          advName: adv,
          platformName: platform,
          serviceUuids: service ? [Guid(serviceUuid)] : const [],
          ticket: ticket,
        );

    test('mức khớp theo tên đúng, tên gần đúng, chỉ service UUID', () {
      expect(level('LOCKR_CAB-TU01'), BleMatch.exactName);
      expect(level('', platform: 'LOCKR_CAB-TU01'), BleMatch.exactName);
      expect(level('LOCKR_CABTU01', service: true), BleMatch.fuzzyName);
      // Tủ giả trên Windows: quảng bá tên máy, chỉ có service UUID.
      expect(level('DESKTOP-PC', service: true), BleMatch.serviceOnly);
      expect(level('Galaxy Buds'), isNull);
    });

    test('ưu tiên đúng tên hơn tín hiệu mạnh, cùng mức thì lấy tủ gần nhất', () {
      expect(
        LockerBleOpenService.pickBest([
          (device: 'tu-khac', match: BleMatch.serviceOnly, rssi: -40),
          (device: 'tu-nay', match: BleMatch.exactName, rssi: -85),
        ]),
        'tu-nay',
      );
      expect(
        LockerBleOpenService.pickBest([
          (device: 'xa', match: BleMatch.serviceOnly, rssi: -90),
          (device: 'gan', match: BleMatch.serviceOnly, rssi: -55),
        ]),
        'gan',
      );
      expect(LockerBleOpenService.pickBest<String>(const []), isNull);
    });
  });

  test('mã lỗi phía app và phần cứng có câu báo riêng', () {
    for (final code in ['NOT_FOUND_LOCATION_OFF', 'MTU_TOO_SMALL', 'WRITE_FAILED', 'DISCONNECTED', 'HARDWARE_ERROR']) {
      expect(BleOpenOutcome.failed(code).message, isNot(contains(code)), reason: code);
    }
    expect(const BleOpenOutcome.failed('NOT_FOUND_LOCATION_OFF').message, contains('Vị trí'));
  });

  test('mã lỗi lạ vẫn có câu báo', () {
    expect(const BleOpenOutcome.failed('WHATEVER').message, contains('WHATEVER'));
    expect(const BleOpenOutcome.failed('NOT_FOUND').message, contains('2 m'));
  });
}
