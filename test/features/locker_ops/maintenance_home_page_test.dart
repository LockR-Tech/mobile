import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_laundry_locker/core/config/business_config.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/pages/maintenance_home_page.dart';

import '../../helpers/test_helpers.dart';

class _FakeMaintenanceService extends LockerOpsService {
  _FakeMaintenanceService() : super(dio: createMockDio().dio);

  final Map<String, dynamic> droneReport = {
    'id': 42,
    'title': 'Lỗi cảm biến Drone',
    'description': 'Cảm biến độ cao báo sai',
    'status': 'OPEN',
    'category': 'DRONE',
    'droneUnitId': 9,
    'droneCode': 'DRONE-09',
    'lockerId': 3,
    'lockerName': 'Trạm 3',
    'createdAt': '2026-10-10T08:00:00Z',
  };

  int? acceptedOrderId;
  int? acceptedDroneId;
  int? loadedOrderId;
  int? loadedWeightGrams;
  String? loadedSealCode;
  int? launchedOrderId;
  int? canceledOrderId;
  int? canceledReasonCode;
  String? canceledNote;
  String? requestedScheduleTarget;
  int? completedScheduleId;
  List<Map<String, dynamic>>? completedChecklist;

  @override
  Future<List<Map<String, dynamic>>> droneReports({
    bool mine = false,
    bool routed = false,
    bool all = false,
  }) async {
    if (mine && droneReport['assignedToUserId'] != 99) return const [];
    return [Map<String, dynamic>.from(droneReport)];
  }

  @override
  Future<Map<String, dynamic>> getDroneReport(int reportId) async =>
      Map<String, dynamic>.from(droneReport);

  @override
  Future<List<Map<String, dynamic>>> droneReportAttachments(
    int reportId, {
    String? stage,
  }) async => [
    {
      'id': 1,
      'reportId': reportId,
      'stage': 'REPORT',
      'url': 'https://example.com/drone-report.jpg',
    },
  ];

  @override
  Future<List<Map<String, dynamic>>> droneReportLogs(int reportId) async => [
    {
      'id': 5,
      'reportId': reportId,
      'actorUserId': 99,
      'note': 'Đã kiểm tra cảm biến độ cao',
      'createdAt': '2026-10-10T09:00:00Z',
      'attachments': [
        {
          'id': 2,
          'repairLogId': 5,
          'stage': 'PROGRESS',
          'url': 'https://example.com/drone-log.jpg',
        },
      ],
    },
  ];

  @override
  Future<Map<String, dynamic>> claimDroneReport(int reportId) async {
    droneReport['status'] = 'IN_PROGRESS';
    droneReport['assignedToUserId'] = 99;
    return Map<String, dynamic>.from(droneReport);
  }

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
  }) async {
    requestedScheduleTarget = target;
    return const [
      {
        'id': 71,
        'droneUnitId': 9,
        'droneCode': 'DRONE-09',
        'title': 'Bảo trì pin và cảm biến',
        'description': 'Kiểm tra trước chu kỳ bay mới',
        'priority': 'HIGH',
        'intervalDays': 30,
        'nextDueAt': '2026-10-09T08:00:00Z',
        'due': true,
        'active': true,
        'assignedTechnicianId': 99,
        'assignedTechnicianName': 'Bảo Huy Nguyễn',
        'checklistItems': ['Kiểm tra pin', 'Kiểm tra cảm biến'],
        'address': 'Trạm 3, TP.HCM',
      },
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> scheduleInspectionLogs(
    int scheduleId,
  ) async => const [];

  @override
  Future<Map<String, dynamic>> completeInspection(
    int scheduleId,
    List<Map<String, dynamic>> items, {
    String? status,
    String? note,
    int? faultBoxId,
    String? faultReason,
    List<String>? photoUrls,
  }) async {
    completedScheduleId = scheduleId;
    completedChecklist = items;
    return {
      'id': scheduleId,
      'droneUnitId': 9,
      'droneCode': 'DRONE-09',
      'title': 'Bảo trì pin và cảm biến',
      'lastResult': 'PASSED',
      'nextDueAt': '2026-11-09T08:00:00Z',
    };
  }

  @override
  Future<List<Map<String, dynamic>>> droneOrderQueue({
    String? deliveryStage,
  }) async {
    final items = [
      {
        'orderId': 21,
        'deliveryStage': 'AWAITING_DISPATCH',
        // Chỉ đơn đã thanh toán mới tiếp nhận được.
        'paymentStatus': 'PAID',
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
        'paymentStatus': 'PAID',
        'totalPrice': 27000,
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
    String? sealCode,
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
    createMockApiClient();
    mockSecureStorage({
      'access_token': makeFakeJwt(sub: '99', roles: ['DRONE_TECHNICIAN']),
    });
  });

  testWidgets('drone technician confirms before logging out', (tester) async {
    final service = _FakeMaintenanceService();
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => MaintenanceHomePage(service: service),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const Scaffold(body: Text('Onboarding')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Đăng xuất'));
    await tester.pumpAndSettle();

    expect(find.text('Đăng xuất ca trực'), findsOneWidget);
    expect(
      find.text(
        'Bạn có chắc chắn muốn kết thúc ca trực và đăng xuất khỏi tài khoản KTV Drone không?',
      ),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(TextButton, 'Hủy'));
    await tester.pumpAndSettle();
    expect(find.text('Onboarding'), findsNothing);

    await tester.tap(find.byTooltip('Đăng xuất'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Đăng xuất'));
    await tester.pumpAndSettle();

    expect(find.text('Onboarding'), findsOneWidget);
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

    // Khớp tiêu đề nhóm ("… (n)"): thẻ đơn cũng hiện nhãn trạng thái nhiệm vụ
    // cùng chữ, nên tìm theo chữ trần sẽ ra nhiều hơn một widget.
    expect(
      find.textContaining('Chờ tiếp nhận (', skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.textContaining('Chờ nạp hàng (', skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.textContaining('Sẵn sàng phóng (', skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.textContaining('Nhiệm vụ: Chờ nạp hàng', skipOffstage: false),
      findsOneWidget,
    );
    expect(find.text('Tiếp nhận', skipOffstage: false), findsOneWidget);
    final launchAction = find.text('Phóng', skipOffstage: false);
    await tester.ensureVisible(launchAction);
    expect(launchAction, findsOneWidget);

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
          .widget<TextField>(find.byKey(const ValueKey('drone-loading-weight')))
          .controller!
          .text,
      '1450',
    );
    // Mã niêm phong do hệ thống cấp, đội viên không nhập tay.
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('drone-loading-seal')),
        matching: find.byType(TextField),
      ),
      findsNothing,
    );
    expect(find.textContaining('Khách khai báo 1450 g'), findsOneWidget);
    expect(find.byKey(const ValueKey('drone-loading-surcharge')), findsNothing);
    for (final checkbox in find.byType(Checkbox).evaluate()) {
      await tester.tap(find.byWidget(checkbox.widget));
      await tester.pump();
    }
    await tester.tap(find.text('Xác nhận đã nạp'));
    await tester.pumpAndSettle();

    expect(service.loadedOrderId, equals(23));
    expect(service.loadedWeightGrams, equals(1450));
    expect(service.loadedSealCode, matches(RegExp(r'^NP-\d{6}-[A-Z2-9]{6}$')));
  });

  testWidgets('cân nặng hơn khai báo: báo trước khoản khách phải trả thêm', (
    tester,
  ) async {
    useBusinessConfig(
      BusinessConfig.fromPublicMaps(
        order: {'app.order.drone-weight-step-fee': 3000},
      ),
    );
    addTearDown(useBusinessConfig);
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

    // Khai 1450 g đã tính 27.000đ; cân 2000 g = 15.000 + 6 nấc × 3.000 = 33.000đ.
    await tester.enterText(
      find.byKey(const ValueKey('drone-loading-weight')),
      '2000',
    );
    await tester.pump();

    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('drone-loading-surcharge')))
          .data,
      contains('6.000đ'),
    );

    // Trong sai số cân 50 g thì không thu thêm.
    await tester.enterText(
      find.byKey(const ValueKey('drone-loading-weight')),
      '1490',
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('drone-loading-surcharge')), findsNothing);
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

  testWidgets('drone incident detail shows staged photos and log photos', (
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
    await tester.tap(find.text('Sự cố (1)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('RPT-42'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(
      find.text('Hồ sơ chi tiết phiếu sự cố kỹ thuật Drone'),
      findsOneWidget,
    );
    expect(find.text('Ảnh hồ sơ theo giai đoạn'), findsOneWidget);
    expect(find.textContaining('Ảnh hiện trường'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Đã kiểm tra cảm biến độ cao'),
      300,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('drone-report-detail-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('Đã kiểm tra cảm biến độ cao'), findsOneWidget);
  });

  testWidgets(
    'assigned drone maintenance appears in my work and requires checklist',
    (tester) async {
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

      expect(service.requestedScheduleTarget, 'DRONE');
      await tester.tap(find.text('Việc của tôi (1)'));
      await tester.pumpAndSettle();
      expect(find.text('Bảo trì pin và cảm biến'), findsOneWidget);
      expect(find.text('Bảo trì'), findsOneWidget);

      await tester.tap(find.text('Định kỳ (1)'));
      await tester.pumpAndSettle();
      expect(find.text('Bảo trì pin và cảm biến'), findsOneWidget);
      await tester.ensureVisible(find.text('Kiểm tra ngay'));
      await tester.pump();
      await tester.tap(find.text('Kiểm tra ngay'));
      await tester.pumpAndSettle();

      expect(find.text('Hạng mục kiểm tra (0/2)'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('inspection-item-0-PASS')));
      await tester.tap(find.byKey(const ValueKey('inspection-item-1-PASS')));
      await tester.pump();
      expect(find.text('Hạng mục kiểm tra (2/2)'), findsOneWidget);
      await tester.ensureVisible(
        find.byKey(const ValueKey('inspection-submit')),
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('inspection-submit')));
      await tester.pumpAndSettle();

      expect(service.completedScheduleId, 71);
      expect(service.completedChecklist, hasLength(2));
      expect(
        service.completedChecklist!.every((item) => item['result'] == 'PASS'),
        isTrue,
      );
    },
  );
}
