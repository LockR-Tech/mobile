import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_delivery_stage.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_labels.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_route_geometry.dart';

void main() {
  test('distance between two points in Ho Chi Minh City is in km', () {
    // Nhà thờ Đức Bà → Chợ Bến Thành ≈ 0,8 km đường chim bay.
    final km = droneDistanceKm(10.7798, 106.6990, 10.7725, 106.6980);
    expect(km, closeTo(0.82, 0.05));
    expect(droneDistanceKm(10.0, 106.0, 10.0, 106.0), 0);
  });

  test('labels km, coordinates and durations for the tracking screens', () {
    expect(droneKmLabel(0.8234), '823 m');
    expect(droneKmLabel(2.345), '2,35 km');
    expect(droneCoordinateLabel(10.7769, 106.7009), '10.776900, 106.700900');
    expect(droneDurationLabel(const Duration(seconds: 45)), '45 giây');
    expect(droneDurationLabel(const Duration(minutes: 3, seconds: 20)), '3 phút 20 giây');
    expect(droneDurationLabel(const Duration(hours: 1, minutes: 5)), '1 giờ 5 phút');
    expect(droneDurationLabel(const Duration(days: 2)), '2 ngày');
  });

  test('estimated progress only exists while the drone is airborne', () {
    expect(droneStageProgress(DroneDeliveryStage.awaitingDispatch), isNull);
    expect(droneStageProgress(DroneDeliveryStage.launching), 0);
    expect(droneStageProgress(DroneDeliveryStage.enRoute), closeTo(0.525, 1e-9));
    expect(droneStageProgress(DroneDeliveryStage.arrived), 1);
    expect(droneStageProgress(DroneDeliveryStage.readyForPickup), isNull);
  });
}
