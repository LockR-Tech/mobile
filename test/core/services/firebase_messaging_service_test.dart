import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/core/services/firebase_messaging_service.dart';

void main() {
  group('drone notification routing contract', () {
    test('customer stage notification is classified as drone delivery', () {
      expect(
        FirebaseMessagingService.droneDeliveryTypes,
        contains('DRONE_DELIVERY_STATUS_CHANGED'),
      );
    });

    test('new drone order notification is classified for maintenance', () {
      expect(
        FirebaseMessagingService.maintenanceDroneTypes,
        contains('DRONE_ORDER_CREATED'),
      );
    });
  });
}
