import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/widgets/drone_booking_sheet.dart';

void main() {
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
}
