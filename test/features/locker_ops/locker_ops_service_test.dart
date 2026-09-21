import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';

import '../../helpers/test_helpers.dart';

void main() {
  late LockerOpsService service;
  late DioAdapter adapter;

  setUp(() {
    final mock = createMockDio();
    adapter = mock.adapter;
    service = LockerOpsService(dio: mock.dio);
  });

  // ── LOCKER_TECHNICIAN ─────────────────────────────────────────────────────

  group('LOCKER_TECHNICIAN endpoints', () {
    group('techDevices()', () {
      test('returns device list with status', () async {
        adapter.onGet(
          '/api/locker-technician/devices',
          (server) => server.reply(
            200,
            apiOk([
              {
                'id': 1,
                'deviceId': 'DEV-001',
                'lockerId': 10,
                'status': 'ONLINE',
                'lastSeenAt': '2026-06-22T10:00:00',
              },
              {
                'id': 2,
                'deviceId': 'DEV-002',
                'lockerId': 11,
                'status': 'OFFLINE',
                'lastSeenAt': '2026-06-21T09:00:00',
              },
            ]),
          ),
        );

        final result = await service.techDevices();
        expect(result, hasLength(2));
        expect(result.first['status'], equals('ONLINE'));
        expect(result.last['status'], equals('OFFLINE'));
      });

      test('returns empty list when no devices', () async {
        adapter.onGet(
          '/api/locker-technician/devices',
          (server) => server.reply(200, apiOk([])),
        );

        final result = await service.techDevices();
        expect(result, isEmpty);
      });
    });

    group('techDeviceDetail()', () {
      test('returns device detail map', () async {
        adapter.onGet(
          '/api/locker-technician/devices/1',
          (server) => server.reply(
            200,
            apiOk({
              'id': 1,
              'deviceId': 'DEV-001',
              'lockerId': 10,
              'status': 'ONLINE',
              'model': 'RPi-4B',
              'firmwareVersion': '2.1.0',
              'lastSeenAt': '2026-06-22T10:00:00',
            }),
          ),
        );

        final result = await service.techDeviceDetail(1);
        expect(result['deviceId'], equals('DEV-001'));
        expect(result['model'], equals('RPi-4B'));
        expect(result['status'], equals('ONLINE'));
      });
    });

    group('techDeviceLogs()', () {
      test('returns audit log entries', () async {
        adapter.onGet(
          '/api/locker-technician/devices/1/logs',
          (server) => server.reply(
            200,
            apiOk([
              {
                'id': 1,
                'result': 'UNLOCK_SUCCESS',
                'message': 'Box 3 opened',
                'createdAt': '2026-06-22T09:30:00',
              },
              {
                'id': 2,
                'result': 'RESTART_REQUESTED',
                'message': 'Technician restart',
                'createdAt': '2026-06-22T08:00:00',
              },
            ]),
          ),
        );

        final result = await service.techDeviceLogs(1);
        expect(result, hasLength(2));
        expect(result.first['result'], equals('UNLOCK_SUCCESS'));
        expect(result.last['result'], equals('RESTART_REQUESTED'));
      });
    });

    group('techUpdateStatus()', () {
      test('completes without throwing on success', () async {
        adapter.onPut(
          '/api/locker-technician/devices/1/status',
          (server) => server.reply(
            200,
            apiOk({
              'id': 1,
              'status': 'OFFLINE',
              'lastSeenAt': '2026-06-22T10:05:00',
            }),
          ),
        );

        await expectLater(service.techUpdateStatus(1, 'OFFLINE'), completes);
      });
    });

    group('techRestartDevice()', () {
      test('completes without throwing on success', () async {
        adapter.onPost(
          '/api/locker-technician/devices/1/restart',
          (server) =>
              server.reply(200, apiOk({'deviceId': 'DEV-001', 'lockerId': 10})),
        );

        await expectLater(service.techRestartDevice(1), completes);
      });
    });
  });

  // ── /api/locker-technician (việc của KTV tủ) ──────────────────────────────

  group('/api/locker-technician endpoints', () {
    test('faults() returns fault cell list', () async {
      adapter.onGet(
        '/api/locker-technician/faults',
        (server) => server.reply(
          200,
          apiOk([
            {
              'boxId': 5,
              'boxNumber': 5,
              'lockerId': 1,
              'lockerName': 'Tủ A1',
              'faultReason': 'Khóa kẹt',
            },
          ]),
        ),
      );

      final result = await service.faults();
      expect(result.first['faultReason'], equals('Khóa kẹt'));
    });

    test('claimReport() returns updated report', () async {
      adapter.onPut(
        '/api/locker-technician/reports/42/claim',
        (server) =>
            server.reply(200, apiOk({'id': 42, 'status': 'IN_PROGRESS'})),
      );

      final result = await service.claimReport(42);
      expect(result['status'], equals('IN_PROGRESS'));
    });

    test('resolveReport() returns resolved report', () async {
      adapter.onPut(
        '/api/locker-technician/reports/42/resolve',
        (server) => server.reply(200, apiOk({'id': 42, 'status': 'RESOLVED'})),
      );

      final result = await service.resolveReport(42);
      expect(result['status'], equals('RESOLVED'));
    });

    test('clearFault() succeeds', () async {
      adapter.onPost(
        '/api/locker-technician/boxes/5/clear-fault',
        (server) => server.reply(200, apiOk(null)),
      );

      await expectLater(service.clearFault(5), completes);
    });

    test('forceOpenBox() succeeds', () async {
      adapter.onPost(
        '/api/locker-technician/boxes/5/force-open',
        (server) => server.reply(200, apiOk(null)),
      );

      await expectLater(service.forceOpenBox(5), completes);
    });
  });

  // ── DRONE_TECHNICIAN — drone fleet ────────────────────────────────────────

  group('Drone fleet endpoints', () {
    test('droneUnits() returns fleet list', () async {
      adapter.onGet(
        '/api/drone-technician/drones',
        (server) => server.reply(
          200,
          apiOk([
            {
              'id': 1,
              'code': 'DRONE-01',
              'status': 'IDLE',
              'batteryPercent': 90,
              'lockerId': 1,
            },
            {
              'id': 2,
              'code': 'DRONE-02',
              'status': 'IN_FLIGHT',
              'batteryPercent': 55,
              'lockerId': 2,
            },
          ]),
        ),
      );

      final result = await service.droneUnits();
      expect(result, hasLength(2));
      expect(result.first['code'], equals('DRONE-01'));
      expect(result.last['status'], equals('IN_FLIGHT'));
    });

    test('updateDroneStatus() returns updated drone', () async {
      adapter.onPost(
        '/api/drone-technician/drones/1/status',
        (server) => server.reply(200, apiOk({'id': 1, 'status': 'CHARGING'})),
      );

      final result = await service.updateDroneStatus(1, 'CHARGING');
      expect(result['status'], equals('CHARGING'));
    });

    test('updateDroneBattery() returns updated drone', () async {
      adapter.onPost(
        '/api/drone-technician/drones/1/battery',
        (server) => server.reply(200, apiOk({'id': 1, 'batteryPercent': 40})),
      );

      final result = await service.updateDroneBattery(1, 40);
      expect(result['batteryPercent'], equals(40));
    });

    test('droneOrderQueue() returns order-based maintenance queue', () async {
      adapter.onGet(
        '/api/drone-technician/drone-orders',
        (server) => server.reply(
          200,
          apiOk([
            {
              'orderId': 21,
              'missionId': null,
              'missionStatus': null,
              'deliveryStage': 'AWAITING_DISPATCH',
              'destinationLockerId': 5,
              'reservedBoxId': 9001,
              'description': 'Tai lieu khan',
            },
          ]),
        ),
      );

      final result = await service.droneOrderQueue();
      expect(result, hasLength(1));
      expect(result.first['orderId'], equals(21));
      expect(result.first['deliveryStage'], equals('AWAITING_DISPATCH'));
    });

    test(
      'acceptDroneOrder() posts to order-based maintenance endpoint',
      () async {
        adapter.onPost(
          '/api/drone-technician/drone-orders/21/accept',
          (server) => server.reply(
            202,
            apiOk({
              'orderId': 21,
              'missionId': 301,
              'missionStatus': 'READY_TO_LAUNCH',
              'deliveryStage': 'ACCEPTED',
              'droneUnitId': 9,
              'droneCode': 'DRONE-09',
            }),
          ),
        );

        final result = await service.acceptDroneOrder(
          21,
          droneUnitId: 9,
          idempotencyKey: 'accept-1',
        );

        expect(result['missionId'], equals(301));
        expect(result['deliveryStage'], equals('ACCEPTED'));
        expect(result['droneCode'], equals('DRONE-09'));
      },
    );

    test('launchDroneOrder() posts to launch endpoint', () async {
      adapter.onPost(
        '/api/drone-technician/drone-orders/21/launch',
        (server) => server.reply(
          202,
          apiOk({
            'orderId': 21,
            'missionId': 301,
            'missionStatus': 'LAUNCHING',
            'deliveryStage': 'LAUNCHING',
            'droneUnitId': 9,
            'droneCode': 'DRONE-09',
          }),
        ),
      );

      final result = await service.launchDroneOrder(
        21,
        idempotencyKey: 'launch-1',
      );

      expect(result['missionStatus'], equals('LAUNCHING'));
      expect(result['deliveryStage'], equals('LAUNCHING'));
    });

    test(
      'cancelDroneOrder() posts reason code and optional note to cancel endpoint',
      () async {
        adapter.onPost(
          '/api/drone-technician/drone-orders/22/cancel',
          (server) {
            return server.reply(
              200,
              apiOk({
                'orderId': 22,
                'missionId': 302,
                'missionStatus': 'CANCELED',
                'deliveryStage': 'CANCELED',
              }),
            );
          },
          data: {'reasonCode': 5, 'note': 'Gio giat manh'},
        );

        final result = await service.cancelDroneOrder(
          22,
          reasonCode: 5,
          note: 'Gio giat manh',
        );

        expect(result['missionStatus'], equals('CANCELED'));
        expect(result['deliveryStage'], equals('CANCELED'));
      },
    );
  });

  // ── CUSTOMER — Order flow ────────────────────────────────────────────────

  group('CUSTOMER order flow', () {
    test('createDroneDeliveryOrder() posts to order-based endpoint', () async {
      adapter.onPost(
        '/api/orders/drone-deliveries',
        (server) => server.reply(
          200,
          apiOk({
            'orderId': 77,
            'reservedBoxId': 9001,
            'type': 'DRONE_DELIVERY',
            'deliveryStage': 'AWAITING_DISPATCH',
          }),
        ),
      );

      final result = await service.createDroneDeliveryOrder(
        destinationLockerId: 5,
        preferredBoxId: 9001,
        description: 'Tai lieu',
        parcelWeightGrams: 1200,
        paymentMethod: 'CASH',
        idempotencyKey: 'idem-1',
      );

      expect(result['orderId'], equals(77));
      expect(result['reservedBoxId'], equals(9001));
      expect(result['deliveryStage'], equals('AWAITING_DISPATCH'));
    });

    test('myOrders() returns order list', () async {
      adapter.onGet(
        '/api/orders/my-orders',
        (server) => server.reply(
          200,
          apiOk([
            {
              'id': 300,
              'type': 'SEND',
              'status': 'INITIALIZED',
              'paymentStatus': 'UNPAID',
              'totalPrice': 15000,
            },
            {
              'id': 301,
              'type': 'RENTAL',
              'status': 'STORING',
              'paymentStatus': 'PAID',
              'totalPrice': 30000,
            },
          ]),
        ),
      );

      final result = await service.myOrders();
      expect(result, hasLength(2));
      expect(result.first['paymentStatus'], equals('UNPAID'));
    });

    test('confirmDrop() returns updated order', () async {
      adapter.onPut(
        '/api/orders/300/confirm',
        (server) => server.reply(200, apiOk({'id': 300, 'status': 'STORING'})),
      );

      final result = await service.confirmDrop(300);
      expect(result['status'], equals('STORING'));
    });

    test('completePickup() returns completed order', () async {
      adapter.onPut(
        '/api/orders/300/complete',
        (server) =>
            server.reply(200, apiOk({'id': 300, 'status': 'COMPLETED'})),
      );

      final result = await service.completePickup(300);
      expect(result['status'], equals('COMPLETED'));
    });

    test('cancelOrder() succeeds', () async {
      adapter.onPut(
        '/api/orders/300/cancel',
        (server) => server.reply(200, apiOk(null)),
      );

      await expectLater(service.cancelOrder(300), completes);
    });
  });

  // ── PAYMENT ──────────────────────────────────────────────────────────────

  group('Payment checkout', () {
    test('checkout() WALLET returns no paymentUrl', () async {
      adapter.onPost(
        '/api/payments/checkout',
        (server) => server.reply(
          200,
          apiOk({'orderId': 300, 'method': 'WALLET', 'status': 'COMPLETED'}),
        ),
      );

      final result = await service.checkout(300, 'WALLET');
      expect(result.containsKey('paymentUrl'), isFalse);
      expect(result['status'], equals('COMPLETED'));
    });

    test('checkout() VNPAY returns paymentUrl', () async {
      adapter.onPost(
        '/api/payments/checkout',
        (server) => server.reply(
          200,
          apiOk({
            'orderId': 300,
            'method': 'VNPAY',
            'paymentUrl':
                'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html?abc=123',
          }),
        ),
      );

      final result = await service.checkout(
        300,
        'VNPAY',
        returnUrl: 'http://localhost/callback',
      );
      expect(result['paymentUrl'], startsWith('https://sandbox.vnpayment.vn'));
    });

    test('checkout() on 400 throws exception', () async {
      adapter.onPost(
        '/api/payments/checkout',
        (server) => server.reply(400, apiError('Đơn đã được thanh toán')),
      );

      expect(() => service.checkout(300, 'WALLET'), throwsA(isA<Exception>()));
    });
  });

  // ── Report photos (Cloudinary attachments) ───────────────────────────────

  group('report attachments', () {
    late List<RequestOptions> captured;
    const attachment = {
      'publicId': 'lockr/reports/u42/abc',
      'version': 1726390012,
      'signature': 'sig',
      'format': 'jpg',
      'bytes': 1234,
      'width': 1600,
      'height': 1200,
      'capturedAt': '2026-09-15T08:10:00',
    };

    setUp(() {
      final mock = createMockDio();
      adapter = mock.adapter;
      captured = [];
      mock.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            captured.add(options);
            handler.next(options);
          },
        ),
      );
      service = LockerOpsService(dio: mock.dio);
    });

    test('reportFault() sends attachments only when provided', () async {
      adapter.onPost(
        '/api/boxes/5/fault',
        (server) => server.reply(200, apiOk({'id': 1})),
      );

      await service.reportFault(5, 'Kẹt cửa');
      await service.reportFault(5, 'Kẹt cửa', attachments: [attachment]);

      expect(captured[0].method, 'POST');
      expect(captured[0].data, {'reason': 'Kẹt cửa'});
      expect(captured[1].data, {
        'reason': 'Kẹt cửa',
        'attachments': [attachment],
      });
    });

    test('reportOrderFault() forwards attachments', () async {
      adapter.onPost(
        '/api/orders/9/report-box-fault',
        (server) => server.reply(200, apiOk({'id': 9})),
      );

      await service.reportOrderFault(
        9,
        'Ô không mở',
        attachments: [attachment],
      );

      expect(captured.single.path, '/api/orders/9/report-box-fault');
      expect(captured.single.data, {
        'reason': 'Ô không mở',
        'attachments': [attachment],
      });
    });

    test('addReportLog() posts note + PROGRESS attachments', () async {
      adapter.onPost(
        '/api/locker-technician/reports/42/logs',
        (server) => server.reply(200, apiOk({'id': 3})),
      );

      await service.addReportLog(42, 'Thay khoá', attachments: [attachment]);

      expect(captured.single.method, 'POST');
      expect(captured.single.data, {
        'note': 'Thay khoá',
        'attachments': [attachment],
      });
    });

    test('resolveReport() sends body only with note/attachments', () async {
      adapter.onPut(
        '/api/locker-technician/reports/42/resolve',
        (server) => server.reply(200, apiOk({'id': 42, 'status': 'RESOLVED'})),
      );

      await service.resolveReport(42);
      await service.resolveReport(42, note: '  ');
      await service.resolveReport(
        42,
        note: ' Đã thay khoá ',
        attachments: [attachment],
      );

      expect(captured, hasLength(3));
      expect(captured[0].method, 'PUT');
      expect(captured[0].data, isNull);
      expect(captured[1].data, isNull);
      expect(captured[2].data, {
        'note': 'Đã thay khoá',
        'attachments': [attachment],
      });
    });

    test('reportAttachments() filters by stage', () async {
      adapter.onGet(
        '/api/locker-technician/reports/42/attachments',
        (server) => server.reply(
          200,
          apiOk([
            {'id': 7, 'stage': 'INSPECTION', 'url': 'https://x/7.jpg'},
          ]),
        ),
      );

      final result = await service.reportAttachments(42, stage: 'INSPECTION');

      expect(result.single['id'], 7);
      expect(captured.single.queryParameters, {'stage': 'INSPECTION'});
    });

    test('addReportAttachments() posts stage, note and attachments', () async {
      adapter.onPost(
        '/api/locker-technician/reports/42/attachments',
        (server) => server.reply(
          200,
          apiOk([
            {'id': 8, 'stage': 'INSPECTION', 'url': 'https://x/8.jpg'},
          ]),
        ),
      );

      final result = await service.addReportAttachments(42, 'INSPECTION', [
        attachment,
      ], note: 'Bản lề lệch');
      await service.addReportAttachments(42, 'RESOLUTION', [attachment]);

      expect(result.single['id'], 8);
      expect(captured[0].data, {
        'stage': 'INSPECTION',
        'note': 'Bản lề lệch',
        'attachments': [attachment],
      });
      expect(captured[1].data, {
        'stage': 'RESOLUTION',
        'attachments': [attachment],
      });
    });

    test('deleteReportAttachment() calls DELETE', () async {
      adapter.onDelete(
        '/api/locker-technician/reports/42/attachments/7',
        (server) => server.reply(200, apiOk(null)),
      );

      await service.deleteReportAttachment(42, 7);

      expect(captured.single.method, 'DELETE');
      expect(captured.single.path, '/api/locker-technician/reports/42/attachments/7');
    });

    test('myReportAttachments() and addMyReportAttachments()', () async {
      adapter.onGet(
        '/api/lockers/reports/12/attachments',
        (server) => server.reply(
          200,
          apiOk([
            {'id': 1, 'stage': 'REPORT', 'url': 'https://x/1.jpg'},
          ]),
        ),
      );
      await service.myReportAttachments(12);

      adapter.onPost(
        '/api/lockers/reports/12/attachments',
        (server) => server.reply(
          200,
          apiOk({
            'id': 12,
            'attachments': [
              {'id': 2, 'stage': 'REPORT', 'url': 'https://x/2.jpg'},
            ],
          }),
        ),
      );
      final added = await service.addMyReportAttachments(12, [attachment]);

      expect(captured[0].method, 'GET');
      expect(captured[1].method, 'POST');
      expect(captured[1].data, {
        'attachments': [attachment],
      });
      expect(added.single['id'], 2);
    });

    test('getMaintenanceReport() returns the report', () async {
      adapter.onGet(
        '/api/locker-technician/reports/42',
        (server) =>
            server.reply(200, apiOk({'id': 42, 'attachments': <Object>[]})),
      );

      final report = await service.getMaintenanceReport(42);

      expect(report['id'], 42);
      expect(captured.single.method, 'GET');
    });

    test('errorMessage() maps media error codes to Vietnamese', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/api/boxes/5/fault'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/boxes/5/fault'),
          statusCode: 503,
          data: {
            'success': false,
            'code': 'MEDIA_STORAGE_DISABLED',
            'message': 'Media storage is disabled',
          },
        ),
      );

      expect(
        LockerOpsService.errorMessage(error),
        contains('Hệ thống lưu ảnh đang tạm tắt'),
      );
    });
  });

  // ── Luồng 4: KTV tủ (định tuyến phiếu, kiểm tra định kỳ, bãi đáp) ─────────

  group('locker technician ops', () {
    late List<RequestOptions> captured;

    setUp(() {
      final mock = createMockDio();
      adapter = mock.adapter;
      captured = [];
      mock.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            captured.add(options);
            handler.next(options);
          },
        ),
      );
      service = LockerOpsService(dio: mock.dio);
    });

    Map<String, dynamic> errorBody(String code, String message) => {
      'success': false,
      'code': code,
      'message': message,
      'data': null,
      'errors': null,
    };

    test('routedReports() asks for OPEN tickets routed to me', () async {
      adapter.onGet(
        '/api/locker-technician/reports',
        (server) => server.reply(
          200,
          apiOk([
            {
              'id': 42,
              'status': 'OPEN',
              'category': 'BOX',
              'routedToUserId': 7,
              'blocksLocker': false,
            },
          ]),
        ),
      );

      final result = await service.routedReports();

      expect(result.single['routedToUserId'], 7);
      expect(captured.single.method, 'GET');
      expect(captured.single.path, '/api/locker-technician/reports');
      expect(captured.single.queryParameters, {'routed': true});
    });

    test('myLockers() lists lockers I am responsible for', () async {
      adapter.onGet(
        '/api/locker-technician/lockers',
        (server) => server.reply(
          200,
          apiOk([
            {
              'id': 3,
              'name': 'Tủ A',
              'landingPad': true,
              'assignedTechnicianId': 7,
            },
          ]),
        ),
      );

      final result = await service.myLockers();

      expect(result.single['landingPad'], isTrue);
      expect(captured.single.path, '/api/locker-technician/lockers');
      expect(captured.single.queryParameters, {'mine': true});
    });

    test('maintenanceSchedules() sends mine/target only when set', () async {
      adapter.onGet(
        '/api/maintenance/schedules',
        (server) => server.reply(
          200,
          apiOk([
            {
              'id': 5,
              'checklistItems': ['Khóa', 'Nguồn'],
              'lastResult': 'FAILED',
              'pendingReportId': 88,
            },
          ]),
        ),
      );

      final result = await service.maintenanceSchedules(
        mine: true,
        target: 'LOCKER',
      );
      await service.maintenanceSchedules();

      expect(result.single['pendingReportId'], 88);
      expect(captured[0].queryParameters, {'mine': true, 'target': 'LOCKER'});
      expect(captured[1].queryParameters, isEmpty);
    });

    test('completeInspection() posts items + fault box, no legacy status', () async {
      adapter.onPost(
        '/api/maintenance/schedules/5/complete',
        (server) => server.reply(
          200,
          apiOk({'id': 5, 'lastResult': 'FAILED', 'pendingReportId': 91}),
        ),
      );

      final result = await service.completeInspection(
        5,
        [
          {'label': 'Khóa', 'result': 'PASS'},
          {'label': 'Nguồn', 'result': 'FAIL', 'note': 'UPS hỏng'},
        ],
        note: '  Đã kiểm tra  ',
        faultBoxId: 12,
        faultReason: ' Ô 12 không khoá ',
        photoUrls: const ['https://x/1.jpg'],
      );

      expect(result['pendingReportId'], 91);
      expect(captured.single.method, 'POST');
      expect(captured.single.path, '/api/maintenance/schedules/5/complete');
      expect(captured.single.data, {
        'items': [
          {'label': 'Khóa', 'result': 'PASS'},
          {'label': 'Nguồn', 'result': 'FAIL', 'note': 'UPS hỏng'},
        ],
        'note': 'Đã kiểm tra',
        'faultBoxId': 12,
        'faultReason': 'Ô 12 không khoá',
        'photoUrls': ['https://x/1.jpg'],
      });
    });

    test('completeInspection() without checklist sends legacy status', () async {
      adapter.onPost(
        '/api/maintenance/schedules/6/complete',
        (server) => server.reply(200, apiOk({'id': 6, 'lastResult': 'PASSED'})),
      );

      await service.completeInspection(6, const [], status: 'FAILED');
      await service.completeInspection(6, const []);

      expect(captured[0].data, {'status': 'FAILED'});
      expect(captured[1].data, {'status': 'PASSED'});
    });

    test('updateLandingPadStatus() posts status and optional reason', () async {
      adapter.onPost(
        '/api/locker-technician/lockers/3/landing-pad',
        (server) => server.reply(
          200,
          apiOk({'lockerId': 3, 'landingPad': true, 'landingPadStatus': 'FAULT'}),
        ),
      );

      final layout = await service.updateLandingPadStatus(
        3,
        'FAULT',
        reason: 'Marker bong tróc',
      );
      await service.updateLandingPadStatus(3, 'OK');

      expect(layout['landingPadStatus'], 'FAULT');
      expect(captured[0].path, '/api/locker-technician/lockers/3/landing-pad');
      expect(captured[0].data, {'status': 'FAULT', 'reason': 'Marker bong tróc'});
      expect(captured[1].data, {'status': 'OK'});
    });

    test('updateLandingPadStatus() surfaces LANDING_PAD_ABSENT in Vietnamese', () async {
      adapter.onPost(
        '/api/locker-technician/lockers/4/landing-pad',
        (server) => server.reply(
          400,
          errorBody('LANDING_PAD_ABSENT', 'This locker has no drone landing pad'),
        ),
      );

      try {
        await service.updateLandingPadStatus(4, 'FAULT', reason: 'x');
        fail('expected DioException');
      } on DioException catch (e) {
        expect(LockerOpsService.errorCode(e), 'LANDING_PAD_ABSENT');
        expect(
          LockerOpsService.errorMessage(e),
          'Tủ này không có bãi đáp drone.',
        );
      }
    });

    test('reportLocker() sends blocking only for a blocking report', () async {
      adapter.onPost(
        '/api/lockers/3/report',
        (server) => server.reply(
          200,
          apiOk({'id': 50, 'category': 'LOCKER', 'blocksLocker': true}),
        ),
      );

      final result = await service.reportLocker(
        3,
        'Mất nguồn',
        'Cả tủ mất điện',
        blocking: true,
      );
      await service.reportLocker(3, 'Màn hình mờ', 'Khó đọc');

      expect(result['blocksLocker'], isTrue);
      expect(captured[0].data, {
        'title': 'Mất nguồn',
        'description': 'Cả tủ mất điện',
        'blocking': true,
      });
      expect(captured[1].data, {
        'title': 'Màn hình mờ',
        'description': 'Khó đọc',
      });
    });

    test('clearFault() surfaces REPORT_OPEN code and server message', () async {
      const message =
          'Đang có phiếu sự cố #42 — nhận phiếu rồi hoàn tất phiếu để khôi phục';
      adapter.onPost(
        '/api/locker-technician/boxes/5/clear-fault',
        (server) => server.reply(409, errorBody('REPORT_OPEN', message)),
      );

      try {
        await service.clearFault(5);
        fail('expected DioException');
      } on DioException catch (e) {
        expect(e.response?.statusCode, 409);
        expect(LockerOpsService.errorCode(e), 'REPORT_OPEN');
        expect(LockerOpsService.errorMessage(e), message);
      }
      expect(captured.single.path, '/api/locker-technician/boxes/5/clear-fault');
    });

    test('errorMessage() localises RESOLUTION_PHOTO_REQUIRED', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/x'),
        response: Response(
          requestOptions: RequestOptions(path: '/x'),
          statusCode: 400,
          data: errorBody(
            'RESOLUTION_PHOTO_REQUIRED',
            'Take at least one acceptance photo before resolving the report',
          ),
        ),
      );

      expect(LockerOpsService.errorCode(error), 'RESOLUTION_PHOTO_REQUIRED');
      expect(LockerOpsService.errorMessage(error), contains('ảnh nghiệm thu'));
      expect(LockerOpsService.errorCode(Exception('x')), isNull);
    });
  });
}
