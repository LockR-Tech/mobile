import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/maintenance/presentation/widgets/drone_journey_camera_panel.dart';

class _UnavailableCameraService extends LockerOpsService {
  _UnavailableCameraService() : super(dio: Dio());

  @override
  Future<Map<String, dynamic>> droneOrderCamera(int orderId) async => {
    'status': 'UNAVAILABLE',
    'integrationAvailable': false,
    'droneCode': 'DRONE-09',
    'journeyStatus': 'EN_ROUTE',
    'telemetryLive': false,
    'locationSource': 'SIMULATION_FPT_HCM',
    'latitude': 10.841100,
    'longitude': 106.809700,
    'observedAt': '2026-10-14T03:22:43Z',
    'batteryPercent': 72,
    'flightMode': 'AUTO',
  };

  @override
  Future<Map<String, dynamic>> reportDroppedParcel(
    int orderId, {
    required String idempotencyKey,
    required String reason,
    double? latitude,
    double? longitude,
    double? gpsAccuracyM,
    String? cameraStatus,
    Map<String, dynamic>? cameraSnapshot,
    String? snapshotCapturedAt,
  }) async => {'incidentCode': 'INC-21', 'orderId': orderId};
}

void main() {
  testWidgets(
    'camera unavailable is explicit and manual report remains available',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DroneJourneyCameraPanel(
              orderId: 21,
              service: _UnavailableCameraService(),
              onIncidentReported: () async {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('UNAVAILABLE'), findsOneWidget);
      expect(find.text('Báo rơi kiện'), findsOneWidget);
      expect(find.text('Trực tuyến'), findsNothing);
    },
  );

  testWidgets('submitting a parcel-drop report closes the dialog safely', (
    tester,
  ) async {
    var incidentReported = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DroneJourneyCameraPanel(
            orderId: 21,
            service: _UnavailableCameraService(),
            onIncidentReported: () async => incidentReported = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Báo rơi kiện'));
    await tester.pumpAndSettle();
    expect(find.text('Dữ liệu tự ghi vào phiếu'), findsOneWidget);
    expect(find.text('10.84110, 106.80970 · Mô phỏng FPT HCM'), findsOneWidget);
    expect(find.text('Cũ / chưa kết nối'), findsOneWidget);
    await tester.enterText(
      find.byType(TextField),
      'Phát hiện kiện rơi tại khu vực hạ cánh',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Xác nhận'));
    await tester.pumpAndSettle();

    expect(incidentReported, isTrue);
    expect(find.text('Xác nhận báo rơi kiện'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
