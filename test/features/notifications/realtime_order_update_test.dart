import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/notifications/infrastructure/services/realtime_notification_service.dart';

void main() {
  test('tin cập nhật đơn (/user/queue/orders) không phải thông báo hiển thị', () {
    // Dạng notification-service đẩy kèm sự kiện đơn: không có id thông báo.
    final orderUpdate = {
      'type': 'ORDER_STATUS_CHANGED',
      'orderId': 42,
      'userId': 7,
      'timestamp': '2026-10-12T01:00:00',
    };
    expect(isDisplayableNotificationJson(orderUpdate), isFalse);

    final parsed = OrderUpdateMessage.fromJson(orderUpdate);
    expect(parsed.type, 'ORDER_STATUS_CHANGED');
    expect(parsed.orderId, '42');
  });

  test('thông báo thật có id và nội dung', () {
    expect(
      isDisplayableNotificationJson({
        'id': 9,
        'title': 'Đơn hàng hoàn tất',
        'message': 'Đơn ORD-1 đã hoàn tất',
      }),
      isTrue,
    );
  });

  test('có id nhưng trống tiêu đề và nội dung ⇒ bỏ', () {
    expect(
      isDisplayableNotificationJson({'id': 9, 'title': ' ', 'message': ''}),
      isFalse,
    );
  });

  test('tin đơn chỉ có status ⇒ dùng status làm type', () {
    final parsed = OrderUpdateMessage.fromJson({
      'status': 'ORDER_COMPLETED',
      'referenceId': '5',
    });
    expect(parsed.type, 'ORDER_COMPLETED');
    expect(parsed.orderId, '5');
  });
}
