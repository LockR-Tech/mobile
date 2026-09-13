import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/pages/maintenance_home_page.dart';

import '../../helpers/test_helpers.dart';

class _FakeMaintenanceService extends LockerOpsService {
  _FakeMaintenanceService() : super(dio: createMockDio().dio);

  int? acceptedOrderId;
  int? acceptedDroneId;
  int? launchedOrderId;
  int? canceledOrderId;
  int? canceledReasonCode;
  String? canceledNote;

  @override
  Future<List<Map<String, dynamic>>> droneUnits() async => [
    {
      'id': 9,
      'code': 'DRONE-09',
      'status': 'IDLE',
      'batteryPercent': 87,
      'lockerId': 3,
      'lockerName': 'Tram 3',
    },
  ];

  @override
  Future<List<Map<String, dynamic>>> maintenanceSchedules() async => const [];

  @override
  Future<List<Map<String, dynamic>>> droneOrderQueue({
    String? deliveryStage,
  }) async {
    final items = [
      {
        'orderId': 21,
        'deliveryStage': 'AWAITING_DISPATCH',
        'destinationLockerId': 5,
        'reservedBoxId': 9001,
        'description': 'Tai lieu khan',
      },
      {
        'orderId': 22,
        'deliveryStage': 'ACCEPTED',
        'missionStatus': 'READY_TO_LAUNCH',
        'droneCode': 'DRONE-09',
        'destinationLockerId': 5,
        'reservedBoxId': 9002,
        'description': 'Hang mau',
      },
    ];
    if (deliveryStage == null) return items;
    return items
        .where((item) => item['deliveryStage'] == deliveryStage)
        .toList();
  }

  @override
  Future<Map<String, dynamic>> acceptDroneOrder(
    int orderId, {
    required int droneUnitId,
    required String idempotencyKey,
  }) async {
    acceptedOrderId = orderId;
    acceptedDroneId = droneUnitId;
    return {
      'orderId': orderId,
      'missionId': 301,
      'missionStatus': 'READY_TO_LAUNCH',
      'deliveryStage': 'ACCEPTED',
      'droneUnitId': droneUnitId,
      'droneCode': 'DRONE-09',
    };
  }

  @override
  Future<Map<String, dynamic>> launchDroneOrder(
    int orderId, {
    required String idempotencyKey,
  }) async {
    launchedOrderId = orderId;
    return {
      'orderId': orderId,
      'missionId': 301,
      'missionStatus': 'LAUNCHING',
      'deliveryStage': 'LAUNCHING',
      'droneUnitId': 9,
      'droneCode': 'DRONE-09',
    };
  }

  @override
  Future<Map<String, dynamic>> cancelDroneOrder(
    int orderId, {
    required int reasonCode,
    String? note,
  }) async {
    canceledOrderId = orderId;
    canceledReasonCode = reasonCode;
    canceledNote = note;
    return {
      'orderId': orderId,
      'missionId': 302,
      'missionStatus': 'CANCELED',
      'deliveryStage': 'CANCELED',
    };
  }
}

void main() {
  setUp(() {
    mockSecureStorage({
      'access_token': makeFakeJwt(sub: '99', roles: ['MAINTENANCE']),
    });
  });

  testWidgets('renders order-based drone queue and accepts awaiting order', (
    tester,
  ) async {
    final service = _FakeMaintenanceService();
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => MaintenanceHomePage(service: service),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.textContaining('Chờ tiếp nhận'), findsOneWidget);
    expect(find.textContaining('Sẵn sàng phóng'), findsOneWidget);
    expect(find.text('Tiếp nhận'), findsOneWidget);
    expect(find.text('Phóng'), findsOneWidget);

    await tester.tap(find.text('Tiếp nhận'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tiếp nhận ngay'));
    await tester.pumpAndSettle();

    expect(service.acceptedOrderId, equals(21));
    expect(service.acceptedDroneId, equals(9));
  });

  testWidgets('requires cancel reason before canceling accepted drone order', (
    tester,
  ) async {
    final service = _FakeMaintenanceService();
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => MaintenanceHomePage(service: service),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hủy trước khi bay'));
    await tester.pumpAndSettle();

    expect(find.text('Hủy nhiệm vụ trước khi bay'), findsOneWidget);
    await tester.tap(find.text('Khác'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Gio giat manh');
    await tester.tap(find.text('Xác nhận hủy'));
    await tester.pumpAndSettle();

    expect(service.canceledOrderId, equals(22));
    expect(service.canceledReasonCode, equals(5));
    expect(service.canceledNote, equals('Gio giat manh'));
  });
}
