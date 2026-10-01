import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_delivery_stage.dart';
import 'package:smart_laundry_locker/features/drone_delivery/infrastructure/models/drone_delivery_response.dart';

void main() {
  test('uses deliveryStage and mission id from order read model', () {
    final response = DroneDeliveryResponse.fromJson({
      'data': {
        'orderId': 21,
        'orderCode': 'ORD-21',
        'status': 'AWAITING_DISPATCH',
        'deliveryStage': 'EN_ROUTE',
        'missionId': 301,
        'droneCode': 'DRONE-09',
        'etaMinutes': 6,
        'updatedAt': '2026-07-14T10:00:00Z',
      },
    });

    expect(response.status, 'EN_ROUTE');
    expect(response.deliveryId, '301');
    expect(response.orderId, '21');
    expect(response.toEntity().stage, DroneDeliveryStage.enRoute);
    expect(response.etaMinutes, 6);
  });

  test('maps route, people, loading record and journey for the detail view', () {
    final status = DroneDeliveryResponse.fromJson({
      'orderId': 21,
      'orderCode': 'ORD-21',
      'status': 'AWAITING_DISPATCH',
      'deliveryStage': 'ACCEPTED',
      'missionStatus': 'READY_TO_LAUNCH',
      'reservedBoxId': 9001,
      'reservedBoxNumber': 7,
      'customerName': 'Khach A',
      'assignedByName': 'Dieu Phoi Vien',
      'parcelMatched': true,
      // LocalDateTime trần của backend là UTC.
      'missionCreatedAt': '2026-10-01T03:00:00',
      'sourceLocker': {'lockerId': 1, 'name': 'Locker A', 'code': 'LK-A'},
      'destinationLocker': {
        'lockerId': 5,
        'name': 'Locker B',
        'address': '9 Nguyen Hue',
        'latitude': 10.78,
        'longitude': 106.71,
      },
      'journeyEvents': [
        {
          'id': 1,
          'toStage': 'AWAITING_DISPATCH',
          'occurredAt': '2026-10-01T02:00:00',
        },
        {
          'id': 2,
          'fromStage': 'AWAITING_DISPATCH',
          'toStage': 'ACCEPTED',
          'actorName': 'Dieu Phoi Vien',
          'occurredAt': '2026-10-01T03:00:00',
        },
      ],
    }).toEntity();

    expect(status.reservedBoxNumber, 7);
    expect(status.customerName, 'Khach A');
    expect(status.assignedByName, 'Dieu Phoi Vien');
    expect(status.parcelMatched, isTrue);
    expect(status.compartmentLocked, isNull);
    expect(status.acceptedAt, DateTime.utc(2026, 10, 1, 3).toLocal());
    expect(status.sourceLocker!.displayName, 'Locker A (LK-A)');
    expect(status.sourceLocker!.canNavigate, isFalse);
    expect(status.destinationLocker!.hasCoordinates, isTrue);
    // Mới nhất trước, dù backend trả theo thứ tự nào.
    expect(status.journeyEvents.first.toStage, 'ACCEPTED');
    expect(status.journeyEvents.first.actorName, 'Dieu Phoi Vien');
    expect(status.stageChangedAt, DateTime.utc(2026, 10, 1, 3).toLocal());
  });

  test('finished orders show the order outcome instead of the last stage', () {
    DroneDeliveryStage stageOf(String orderStatus, String deliveryStage) =>
        DroneDeliveryResponse.fromJson({
          'orderId': 21,
          'status': orderStatus,
          'deliveryStage': deliveryStage,
        }).toEntity().stage;

    expect(stageOf('COMPLETED', 'READY_FOR_PICKUP'), DroneDeliveryStage.completed);
    // Đơn cũ bị khách huỷ vẫn mang AWAITING_DISPATCH.
    expect(stageOf('CANCELED', 'AWAITING_DISPATCH'), DroneDeliveryStage.canceled);
    expect(stageOf('EXPIRED', 'READY_FOR_PICKUP'), DroneDeliveryStage.expired);
    expect(stageOf('STORING', 'READY_FOR_PICKUP'), DroneDeliveryStage.readyForPickup);
  });
}
