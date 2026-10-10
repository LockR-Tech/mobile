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
  };
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
}
