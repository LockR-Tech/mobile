import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_position_snapshot.dart';
import 'package:smart_laundry_locker/features/drone_delivery/infrastructure/models/drone_delivery_response.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/providers/drone_live_map_providers.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/widgets/drone_route_map_card.dart';

/// Thẻ "Bản đồ hành trình" phải phóng to được (trước đây khoá mọi thao tác) và mở được toàn màn hình.
void main() {
  final status = DroneDeliveryResponse.fromJson({
    'orderId': 21,
    'orderCode': 'ORD-21',
    'status': 'AWAITING_DISPATCH',
    'deliveryStage': 'EN_ROUTE',
    'fulfillmentMode': 'DEMO',
    'sourceLocker': {'lockerId': 1, 'name': 'Tủ demo', 'latitude': 10.8411, 'longitude': 106.8097},
    'destinationLocker': {'lockerId': 7, 'name': 'TU01', 'latitude': 10.8511, 'longitude': 106.8197},
  }).toEntity();

  Future<void> pumpCard(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dronePositionStreamProvider.overrideWith(
            (ref, orderId) => const Stream<DronePositionSnapshot>.empty(),
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

  double zoomOf(WidgetTester tester) =>
      MapCamera.of(tester.element(find.byType(MarkerLayer).first)).zoom;

  testWidgets('nút + / − đổi mức zoom, nút "Xem cả tuyến" canh lại khung', (tester) async {
    await pumpCard(tester);
    final start = zoomOf(tester);

    await tester.tap(find.byKey(const ValueKey('drone-route-zoom-in')));
    await tester.pump();
    expect(zoomOf(tester), closeTo(start + 1, 1e-6));

    await tester.tap(find.byKey(const ValueKey('drone-route-zoom-out')));
    await tester.tap(find.byKey(const ValueKey('drone-route-zoom-out')));
    await tester.pump();
    expect(zoomOf(tester), closeTo(start - 1, 1e-6));

    await tester.tap(find.byKey(const ValueKey('drone-route-fit')));
    await tester.pump();
    expect(zoomOf(tester), closeTo(start, 1e-6));
  });

  testWidgets('thẻ cho chụm hai ngón / chạm đúp nhưng không nuốt thao tác cuộn một ngón', (tester) async {
    await pumpCard(tester);
    final flags = tester.widget<FlutterMap>(find.byType(FlutterMap)).options.interactionOptions.flags;
    expect(InteractiveFlag.hasPinchZoom(flags), isTrue);
    expect(InteractiveFlag.hasDoubleTapZoom(flags), isTrue);
    expect(InteractiveFlag.hasDrag(flags), isFalse);
  });

  testWidgets('nút ⤢ mở bản đồ toàn màn hình kéo/zoom tự do', (tester) async {
    await pumpCard(tester);
    await tester.tap(find.byKey(const ValueKey('drone-route-expand')));
    await tester.pumpAndSettle();

    expect(find.byType(DroneRouteMapPage), findsOneWidget);
    expect(find.text('Bản đồ hành trình'), findsOneWidget);
    final flags = tester.widget<FlutterMap>(find.byType(FlutterMap)).options.interactionOptions.flags;
    expect(InteractiveFlag.hasDrag(flags), isTrue);
    expect(InteractiveFlag.hasPinchZoom(flags), isTrue);
    expect(find.byKey(const ValueKey('drone-route-expand')), findsNothing);
  });
}
