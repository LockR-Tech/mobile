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
  int? loadedOrderId;
  int? loadedWeightGrams;
  String? loadedSealCode;
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
  Future<List<Map<String, dynamic>>> maintenanceSchedules({
    bool mine = false,
    String? target,
  }) async => const [];

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
        'assignedByUserId': 99,
        'droneCode': 'DRONE-09',
        'destinationLockerId': 5,
        'reservedBoxId': 9002,
        'description': 'Hang mau',
      },
      {
        'orderId': 23,
        'deliveryStage': 'ACCEPTED',
        'missionStatus': 'AWAITING_LOADING',
        'assignedByUserId': 99,
        'droneCode': 'DRONE-10',
        'destinationLockerId': 6,
        'reservedBoxId': 9003,
        'description': 'Linh kien dien tu',
        'expectedWeightGrams': 1450,
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
      'missionStatus': 'AWAITING_LOADING',
      'deliveryStage': 'ACCEPTED',
      'droneUnitId': droneUnitId,
      'droneCode': 'DRONE-09',
      'assignedByUserId': 99,
    };
  }

  @override
  Future<Map<String, dynamic>> confirmDroneLoading(
    int orderId, {
    required int payloadWeightGrams,
    required String sealCode,
    required bool parcelMatched,
    required bool payloadSecured,
    required bool compartmentLocked,
    String? note,
    required String idempotencyKey,
  }) async {
    loadedOrderId = orderId;
    loadedWeightGrams = payloadWeightGrams;
    loadedSealCode = sealCode;
    return {
      'orderId': orderId,
      'missionId': 303,
      'missionStatus': 'READY_TO_LAUNCH',
      'deliveryStage': 'ACCEPTED',
      'payloadWeightGrams': payloadWeightGrams,
      'sealCode': sealCode,
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
      'access_token': makeFakeJwt(sub: '99', roles: ['DRONE_TECHNICIAN']),
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
    expect(find.textContaining('Chờ nạp hàng'), findsOneWidget);
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

  testWidgets('requires full loading checklist before mission is ready', (
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
    await tester.tap(find.text('Xác nhận nạp'));
    await tester.pumpAndSettle();

    expect(find.text('Xác nhận nạp hàng'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey('drone-loading-weight')),
          )
          .controller!
          .text,
      '1450',
    );
    await tester.enterText(
      find.byKey(const ValueKey('drone-loading-seal')),
      'SEAL-23',
    );
    for (final checkbox in find.byType(Checkbox).evaluate()) {
      await tester.tap(find.byWidget(checkbox.widget));
      await tester.pump();
    }
    await tester.tap(find.text('Xác nhận đã nạp'));
    await tester.pumpAndSettle();

    expect(service.loadedOrderId, equals(23));
    expect(service.loadedWeightGrams, equals(1450));
    expect(service.loadedSealCode, equals('SEAL-23'));
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

    final cancelReadyMission = find.text('Hủy trước khi bay').last;
    await tester.ensureVisible(cancelReadyMission);
    await tester.pumpAndSettle();
    await tester.tap(cancelReadyMission);
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
