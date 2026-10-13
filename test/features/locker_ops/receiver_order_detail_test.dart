import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/order_milestone.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/receiver_order_detail.dart';

void main() {
  group('ReceiverOrderDetail', () {
    test('đọc phần chung với danh sách và phần chi tiết', () {
      final d = ReceiverOrderDetail.tryParse({
        'id': 90,
        'orderCode': 'ORD-90',
        'type': 'drone_delivery',
        'viewerRole': 'delegate',
        'readyForPickup': true,
        'pickupPin': '246810',
        'boxSize': 'medium',
        'senderPhone': ' 0900000010 ',
        'parcel': {'weightGrams': 800, 'fragile': false},
        'journey': [
          {'toStage': 'EN_ROUTE', 'occurredAt': '2026-10-12T01:30:00'},
          {'toStage': 'awaiting_dispatch', 'occurredAt': '2026-10-12T01:00:00'},
          {'fromStage': 'X'},
        ],
        'timeline': [
          {'code': 'created', 'label': 'Đơn được tạo', 'occurredAt': '2026-10-12T01:00:00Z'},
          {'code': 'BROKEN'},
          'rác',
        ],
      })!;
      expect(d.loaded, isTrue);
      expect(d.order.pickupPin, '246810');
      expect(d.isDelegateView, isTrue);
      expect(d.isDrone, isTrue);
      expect(d.boxSize, 'MEDIUM');
      expect(d.senderPhone, '0900000010');
      expect(d.parcel!.weightGrams, 800);
      expect(d.parcel!.fragile, isFalse);
      // Hành trình cũ → mới, bỏ phần tử không có chặng.
      expect(d.journey.map((s) => s.toStage), ['AWAITING_DISPATCH', 'EN_ROUTE']);
      expect(d.timeline, hasLength(1));
      expect(d.timeline.single.code, 'CREATED');
      expect(
        d.timeline.single.occurredAt,
        DateTime.utc(2026, 10, 12, 1).toLocal(),
      );
    });

    test('bản từ danh sách chưa có phần chi tiết', () {
      final d = ReceiverOrderDetail.tryParse({'id': 5})!;
      expect(d.parcel, isNull);
      expect(d.timeline, isEmpty);
      expect(d.journey, isEmpty);
      expect(ReceiverOrderDetail.tryParse({'orderCode': 'x'}), isNull);
    });

    test('khai báo kiện rỗng coi như không có', () {
      expect(OrderParcel.tryParse({'description': '  '}), isNull);
      expect(OrderParcel.tryParse(null), isNull);
      expect(OrderMilestone.listFrom(null), isEmpty);
    });
  });
}
