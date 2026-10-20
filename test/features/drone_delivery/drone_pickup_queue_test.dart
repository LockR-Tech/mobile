import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/widgets/drone_pickup_queue.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';

import '../../helpers/test_helpers.dart';

/// Ghi lại các lệnh gọi; không đụng mạng.
class _FakeService extends LockerOpsService {
  _FakeService() : super(dio: createMockDio().dio);

  Map<String, dynamic> presence = {'onDuty': false, 'busy': false};
  final calls = <String>[];
  Object? acceptError;

  @override
  Future<Map<String, dynamic>> droneTechnicianPresence() async => presence;

  @override
  Future<Map<String, dynamic>> updateDroneTechnicianPresence({
    bool? onDuty,
    double? latitude,
    double? longitude,
  }) async {
    calls.add('presence onDuty=$onDuty lat=$latitude lng=$longitude');
    presence = {
      'onDuty': onDuty ?? presence['onDuty'],
      'busy': false,
      'locationAt': '2026-10-12T03:00:00',
    };
    return presence;
  }

  @override
  Future<Map<String, dynamic>> acceptDronePickup(int orderId) async {
    if (acceptError != null) throw acceptError!;
    calls.add('accept $orderId');
    return {};
  }

  @override
  Future<Map<String, dynamic>> declineDronePickup(int orderId) async {
    calls.add('decline $orderId');
    return {};
  }

  @override
  Future<Map<String, dynamic>> confirmDronePickup(
    int orderId, {
    required String pickupCode,
    required Map<String, dynamic> pickupPhoto,
    String? note,
  }) async {
    calls.add('confirm $orderId code=$pickupCode');
    return {};
  }

  @override
  Future<Map<String, dynamic>> failDronePickup(
    int orderId, {
    required String reason,
    String? note,
  }) async {
    calls.add('pickup-fail $orderId $reason note=$note');
    return {};
  }

  @override
  Future<Map<String, dynamic>> failDroneOrder(
    int orderId, {
    String? reason,
    String? note,
  }) async {
    calls.add('fail $orderId $reason note=$note');
    return {};
  }
}

Map<String, dynamic> _order(
  int id,
  String pickupStatus,
  String stage, {
  Map<String, dynamic>? block,
}) => {
  'orderId': id,
  'orderCode': 'ORD-$id',
  'deliveryStage': stage,
  'parcelWeightGrams': 1200,
  'parcelCategory': 'DOCUMENT',
  'fragile': true,
  'sourceLockerId': 3,
  'sourceLocker': {
    'name': 'Locker A',
    'address': '1 Lê Lợi',
    'latitude': 10.701,
    'longitude': 106.7,
  },
  'sender': {
    'name': 'Nguyễn Văn Gửi',
    'phone': '0901000111',
    'email': 'gui@gmail.com',
  },
  'pickup': {
    'status': pickupStatus,
    'address': '12 Nguyễn Huệ',
    'latitude': 10.7,
    'longitude': 106.7,
    'note': 'Gọi trước',
    'technicianDistanceMeters': 850,
    'offerExpiresAt': DateTime.now()
        .toUtc()
        .add(const Duration(minutes: 2))
        .toIso8601String(),
  },
  if (block != null) 'block': block,
};

void main() {
  setUp(() => useBusinessConfig());

  late _FakeService service;
  late int reloads;
  Map<String, dynamic>? assigned;

  setUp(() {
    service = _FakeService();
    reloads = 0;
    assigned = null;
  });

  Future<void> pump(
    WidgetTester tester,
    List<Map<String, dynamic>> deliveries, {
    (LatLng?, String?) position = (const LatLng(10.7001, 106.7001), null),
  }) async {
    tester.view.physicalSize = const Size(1000, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DronePickupQueue(
              service: service,
              deliveries: deliveries,
              onChanged: () async => reloads++,
              onOpenDetail: (_) {},
              onAssignDrone: (order) => assigned = order,
              readPosition: () async => position,
              // Không cần gửi vị trí định kỳ trong test.
              locationInterval: const Duration(days: 1),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('vào ca phải kèm vị trí hiện tại; ra ca thì thôi được mời', (
    tester,
  ) async {
    await pump(tester, const []);
    expect(find.text('Chưa vào ca lấy hàng'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('drone-duty-switch')));
    await tester.pump();
    await tester.pump();

    expect(service.calls, ['presence onDuty=true lat=10.7001 lng=106.7001']);
    expect(find.text('Đang nhận việc lấy hàng'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('drone-duty-switch')));
    await tester.pump();
    await tester.pump();
    expect(service.calls.last, 'presence onDuty=false lat=null lng=null');
  });

  testWidgets('không có GPS thì không vào ca được', (tester) async {
    await pump(
      tester,
      const [],
      position: (null, 'Dịch vụ vị trí đang tắt. Vui lòng bật GPS.'),
    );

    await tester.tap(find.byKey(const ValueKey('drone-duty-switch')));
    await tester.pump();
    await tester.pump();

    expect(service.calls, isEmpty);
    expect(
      find.text('Dịch vụ vị trí đang tắt. Vui lòng bật GPS.'),
      findsOneWidget,
    );
    expect(find.text('Chưa vào ca lấy hàng'), findsOneWidget);
  });

  testWidgets(
    'lời mời: thấy địa chỉ, khoảng cách, kiện, hạn trả lời; nhận hoặc từ chối',
    (tester) async {
      await pump(tester, [
        _order(21, 'OFFERED', 'AWAITING_DISPATCH'),
        _order(22, 'OFFERED', 'AWAITING_DISPATCH'),
      ]);

      expect(find.text('Lời mời lấy hàng (2)'), findsOneWidget);
      expect(find.text('Lấy tại: 12 Nguyễn Huệ'), findsNWidgets(2));
      expect(find.textContaining('Cách bạn 850 m'), findsNWidgets(2));
      expect(find.textContaining('DỄ VỠ'), findsNWidgets(2));
      expect(find.textContaining('Trả lời còn 1:'), findsNWidgets(2));

      await tester.tap(find.byKey(const ValueKey('drone-pickup-accept-21')));
      await tester.pump();
      await tester.pump();
      expect(service.calls, ['accept 21']);
      expect(reloads, 1);

      await tester.tap(find.byKey(const ValueKey('drone-pickup-decline-22')));
      await tester.pump();
      await tester.pump();
      expect(service.calls.last, 'decline 22');
    },
  );

  testWidgets(
    'đang đi lấy hàng: cần đúng 6 số mã lấy hàng và xác nhận kiện đúng khai báo',
    (tester) async {
      await pump(tester, [_order(21, 'ACCEPTED', 'PICKUP_ASSIGNED')]);

      expect(find.text('Đang đi lấy hàng (1)'), findsOneWidget);
      expect(
        find.text('Người gửi: Nguyễn Văn Gửi · 0901000111'),
        findsOneWidget,
      );
      expect(find.text('Chỉ dẫn: Gọi trước'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('drone-pickup-done-21')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('drone-pickup-code-input')),
        '123',
      );
      await tester.tap(find.byKey(const ValueKey('drone-pickup-confirm')));
      await tester.pumpAndSettle();
      expect(find.text('Nhập đủ 6 chữ số'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('drone-pickup-code-input')),
        '123456',
      );
      await tester.tap(find.byKey(const ValueKey('drone-pickup-confirm')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Cần xác nhận kiện đúng khai báo'),
        findsOneWidget,
      );
      expect(service.calls, isEmpty);

      await tester.tap(find.byKey(const ValueKey('drone-pickup-matched')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('drone-pickup-confirm')));
      await tester.pumpAndSettle();
      expect(find.text('Cần chụp ảnh kiện trước khi xác nhận'), findsOneWidget);
      expect(service.calls, isEmpty);
    },
  );

  testWidgets(
    'không lấy được hàng: chọn lý do, lý do "Khác" bắt buộc ghi chú',
    (tester) async {
      await pump(tester, [_order(21, 'ACCEPTED', 'PICKUP_ASSIGNED')]);

      await tester.tap(find.byKey(const ValueKey('drone-pickup-fail-21')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('drone-reason-OTHER')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('drone-reason-confirm')));
      await tester.pumpAndSettle();
      expect(find.text('Cần nhập ghi chú cho lý do này'), findsOneWidget);
      expect(service.calls, isEmpty);

      await tester.tap(
        find.byKey(const ValueKey('drone-reason-PICKUP_CUSTOMER_ABSENT')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('drone-reason-note')),
        'Gọi 3 lần không nghe',
      );
      await tester.tap(find.byKey(const ValueKey('drone-reason-confirm')));
      await tester.pumpAndSettle();

      expect(service.calls, [
        'pickup-fail 21 PICKUP_CUSTOMER_ABSENT note=Gọi 3 lần không nghe',
      ]);
    },
  );

  testWidgets(
    'đã lấy hàng: mang về tủ gửi, gán drone, hoặc đóng đơn theo lý do đang chặn',
    (tester) async {
      await pump(tester, [
        _order(
          21,
          'PICKED_UP',
          'PICKED_UP',
          block: {
            'reason': 'WEATHER',
            'reasonLabel': 'Tạm dừng bay do thời tiết',
            'ticketId': 77,
          },
        ),
        // Đã gán drone rồi (chặng ACCEPTED) thì không còn ở mục "mang về tủ".
        _order(22, 'PICKED_UP', 'ACCEPTED'),
      ]);

      expect(
        find.text('Đã lấy hàng · chờ nạp trực tiếp lên drone (1)'),
        findsOneWidget,
      );
      expect(find.text('Mang kiện tới drone tại: Locker A'), findsOneWidget);
      expect(
        find.text('Đang gặp sự cố: Tạm dừng bay do thời tiết · phiếu #77'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('drone-assign-drone-21')));
      expect(assigned!['orderId'], 21);

      await tester.tap(find.byKey(const ValueKey('drone-delivery-fail-21')));
      await tester.pumpAndSettle();
      // Lý do đang chặn đơn được chọn sẵn.
      await tester.tap(find.byKey(const ValueKey('drone-reason-confirm')));
      await tester.pumpAndSettle();
      expect(service.calls, ['fail 21 WEATHER note=null']);
    },
  );

  testWidgets('lời mời đã hết hạn ở server: báo lỗi và nạp lại danh sách', (
    tester,
  ) async {
    service.acceptError = StateError('expired');
    await pump(tester, [_order(21, 'OFFERED', 'AWAITING_DISPATCH')]);

    await tester.tap(find.byKey(const ValueKey('drone-pickup-accept-21')));
    await tester.pump();
    await tester.pump();

    expect(service.calls, isEmpty);
    expect(reloads, 1);
    expect(find.byType(SnackBar), findsOneWidget);
  });
}
