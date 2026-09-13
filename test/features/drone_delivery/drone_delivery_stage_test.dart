import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_delivery_stage.dart';

void main() {
  test('parses production drone delivery stages', () {
    expect(
      DroneDeliveryStage.fromRaw('AWAITING_DISPATCH'),
      DroneDeliveryStage.awaitingDispatch,
    );
    expect(
      DroneDeliveryStage.fromRaw('ACCEPTED'),
      DroneDeliveryStage.accepted,
    );
    expect(
      DroneDeliveryStage.fromRaw('LAUNCHING'),
      DroneDeliveryStage.launching,
    );
    expect(
      DroneDeliveryStage.fromRaw('DEPARTED'),
      DroneDeliveryStage.departed,
    );
    expect(
      DroneDeliveryStage.fromRaw('EN_ROUTE'),
      DroneDeliveryStage.enRoute,
    );
    expect(
      DroneDeliveryStage.fromRaw('READY_FOR_PICKUP'),
      DroneDeliveryStage.readyForPickup,
    );
  });

  test('keeps production stages in timeline order', () {
    expect(DroneDeliveryStage.awaitingDispatch.order, lessThan(DroneDeliveryStage.accepted.order));
    expect(DroneDeliveryStage.accepted.order, lessThan(DroneDeliveryStage.launching.order));
    expect(DroneDeliveryStage.launching.order, lessThan(DroneDeliveryStage.departed.order));
    expect(DroneDeliveryStage.departed.order, lessThan(DroneDeliveryStage.enRoute.order));
    expect(DroneDeliveryStage.enRoute.order, lessThan(DroneDeliveryStage.approaching.order));
    expect(DroneDeliveryStage.approaching.order, lessThan(DroneDeliveryStage.arrived.order));
    expect(DroneDeliveryStage.arrived.order, lessThan(DroneDeliveryStage.readyForPickup.order));
  });
}
