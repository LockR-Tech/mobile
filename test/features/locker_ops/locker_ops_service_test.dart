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

  // ── TECHNICIAN ────────────────────────────────────────────────────────────

  group('TECHNICIAN endpoints', () {
    group('techDevices()', () {
      test('returns device list with status', () async {
        adapter.onGet(
          '/api/technician/devices',
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
          '/api/technician/devices',
          (server) => server.reply(200, apiOk([])),
        );

        final result = await service.techDevices();
        expect(result, isEmpty);
      });
    });

    group('techDeviceDetail()', () {
      test('returns device detail map', () async {
        adapter.onGet(
          '/api/technician/devices/1',
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
          '/api/technician/devices/1/logs',
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
          '/api/technician/devices/1/status',
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
          '/api/technician/devices/1/restart',
          (server) =>
              server.reply(200, apiOk({'deviceId': 'DEV-001', 'lockerId': 10})),
        );

        await expectLater(service.techRestartDevice(1), completes);
      });
    });
  });

  // ── MAINTENANCE (locker upkeep endpoints — now used by TECHNICIAN UI) ─────

  group('MAINTENANCE endpoints', () {
    test('faults() returns fault cell list', () async {
      adapter.onGet(
        '/api/maintenance/faults',
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
        '/api/maintenance/reports/42/claim',
        (server) =>
            server.reply(200, apiOk({'id': 42, 'status': 'IN_PROGRESS'})),
      );

      final result = await service.claimReport(42);
      expect(result['status'], equals('IN_PROGRESS'));
    });

    test('resolveReport() returns resolved report', () async {
      adapter.onPut(
        '/api/maintenance/reports/42/resolve',
        (server) => server.reply(200, apiOk({'id': 42, 'status': 'RESOLVED'})),
      );

      final result = await service.resolveReport(42);
      expect(result['status'], equals('RESOLVED'));
    });

    test('clearFault() succeeds', () async {
      adapter.onPost(
        '/api/maintenance/boxes/5/clear-fault',
        (server) => server.reply(200, apiOk(null)),
      );

      await expectLater(service.clearFault(5), completes);
    });

    test('forceOpenBox() succeeds', () async {
      adapter.onPost(
        '/api/maintenance/boxes/5/force-open',
        (server) => server.reply(200, apiOk(null)),
      );

      await expectLater(service.forceOpenBox(5), completes);
    });
  });

  // ── MAINTENANCE — drone fleet ─────────────────────────────────────────────

  group('Drone fleet endpoints', () {
    test('droneUnits() returns fleet list', () async {
      adapter.onGet(
        '/api/maintenance/drones',
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
        '/api/maintenance/drones/1/status',
        (server) => server.reply(200, apiOk({'id': 1, 'status': 'CHARGING'})),
      );

      final result = await service.updateDroneStatus(1, 'CHARGING');
      expect(result['status'], equals('CHARGING'));
    });

    test('updateDroneBattery() returns updated drone', () async {
      adapter.onPost(
        '/api/maintenance/drones/1/battery',
        (server) => server.reply(200, apiOk({'id': 1, 'batteryPercent': 40})),
      );

      final result = await service.updateDroneBattery(1, 40);
      expect(result['batteryPercent'], equals(40));
    });

    test('droneOrderQueue() returns order-based maintenance queue', () async {
      adapter.onGet(
        '/api/maintenance/drone-orders',
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
          '/api/maintenance/drone-orders/21/accept',
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
        '/api/maintenance/drone-orders/21/launch',
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
          '/api/maintenance/drone-orders/22/cancel',
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
}
