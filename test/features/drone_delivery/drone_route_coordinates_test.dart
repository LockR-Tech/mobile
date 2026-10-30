import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_delivery_stage.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_position_snapshot.dart';
import 'package:smart_laundry_locker/features/drone_delivery/infrastructure/models/drone_delivery_response.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/providers/drone_live_map_providers.dart';
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

  Map<String, dynamic> enRouteDemo({double? lat, double? lng}) => {
    'orderId': 21,
    'orderCode': 'ORD-21',
    'status': 'AWAITING_DISPATCH',
    'deliveryStage': 'EN_ROUTE',
    'fulfillmentMode': 'DEMO',
    'currentLatitude': lat,
    'currentLongitude': lng,
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
  };

  Future<void> pumpCard(
    WidgetTester tester,
    Map<String, dynamic> json, {
    Stream<DronePositionSnapshot>? live,
  }) async {
    final status = DroneDeliveryResponse.fromJson(json).toEntity();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dronePositionStreamProvider.overrideWith(
            (ref, orderId) => live ?? const Stream<DronePositionSnapshot>.empty(),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: DroneRouteMapCard(status: status)),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('chưa có số nào: thẻ ghi toạ độ ước theo chặng, gộp một dòng', (tester) async {
    await pumpCard(tester, enRouteDemo());

    expect(find.byKey(const ValueKey('drone-route-coordinates')), findsOneWidget);
    expect(find.text('10.846350, 106.814950'), findsOneWidget);
    expect(find.text('Vị trí drone · Ước theo chặng bay · mô phỏng'), findsOneWidget);
  });

  testWidgets('API chi tiết có toạ độ: thẻ dùng đúng số đó', (tester) async {
    await pumpCard(tester, enRouteDemo(lat: 10.8452, lng: 106.8131));

    expect(find.text('10.845200, 106.813100'), findsOneWidget);
    expect(find.text('Vị trí drone · Mô phỏng theo chặng bay'), findsOneWidget);
  });

  testWidgets('drone bắn toạ độ về: thẻ đổi theo bản tin mới nhất', (tester) async {
    final at = DateTime(2026, 10, 30, 9, 15, 42);
    await pumpCard(
      tester,
      enRouteDemo(lat: 10.8452, lng: 106.8131),
      live: Stream.value(
        DronePositionSnapshot(
          orderId: '21',
          status: 'en_route',
          lat: 10.8477,
          lng: 106.8163,
          headingDeg: 45,
          timestamp: at,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('10.847700, 106.816300'), findsOneWidget);
    expect(find.text('Vị trí drone · Drone gửi về lúc 09:15:42 · mô phỏng'), findsOneWidget);
  });
}
