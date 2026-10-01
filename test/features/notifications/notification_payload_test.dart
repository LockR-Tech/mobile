import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/notifications/domain/entities/notification_model.dart';

void main() {
  NotificationDataPayload payloadOf(Map<String, dynamic> json) =>
      NotificationModel.fromJson({
        'id': 1,
        'title': 't',
        'message': 'm',
        'createdAt': '2026-10-01T03:00:00',
        ...json,
      }).dataPayload!;

  test('delivery-stage notification opens drone tracking, not order detail', () {
    final payload = payloadOf({
      'type': 'ORDER_STATUS_CHANGED',
      'referenceId': 21,
      'referenceType': 'DELIVERY',
    });

    expect(payload.isDroneDelivery, isTrue);
    expect(payload.referenceId, '21');
  });

  test('plain order notification is not a drone notification', () {
    final payload = payloadOf({
      'type': 'ORDER_STATUS_CHANGED',
      'referenceId': 21,
      'referenceType': 'ORDER',
    });

    expect(payload.isDroneDelivery, isFalse);
    expect(payload.isDroneDispatch, isFalse);
  });

  test('mission cancel and new drone order are recognised by type', () {
    expect(
      payloadOf({'type': 'DRONE_DELIVERY_STATUS_CHANGED', 'referenceId': 21})
          .isDroneDelivery,
      isTrue,
    );
    expect(
      payloadOf({'type': 'DRONE_ORDER_CREATED', 'referenceId': 21})
          .isDroneDispatch,
      isTrue,
    );
  });

  test('server time without zone is read as UTC', () {
    final model = NotificationModel.fromJson({
      'id': 1,
      'title': 't',
      'message': 'm',
      'createdAt': '2026-10-01T03:00:00',
    });

    expect(model.createdAt, DateTime.utc(2026, 10, 1, 3).toLocal());
  });
}
