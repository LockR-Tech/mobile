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
  List<Map<String, dynamic>> incidents = const [];
  List<Map<String, dynamic>> extraQueue = const [];
  Map<String, dynamic> droneOverride = const {};
  List<Map<String, dynamic>>? customReports;
  List<Map<String, dynamic>>? customDrones;
  List<Map<String, dynamic>>? customSchedules;
  int? advancedOrderId;
  String? advancedExpectedStage;

  @override
  Future<List<Map<String, dynamic>>> droneIncidents() async => incidents;

  /// Chưa có tủ nào có bãi đáp ⇒ thẻ thời tiết các tủ không chiếm chỗ.
  List<Map<String, dynamic>> lockerWeather = const [];

  @override
  Future<List<Map<String, dynamic>>> droneLockerWeather() async =>
      lockerWeather;

  @override
  Future<Map<String, dynamic>> droneRouteWeather(
    int orderId, {
    bool asTechnician = false,
  }) async => {
    'orderId': orderId,
    'weather': {'safe': true, 'status': 'SAFE', 'message': 'An toàn'},
  };

  @override
  Future<Map<String, dynamic>> droneIncident(int incidentId) async =>
      incidents.firstWhere(
        (incident) => incident['id'] == incidentId,
        orElse: () => <String, dynamic>{},
      );

  @override
  Future<Map<String, dynamic>> droneMyPerformance() async => {
    'totalAssigned': 3,
    'inProgress': 0,
    'resolved': 3,
    'overdue': 0,
    'penaltyLevel': 'NORMAL',
    'penaltyReason': 'Hiệu suất hoạt động tốt, không có phiếu trễ hạn.',
    'ratingCount': 0,
    'averageRating': 0.0,
  };

  @override
  Future<Map<String, dynamic>> droneMyRatingAverage() async => {
    'count': 0,
    'average': 0.0,
  };

  @override
  Future<Map<String, dynamic>> advanceDroneOrder(
    int orderId, {
    String? expectedStage,
  }) async {
    advancedOrderId = orderId;
    advancedExpectedStage = expectedStage;
    return {'orderId': orderId};
  }

  @override
  Future<List<Map<String, dynamic>>> droneReports({
    bool mine = false,
    bool routed = false,
    bool all = false,
  }) async {
    if (customReports != null) {
      if (mine) {
        return customReports!
            .where((r) => '${r['assignedToUserId']}' == '99')
            .toList();
      }
      return customReports!;
    }
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
  Future<List<Map<String, dynamic>>> droneUnits() async {
    if (customDrones != null) return customDrones!;
    return [
      {
        'id': 9,
        'code': 'DRONE-09',
        'status': 'IDLE',
        'batteryPercent': 87,
        'lockerId': 3,
        'lockerName': 'Tram 3',
        ...droneOverride,
      },
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> maintenanceSchedules({
    bool mine = false,
    String? target,
  }) async {
    requestedScheduleTarget = target;
    if (customSchedules != null) return customSchedules!;
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
      ...extraQueue,
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
      // Server tự sinh mã niêm phong khi app không gửi.
      'sealCode': sealCode ?? 'NP-261010-SRVSEA',
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

void _setPhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
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
    await tester.tap(find.text('Gán drone'));
    await tester.pumpAndSettle();

    expect(service.acceptedOrderId, equals(21));
    expect(service.acceptedDroneId, equals(9));
  });

  testWidgets('requires full loading checklist before mission is ready', (
    tester,
  ) async {
    _setPhoneViewport(tester);
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
    // Ô cân để trống: phải nhập số đọc trên cân, không lấy sẵn số khai báo.
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('drone-loading-weight')))
          .controller!
          .text,
      isEmpty,
    );
    await tester.enterText(
      find.byKey(const ValueKey('drone-loading-weight')),
      '1450',
    );
    await tester.pump();
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
    // App không tự sinh mã niêm phong; hiện mã server trả về.
    expect(service.loadedSealCode, isNull);
    expect(find.textContaining('NP-261010-SRVSEA'), findsOneWidget);
  });

  testWidgets('shows loading validation inside the dialog', (tester) async {
    _setPhoneViewport(tester);
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
    await tester.tap(find.text('Xác nhận đã nạp'));
    await tester.pump();

    expect(find.text('Xác nhận nạp hàng'), findsOneWidget);
    expect(
      find.text('Vui lòng nhập khối lượng thực tế lớn hơn 0'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('drone-loading-checklist-error')),
      findsOneWidget,
    );
    expect(find.byType(SnackBar), findsNothing);
    expect(service.loadedOrderId, isNull);
  });

  testWidgets('deep link mở đúng tab và phiếu sự cố được nhắc tới', (
    tester,
  ) async {
    final service = _FakeMaintenanceService();
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => MaintenanceHomePage(
            service: service,
            initialTab: 2,
            reportId: 42,
          ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }

    expect(
      find.text('Hồ sơ chi tiết phiếu sự cố kỹ thuật Drone'),
      findsOneWidget,
    );
  });

  testWidgets('tab Điều phối chỉ hiện đơn hàng, không hiện sự cố rơi kiện', (
    tester,
  ) async {
    final service = _FakeMaintenanceService()
      ..incidents = [
        {
          'id': 5,
          'incidentCode': 'INC-5',
          'orderId': 30,
          'orderCode': 'ORD-30',
          'droneCode': 'DRONE-09',
          'status': 'MANUAL_INTERVENTION_REQUIRED',
          'returnFlightStatus': 'MANUAL_INTERVENTION_REQUIRED',
          'createdAt': '2026-10-12T08:00:00Z',
        },
      ];
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

    // Tab Điều phối chỉ tính đơn hàng (3 đơn), không gộp sự cố rơi kiện.
    expect(find.text('Điều phối (3)'), findsOneWidget);
    expect(find.text('Sự cố rơi kiện (1)'), findsNothing);
    expect(
      find.byKey(const ValueKey('drone-incident-manual-return')),
      findsNothing,
    );
    // Header không ghi SLA giả: bậc SLA lấy từ my-performance.
    expect(
      find.text('SLA: Bình thường · Chưa có phiếu đang xử lý'),
      findsOneWidget,
    );
  });

  testWidgets('xác nhận chặng gửi expectedStage; drone gửi tín hiệu thì ẩn nút', (
    tester,
  ) async {
    final service = _FakeMaintenanceService()
      ..extraQueue = [
        {
          'orderId': 24,
          'deliveryStage': 'EN_ROUTE',
          'missionStatus': 'EN_ROUTE',
          'assignedByUserId': 99,
          'droneCode': 'DRONE-09',
          'destinationLockerId': 5,
        },
        {
          'orderId': 25,
          'deliveryStage': 'APPROACHING',
          'missionStatus': 'APPROACHING',
          'assignedByUserId': 99,
          'droneCode': 'DRONE-11',
          'destinationLockerId': 6,
          'liveTracking': true,
        },
      ];
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

    // Danh sách dựng lười: cuộn tới thẻ đơn đang bay.
    final dispatchList = find
        .byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down,
        )
        .first;
    final advance = find.text('Xác nhận drone sắp tới tủ nhận');
    await tester.scrollUntilVisible(advance, 150, scrollable: dispatchList);
    await tester.pumpAndSettle();
    await tester.tap(advance);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Xác nhận'));
    await tester.pumpAndSettle();

    expect(service.advancedOrderId, 24);
    expect(service.advancedExpectedStage, 'EN_ROUTE');

    // Đơn 25 đang gửi telemetry: chỉ hiện nhãn tự cập nhật, không có nút xác nhận.
    const liveLabel = 'Drone đang gửi tín hiệu · chặng bay tự cập nhật';
    await tester.scrollUntilVisible(
      find.text(liveLabel),
      150,
      scrollable: dispatchList,
    );
    await tester.pumpAndSettle();
    expect(find.text(liveLabel), findsOneWidget);
    expect(find.text('Xác nhận drone đã tới tủ nhận'), findsNothing);
  });

  testWidgets('drone còn phiếu mở thì không cho chọn Sẵn sàng', (tester) async {
    final service = _FakeMaintenanceService()
      ..droneOverride = {
        'status': 'FAULT',
        'assignedTechnicianId': 99,
        'assignedTechnicianName': 'KTV phụ trách 99',
      };
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
    await tester.tap(find.text('Đội bay (1)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('KTV phụ trách 99'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đổi trạng thái'));
    await tester.pumpAndSettle();

    expect(find.text('Đổi trạng thái drone'), findsOneWidget);
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Sẵn sàng'))
          .onSelected,
      isNull,
    );
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Đang bảo trì'))
          .onSelected,
      isNotNull,
    );
    expect(find.textContaining('RPT-42'), findsOneWidget);
  });

  testWidgets('cân nặng hơn khai báo: báo trước khoản khách phải trả thêm', (
    tester,
  ) async {
    _setPhoneViewport(tester);
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

      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

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

  testWidgets(
    'dispatch shows pickup work that currently keeps the drone technician busy',
    (tester) async {
      final service = _FakeMaintenanceService()
        ..extraQueue = [
          {
            'orderId': 31,
            'orderCode': 'ORD-31',
            'deliveryStage': 'PICKUP_ASSIGNED',
            'parcelCategory': 'DOCUMENT',
            'parcelWeightGrams': 800,
            'sender': {'name': 'Nguoi gui A', 'phone': '0901000001'},
            'pickup': {'status': 'ACCEPTED', 'address': '12 Nguyen Hue'},
          },
          {
            'orderId': 32,
            'orderCode': 'ORD-32',
            'deliveryStage': 'PICKED_UP',
            'parcelCategory': 'FOOD',
            'parcelWeightGrams': 1200,
            'sourceLocker': {'name': 'Tu gui A'},
            'pickup': {'status': 'PICKED_UP', 'address': '20 Le Loi'},
          },
        ];
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

      expect(find.text('Đang đi lấy hàng (1)'), findsOneWidget);
      expect(find.text('Đã lấy hàng · chờ nạp trực tiếp lên drone (1)'), findsOneWidget);
      expect(find.text('Điều phối (5)'), findsOneWidget);
    },
  );

  testWidgets('tab Đội bay chỉ hiện drone mà mình được phụ trách', (tester) async {
    _setPhoneViewport(tester);
    final service = _FakeMaintenanceService()
      ..customDrones = [
        {
          'id': 1,
          'code': 'DRONE-MY-01',
          'status': 'IDLE',
          'batteryPercent': 95,
          'assignedTechnicianId': 99,
          'assignedTechnicianName': 'KTV 99',
        },
        {
          'id': 2,
          'code': 'DRONE-OTHER-02',
          'status': 'IDLE',
          'batteryPercent': 80,
          'assignedTechnicianId': 88,
          'assignedTechnicianName': 'KTV 88',
        },
        {
          'id': 3,
          'code': 'DRONE-FREE-03',
          'status': 'IDLE',
          'batteryPercent': 70,
          'assignedTechnicianId': null,
        },
      ];
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

    // Tab Đội bay và HUD chip chỉ đếm drone của mình (1 drone)
    expect(find.text('Đội bay (1)'), findsOneWidget);
    await tester.tap(find.text('Đội bay (1)'));
    await tester.pumpAndSettle();

    expect(find.text('DRONE-MY-01'), findsOneWidget);
    expect(find.text('DRONE-OTHER-02'), findsNothing);
    expect(find.text('DRONE-FREE-03'), findsNothing);
  });

  testWidgets(
    'sự cố mới trên drone có KTV phụ trách: chỉ hiển thị cho KTV phụ trách đó xem và nhận việc',
    (tester) async {
      _setPhoneViewport(tester);
      final service = _FakeMaintenanceService()
        ..customDrones = [
          {
            'id': 10,
            'code': 'DRONE-10',
            'status': 'FAULT',
            'assignedTechnicianId': 99,
          },
          {
            'id': 20,
            'code': 'DRONE-20',
            'status': 'FAULT',
            'assignedTechnicianId': 88,
          },
        ]
        ..customReports = [
          {
            'id': 101,
            'title': 'Lỗi motor Drone 10',
            'description': 'Motor số 2 kêu to',
            'status': 'OPEN',
            'category': 'DRONE',
            'droneUnitId': 10,
            'droneCode': 'DRONE-10',
            'assignedToUserId': null,
            'createdAt': '2026-10-10T08:00:00Z',
          },
          {
            'id': 201,
            'title': 'Lỗi cánh quạt Drone 20',
            'description': 'Cánh nứt',
            'status': 'OPEN',
            'category': 'DRONE',
            'droneUnitId': 20,
            'droneCode': 'DRONE-20',
            'assignedToUserId': null,
            'createdAt': '2026-10-10T08:00:00Z',
          },
        ];
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

      // Chỉ thấy 1 sự cố của Drone-10 (do KTV 99 phụ trách)
      expect(find.text('Sự cố (1)'), findsOneWidget);
      await tester.tap(find.text('Sự cố (1)'));
      await tester.pumpAndSettle();

      expect(find.text('Lỗi motor Drone 10'), findsOneWidget);
      expect(find.text('Lỗi cánh quạt Drone 20'), findsNothing);
      expect(find.text('Nhận xử lý'), findsOneWidget);
    },
  );

  testWidgets(
    'sự cố mới trên drone chưa có KTV phụ trách: hiển thị cho tất cả KTV xem và nhận',
    (tester) async {
      _setPhoneViewport(tester);
      final service = _FakeMaintenanceService()
        ..customDrones = [
          {
            'id': 30,
            'code': 'DRONE-30',
            'status': 'FAULT',
            'assignedTechnicianId': null,
          },
        ]
        ..customReports = [
          {
            'id': 301,
            'title': 'Sự cố nguồn Drone 30',
            'description': 'Pin tụt nhanh',
            'status': 'OPEN',
            'category': 'DRONE',
            'droneUnitId': 30,
            'droneCode': 'DRONE-30',
            'assignedToUserId': null,
            'createdAt': '2026-10-10T08:00:00Z',
          },
        ];
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

      expect(find.text('Sự cố (1)'), findsOneWidget);
      await tester.tap(find.text('Sự cố (1)'));
      await tester.pumpAndSettle();

      expect(find.text('Sự cố nguồn Drone 30'), findsOneWidget);
      expect(find.text('Nhận xử lý'), findsOneWidget);
    },
  );

  testWidgets(
    'sự cố đã có người nhận: chỉ hiển thị cho người đã nhận, ẩn với người khác',
    (tester) async {
      _setPhoneViewport(tester);
      final service = _FakeMaintenanceService()
        ..customDrones = [
          {
            'id': 10,
            'code': 'DRONE-10',
            'status': 'IN_SERVICE',
            'assignedTechnicianId': 99,
          },
        ]
        ..customReports = [
          {
            'id': 101,
            'title': 'Phiếu đã nhận bởi KTV khác',
            'description': 'KTV 88 đang xử lý',
            'status': 'IN_PROGRESS',
            'category': 'DRONE',
            'droneUnitId': 10,
            'droneCode': 'DRONE-10',
            'assignedToUserId': 88,
            'createdAt': '2026-10-10T08:00:00Z',
          },
          {
            'id': 102,
            'title': 'Phiếu đã nhận bởi tôi',
            'description': 'Tôi đang xử lý',
            'status': 'IN_PROGRESS',
            'category': 'DRONE',
            'droneUnitId': 10,
            'droneCode': 'DRONE-10',
            'assignedToUserId': 99,
            'createdAt': '2026-10-10T08:00:00Z',
          },
        ];
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

      // Chỉ hiển thị phiếu 102 được nhận bởi 99, ẩn phiếu 101 được nhận bởi 88
      expect(find.text('Sự cố (1)'), findsOneWidget);
      await tester.tap(find.text('Sự cố (1)'));
      await tester.pumpAndSettle();

      expect(find.text('Phiếu đã nhận bởi tôi'), findsOneWidget);
      expect(find.text('Phiếu đã nhận bởi KTV khác'), findsNothing);
    },
  );

  testWidgets(
    'sự cố rơi kiện: hiển thị trong tab Sự cố theo đúng phân quyền (chưa nhận/đã nhận/phụ trách drone)',
    (tester) async {
      _setPhoneViewport(tester);
      final service = _FakeMaintenanceService()
        ..customDrones = [
          {
            'id': 10,
            'code': 'DRONE-10',
            'status': 'IN_SERVICE',
            'assignedTechnicianId': 99,
          },
          {
            'id': 20,
            'code': 'DRONE-20',
            'status': 'IN_SERVICE',
            'assignedTechnicianId': 88,
          },
          {
            'id': 30,
            'code': 'DRONE-30',
            'status': 'IN_SERVICE',
            'assignedTechnicianId': null,
          },
        ]
        ..incidents = [
          // Case 1: Sự cố mới trên Drone 10 (do KTV 99 phụ trách) -> KTV 99 PHẢI thấy
          {
            'id': 1,
            'incidentCode': 'INC-01',
            'orderId': 101,
            'orderCode': 'ORD-101',
            'droneCode': 'DRONE-10',
            'droneUnitId': 10,
            'status': 'REPORTED',
            'returnFlightStatus': 'COMMAND_ACCEPTED',
            'createdAt': '2026-10-12T08:00:00Z',
          },
          // Case 2: Sự cố mới trên Drone 20 (do KTV 88 phụ trách) -> KTV 99 KHÔNG được thấy
          {
            'id': 2,
            'incidentCode': 'INC-02',
            'orderId': 102,
            'orderCode': 'ORD-102',
            'droneCode': 'DRONE-20',
            'droneUnitId': 20,
            'status': 'REPORTED',
            'returnFlightStatus': 'COMMAND_ACCEPTED',
            'createdAt': '2026-10-12T08:00:00Z',
          },
          // Case 3: Sự cố mới trên Drone 30 (chưa ai phụ trách) -> KTV 99 PHẢI thấy trong hàng chờ
          {
            'id': 3,
            'incidentCode': 'INC-03',
            'orderId': 103,
            'orderCode': 'ORD-103',
            'droneCode': 'DRONE-30',
            'droneUnitId': 30,
            'status': 'REPORTED',
            'returnFlightStatus': 'COMMAND_ACCEPTED',
            'createdAt': '2026-10-12T08:00:00Z',
          },
          // Case 4: Sự cố trên Drone 10 nhưng đã có KTV 88 nhận -> KTV 99 KHÔNG được thấy
          {
            'id': 4,
            'incidentCode': 'INC-04',
            'orderId': 104,
            'orderCode': 'ORD-104',
            'droneCode': 'DRONE-10',
            'droneUnitId': 10,
            'recoveryAssignedToUserId': 88,
            'status': 'INVESTIGATING',
            'returnFlightStatus': 'COMMAND_ACCEPTED',
            'createdAt': '2026-10-12T08:00:00Z',
          },
          // Case 5: Sự cố trên Drone 20 nhưng do KTV 99 đã nhận -> KTV 99 PHẢI thấy
          {
            'id': 5,
            'incidentCode': 'INC-05',
            'orderId': 105,
            'orderCode': 'ORD-105',
            'droneCode': 'DRONE-20',
            'droneUnitId': 20,
            'recoveryAssignedToUserId': 99,
            'status': 'INVESTIGATING',
            'returnFlightStatus': 'COMMAND_ACCEPTED',
            'createdAt': '2026-10-12T08:00:00Z',
          },
        ]
        ..customReports = const [];

      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => MaintenanceHomePage(
              service: service,
              initialTab: 2,
            ),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      // Chỉ có 3 sự cố hiển thị với KTV 99 (INC-01, INC-03, INC-05)
      expect(find.text('Sự cố (3)'), findsOneWidget);
      expect(find.text('Sự cố rơi kiện (3)'), findsOneWidget);

      expect(find.textContaining('INC-01'), findsOneWidget);
      expect(find.textContaining('INC-02'), findsNothing);
      expect(find.textContaining('INC-03'), findsOneWidget);
      expect(find.textContaining('INC-04'), findsNothing);
      expect(find.textContaining('INC-05'), findsOneWidget);
    },
  );

  testWidgets(
    'tab Định kỳ chỉ lấy và hiển thị danh sách lịch do chính KTV đó phụ trách',
    (tester) async {
      _setPhoneViewport(tester);
      final service = _FakeMaintenanceService()
        ..customSchedules = [
          {
            'id': 701,
            'droneUnitId': 9,
            'droneCode': 'DRONE-09',
            'title': 'Bảo trì động cơ DRONE-09 (của tôi)',
            'description': 'Kiểm tra motor',
            'priority': 'HIGH',
            'intervalDays': 15,
            'nextDueAt': '2026-10-09T08:00:00Z',
            'due': true,
            'active': true,
            'assignedTechnicianId': 99,
            'assignedTechnicianName': 'Bảo Huy Nguyễn',
            'checklistItems': ['Motor 1', 'Motor 2'],
          },
          {
            'id': 702,
            'droneUnitId': 10,
            'droneCode': 'DRONE-10',
            'title': 'Bảo trì cánh quạt DRONE-10 (của KTV khác)',
            'description': 'Kiểm tra cánh quạt',
            'priority': 'NORMAL',
            'intervalDays': 30,
            'nextDueAt': '2026-10-15T08:00:00Z',
            'due': false,
            'active': true,
            'assignedTechnicianId': 88,
            'assignedTechnicianName': 'KTV Khác',
            'checklistItems': ['Cánh quạt'],
          },
        ];

      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => MaintenanceHomePage(
              service: service,
              initialTab: 4,
            ),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      // Tab text chỉ tính lịch của mình: 1 lịch
      expect(find.text('Định kỳ (1)'), findsOneWidget);

      // Hiển thị lịch của tôi, không hiển thị lịch của KTV khác
      expect(find.text('Bảo trì động cơ DRONE-09 (của tôi)'), findsOneWidget);
      expect(
        find.text('Bảo trì cánh quạt DRONE-10 (của KTV khác)'),
        findsNothing,
      );

      // Filter chips hiển thị số lượng theo danh sách của KTV
      expect(find.text('Tất cả (1)'), findsOneWidget);
      expect(find.text('Đến hạn (1)'), findsOneWidget);
      expect(find.text('Sắp tới (0)'), findsOneWidget);

      // Không còn toggle chip "Của tôi" / "Tất cả"
      expect(find.text('Của tôi (1)'), findsNothing);
    },
  );
}
