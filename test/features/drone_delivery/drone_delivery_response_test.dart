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
}
