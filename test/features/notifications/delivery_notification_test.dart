import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/notifications/domain/entities/delivery_notification.dart';

/// Kiểm chứng tầng logic xử lý noti giao hàng end-to-end ở phía app: từ `data`
/// payload mà backend bắn xuống (giống hệt phần data của FCM message) → bóc
/// tách → status/title/body + điều kiện deep-link.
void main() {
  // Mô phỏng đúng payload backend gửi (DeliveryNotificationService).
  Map<String, dynamic> payload(String status, {String? eta, String? message}) => {
        'orderId': '9001',
        'status': status,
        'type': 'ORDER_STATUS_CHANGED',
        'referenceId': '9001',
        'referenceType': 'DELIVERY',
        if (eta != null) 'eta': eta,
        'message': message ?? '',
      };

  group('DeliveryNotification.fromData (gate deep-link)', () {
    test('payload giao hàng hợp lệ -> parse được + giữ orderId', () {
      final d = DeliveryNotification.fromData(payload('dispatched'));
      expect(d, isNotNull);
      expect(d!.orderId, '9001'); // dùng để deep-link order_detail
      expect(d.status, DeliveryStatus.dispatched);
    });

    test('thiếu orderId -> null (không deep-link nhầm)', () {
      final data = payload('arrived')..remove('orderId');
      expect(DeliveryNotification.fromData(data), isNull);
    });

    test('thiếu status -> null', () {
      final data = payload('arrived')..remove('status');
      expect(DeliveryNotification.fromData(data), isNull);
    });

    test('status lạ -> unknown, không vỡ', () {
      final d = DeliveryNotification.fromData(payload('teleported'));
      expect(d, isNotNull);
      expect(d!.status, DeliveryStatus.unknown);
    });
  });

  group('Map 6 mốc -> status enum + style', () {
    final cases = {
      'dispatched': DeliveryStatus.dispatched,
      'approaching': DeliveryStatus.approaching,
      'arrived': DeliveryStatus.arrived,
      'delivered': DeliveryStatus.delivered,
      'delayed': DeliveryStatus.delayed,
      'failed': DeliveryStatus.failed,
    };
    cases.forEach((raw, expected) {
      test('$raw -> $expected + có icon/màu/title/body', () {
        final d = DeliveryNotification.fromData(payload(raw))!;
        expect(d.status, expected);
        expect(d.displayTitle, isNotEmpty);
        expect(d.displayBody, isNotEmpty);
        expect(d.status.icon, isA<IconData>());
        expect(d.status.color, isA<Color>());
      });
    });

    test('không phân biệt hoa thường', () {
      expect(DeliveryStatus.fromRaw('DELIVERED'), DeliveryStatus.delivered);
      expect(DeliveryStatus.fromRaw('  Arrived '), DeliveryStatus.arrived);
    });
  });

  group('Nội dung hiển thị', () {
    test('ưu tiên message backend gửi kèm', () {
      final d = DeliveryNotification.fromData(
        payload('arrived', message: 'Drone đã đến sảnh B'),
      )!;
      expect(d.displayBody, 'Drone đã đến sảnh B');
    });

    test('không có message -> fallback theo status', () {
      final d = DeliveryNotification.fromData(payload('delivered'))!;
      expect(d.displayBody, 'Đã giao hàng thành công. Cảm ơn bạn!');
    });

    test('delayed chèn eta vào nội dung mặc định', () {
      final d = DeliveryNotification.fromData(payload('delayed', eta: '14:30'))!;
      expect(d.displayBody, contains('14:30'));
    });
  });
}
