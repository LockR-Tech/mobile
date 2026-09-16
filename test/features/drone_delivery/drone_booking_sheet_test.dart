import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:smart_laundry_locker/core/config/business_config.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/widgets/drone_booking_sheet.dart';

import '../../helpers/test_helpers.dart';

void main() {
  setUp(() => useBusinessConfig());

  testWidgets('books with backend orderId instead of local mock id', (tester) async {
    int? bookedOrderId;

    await tester.pumpWidget(
      MaterialApp(
        builder: FlutterSmartDialog.init(),
        home: Scaffold(
          body: DroneBookingSheet(
            cell: const {'id': 9001, 'boxNumber': 7},
            lockerName: 'Locker A',
            origin: const LatLng(10.0, 106.0),
            lockerId: 5,
            createOrder: ({
              required destinationLockerId,
              required preferredBoxId,
              required description,
              required parcelWeightGrams,
              required paymentMethod,
              required idempotencyKey,
            }) async => {
              'orderId': 77,
              'reservedBoxId': 9001,
            },
            onBooked: (orderId) => bookedOrderId = orderId,
            showMessage: (_) {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Xác nhận đặt ô Drone'));
    await tester.pumpAndSettle();

    expect(bookedOrderId, equals(77));
  });

  testWidgets('phí drone, hạn lấy hàng và khối lượng kiện theo cấu hình admin', (
    tester,
  ) async {
    useBusinessConfig(
      BusinessConfig.fromPublicMaps(
        order: {
          'app.order.drone-delivery-fee': 25000,
          'app.order.drone-default-parcel-weight-grams': 900,
          'app.order.drone-pickup-hours-limit': 12,
          'app.order.pickup-overtime-fee-per-hour': 0,
        },
      ),
    );
    int? sentWeight;

    await tester.pumpWidget(
      MaterialApp(
        builder: FlutterSmartDialog.init(),
        home: Scaffold(
          body: DroneBookingSheet(
            cell: const {'id': 9001, 'boxNumber': 7},
            lockerName: 'Locker A',
            origin: const LatLng(10.0, 106.0),
            lockerId: 5,
            createOrder: ({
              required destinationLockerId,
              required preferredBoxId,
              required description,
              required parcelWeightGrams,
              required paymentMethod,
              required idempotencyKey,
            }) async {
              sentWeight = parcelWeightGrams;
              return {'orderId': 78};
            },
            showMessage: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('25.000đ'), findsOneWidget);
    expect(
      find.text(
        'Người nhận có 12 giờ để lấy hàng kể từ lúc drone thả hàng vào ô. '
        'Không tính phí quá giờ.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Xác nhận đặt ô Drone'));
    await tester.pumpAndSettle();

    expect(sentWeight, 900);
  });
}
