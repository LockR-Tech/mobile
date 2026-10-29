import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_delivery_stage.dart';
import 'package:smart_laundry_locker/features/drone_delivery/infrastructure/models/drone_delivery_response.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/widgets/drone_route_map_card.dart';

const _a = LatLng(10.8411, 106.8097);
const _b = LatLng(10.8511, 106.8197);

void main() {
  test('đang bay: toạ độ ước theo chặng giữa tủ gửi và tủ nhận', () {
    final p = dronePositionOnRoute(DroneDeliveryStage.enRoute, _a, _b)!;
    expect(p.point.latitude, closeTo(10.8411 + 0.01 * 0.525, 1e-9));
    expect(p.point.longitude, closeTo(106.8097 + 0.01 * 0.525, 1e-9));
    expect(p.note, 'Ước theo chặng bay');
  });

  test('chưa cất cánh: tại tủ gửi; đã tới: tại tủ nhận', () {
    expect(
      dronePositionOnRoute(DroneDeliveryStage.pickedUp, _a, _b)!.point,
      _a,
    );
    expect(dronePositionOnRoute(DroneDeliveryStage.arrived, _a, _b)!.point, _b);
    expect(
      dronePositionOnRoute(DroneDeliveryStage.readyForPickup, _a, _b)!.note,
      'Tại tủ nhận',
    );
  });

  test('chặng lỗi / huỷ / báo rơi kiện: không đoán toạ độ', () {
    for (final stage in [
      DroneDeliveryStage.failed,
      DroneDeliveryStage.canceled,
      DroneDeliveryStage.dropReported,
    ]) {
      expect(dronePositionOnRoute(stage, _a, _b), isNull, reason: '$stage');
    }
  });

  testWidgets('thẻ hành trình hiện vĩ độ, kinh độ của drone', (tester) async {
    final status = DroneDeliveryResponse.fromJson({
      'orderId': 21,
      'orderCode': 'ORD-21',
      'status': 'AWAITING_DISPATCH',
      'deliveryStage': 'EN_ROUTE',
      'fulfillmentMode': 'DEMO',
      'sourceLocker': {
        'lockerId': 1,
        'name': 'Tủ demo',
        'latitude': 10.8411,
        'longitude': 106.8097,
      },
      'destinationLocker': {
        'lockerId': 7,
        'name': 'TU01',
        'latitude': 10.8511,
        'longitude': 106.8197,
      },
    }).toEntity();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: DroneRouteMapCard(status: status)),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('drone-route-coordinates')),
      findsOneWidget,
    );
    expect(find.text('Vĩ độ 10.846350 · Kinh độ 106.814950'), findsOneWidget);
    expect(
      find.text('Vị trí drone · Ước theo chặng bay · mô phỏng'),
      findsOneWidget,
    );
  });
}
