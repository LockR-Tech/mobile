import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/receiver_order.dart';

void main() {
  group('ReceiverOrder', () {
    test('đọc ReceiverOrderResponse; có PIN khi sẵn sàng lấy', () {
      final o = ReceiverOrder.tryParse({
        'id': 12,
        'orderCode': 'ORD-12',
        'type': 'send',
        'status': 'STORING',
        'senderName': 'An',
        'lockerId': 7,
        'lockerCode': 'CAB-TU01',
        'lockerName': 'Tủ thư viện',
        'lockerLatitude': 10.84,
        'lockerLongitude': 106.8,
        'boxId': 701,
        'boxNumber': 3,
        'pickupDeadline': '2026-10-13T08:00:00',
        'readyForPickup': true,
        'pickupPin': '123456',
        'qrToken': 'LLQR.x',
        'overdue': false,
      })!;
      expect(o.type, 'SEND');
      expect(o.isActive, isTrue);
      expect(o.canUnlockWithCode, isTrue);
      expect(o.boxLabel, 'ô số 3');
      expect(o.displayCode, '#ORD-12');
      expect(o.pickupDeadline, isNotNull);
    });

    test('chưa sẵn sàng / thiếu tủ ⇒ không mở được bằng mã', () {
      final notReady = ReceiverOrder.tryParse({
        'id': 1,
        'status': 'INITIALIZED',
        'lockerId': 7,
        'readyForPickup': false,
      })!;
      expect(notReady.isActive, isFalse);
      expect(notReady.canUnlockWithCode, isFalse);

      final noLocker = ReceiverOrder.tryParse({
        'id': 2,
        'status': 'STORING',
        'readyForPickup': true,
        'pickupPin': '111111',
      })!;
      expect(noLocker.canUnlockWithCode, isFalse);
      expect(noLocker.boxLabel, 'ô của đơn');

      final done = ReceiverOrder.tryParse({
        'id': 3,
        'status': 'COMPLETED',
        'lockerId': 7,
        'readyForPickup': true,
        'pickupPin': '111111',
      })!;
      expect(done.isActive, isFalse);
    });

    test('bỏ phần tử không có id, toạ độ NaN coi như không có', () {
      final list = ReceiverOrder.listFrom([
        {'orderCode': 'thiếu id'},
        {'id': '5', 'lockerLatitude': 'NaN', 'lockerLongitude': null},
      ]);
      expect(list, hasLength(1));
      expect(list.single.id, 5);
      expect(list.single.lockerLatitude, isNull);
    });
  });
}
