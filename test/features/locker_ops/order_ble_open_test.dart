import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/core/services/locker_ble_open_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/order_ble_open.dart';

import '../../helpers/test_helpers.dart';

Map<String, dynamic> _ticketJson(int orderId) => {
      'token': base64Url.encode(List<int>.filled(91, 1)),
      'nonce': '0123456789ABCDEF',
      'expiresAt': 1790000000,
      'lockerId': 7,
      'lockerCode': 'CAB-TU01',
      'boxNumber': 4,
      'boxId': 71,
      'deviceName': 'LOCKR_CAB-TU01',
      'serviceUuid': '06776521-9674-432d-b886-5e951244ffa3',
      'openCharUuid': '54af4ad7-dcde-47dc-ad44-fa2c7438dd36',
      'resultCharUuid': '8a6e33a5-1b26-4e80-8faa-026bab93ad4e',
      'orderId': orderId,
      'action': 'PICKUP',
    };

class _FakeOps extends LockerOpsService {
  _FakeOps({this.tokenError}) : super(dio: createMockDio().dio);

  final Object? tokenError;
  final List<int> tokenOrders = [];

  @override
  Future<Map<String, dynamic>> bleOrderToken(int orderId) async {
    tokenOrders.add(orderId);
    if (tokenError != null) throw tokenError!;
    return _ticketJson(orderId);
  }
}

DioException _apiError(int status, String code, String message) {
  final options = RequestOptions(path: '/api/iot/ble/orders/9/token');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response(
      requestOptions: options,
      statusCode: status,
      data: {'success': false, 'code': code, 'message': message},
    ),
  );
}

void main() {
  group('LockerOpsService.bleOrderToken', () {
    test('POST /api/iot/ble/orders/{id}/token ⇒ đọc được mã + orderId/action', () async {
      final mock = createMockDio();
      mock.adapter.onPost(
        '/api/iot/ble/orders/9/token',
        (server) => server.reply(200, apiOk(_ticketJson(9))),
      );
      final ticket = BleOpenTicket.fromJson(
        await LockerOpsService(dio: mock.dio).bleOrderToken(9),
      );
      expect(ticket.token, hasLength(91));
      expect(ticket.nonce, '0123456789abcdef');
      expect(ticket.boxNumber, 4);
      expect(ticket.deviceName, 'LOCKR_CAB-TU01');
      expect(ticket.orderId, 9);
      expect(ticket.action, 'PICKUP');
    });

    test('mã lỗi mới có câu tiếng Việt riêng', () {
      expect(
        LockerOpsService.errorMessage(_apiError(403, 'BLE_ORDER_FORBIDDEN', 'Forbidden')),
        'Tài khoản này không được mở ô của đơn này.',
      );
      expect(
        LockerOpsService.errorMessage(_apiError(409, 'BLE_ORDER_NOT_OPENABLE', 'Conflict')),
        'Đơn đang ở trạng thái không mở ô được.',
      );
    });
  });

  group('OrderOpenSheet', () {
    OrderOpenResult? result;
    var closed = false;

    Future<void> pumpSheet(
      WidgetTester tester, {
      required _FakeOps ops,
      required BleOpener opener,
      LockerQrScan? scanQr,
    }) async {
      result = null;
      closed = false;
      await tester.binding.setSurfaceSize(const Size(420, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  result = await OrderOpenSheet.show(
                    context,
                    orderId: 9,
                    lockerName: 'Tủ TU01',
                    lockerCode: 'CAB-TU01',
                    lockerId: 7,
                    boxLabel: 'ô số 4',
                    pin: '135790',
                    qrToken: 'qr-token-9',
                    service: ops,
                    opener: opener,
                    scanQr: scanQr,
                  );
                  closed = true;
                },
                child: const Text('Mở ô tủ'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('Mở ô tủ'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    testWidgets('bấm mở ⇒ thử Bluetooth ngay (không hỏi cách mở), mở được thì đóng bảng', (tester) async {
      final ops = _FakeOps();
      final done = Completer<BleOpenOutcome>();
      BleOpenTicket? sent;
      await pumpSheet(
        tester,
        ops: ops,
        opener: (ticket, onStep) {
          sent = ticket;
          onStep(BleOpenStep.connecting);
          return done.future;
        },
      );
      await tester.pump();
      expect(find.text('Đang kết nối với tủ…'), findsOneWidget);
      expect(find.text('Quét mã QR'), findsNothing);
      expect(find.text('Dùng mã OTP'), findsNothing);
      expect(closed, isFalse);

      done.complete(const BleOpenOutcome.ok(4));
      await tester.pumpAndSettle();

      expect(ops.tokenOrders, [9]);
      expect(sent?.orderId, 9);
      expect(closed, isTrue);
      expect(result?.method, OrderOpenMethod.bluetooth);
      expect(result?.boxNumber, 4);
    });

    testWidgets('Bluetooth lỗi ⇒ cho chọn Quét mã QR / Dùng mã OTP, thử lại được', (tester) async {
      final ops = _FakeOps();
      var calls = 0;
      await pumpSheet(
        tester,
        ops: ops,
        opener: (ticket, onStep) async {
          calls++;
          return calls == 1 ? const BleOpenOutcome.failed('NOT_FOUND') : BleOpenOutcome.ok(ticket.boxNumber);
        },
      );
      await tester.pumpAndSettle();

      expect(closed, isFalse);
      expect(find.text('Chưa mở được bằng Bluetooth'), findsOneWidget);
      expect(find.textContaining('Không thấy tủ qua Bluetooth'), findsOneWidget);
      expect(find.text('Thử lại Bluetooth'), findsOneWidget);
      expect(find.text('Quét mã QR'), findsOneWidget);
      expect(find.text('Dùng mã OTP'), findsOneWidget);
      // Mã OTP chỉ hiện khi khách chọn cách này.
      expect(find.byType(AccessCredentials), findsNothing);

      await tester.tap(find.text('Dùng mã OTP'));
      await tester.pumpAndSettle();
      final creds = tester.widget<AccessCredentials>(find.byType(AccessCredentials));
      expect(creds.pin, '135790');
      expect(creds.qrToken, 'qr-token-9');
      expect(creds.showQr, isTrue);

      await tester.tap(find.text('Thử lại Bluetooth'));
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(ops.tokenOrders, [9, 9]);
      expect(result?.method, OrderOpenMethod.bluetooth);
    });

    testWidgets('chọn Quét mã QR, quét đúng tủ ⇒ trả về để mở từ xa', (tester) async {
      await pumpSheet(
        tester,
        ops: _FakeOps(),
        opener: (ticket, onStep) async => const BleOpenOutcome.failed('BLUETOOTH_OFF'),
        scanQr: (context) async => true,
      );
      await tester.pumpAndSettle();
      expect(find.text('Bluetooth của điện thoại đang tắt.'), findsOneWidget);

      await tester.tap(find.text('Quét mã QR'));
      await tester.pumpAndSettle();
      expect(result?.method, OrderOpenMethod.lockerQr);
    });

    testWidgets('BLE ném lỗi nền tảng ⇒ vẫn hiện cách dự phòng', (tester) async {
      await pumpSheet(
        tester,
        ops: _FakeOps(),
        opener: (ticket, onStep) async => throw Exception('MissingPlugin'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Chưa mở được bằng Bluetooth'), findsOneWidget);
      expect(find.text('Quét mã QR'), findsOneWidget);
    });

    testWidgets('máy chủ chặn (đơn chưa thanh toán) ⇒ báo lý do, không gợi ý mã kiosk', (tester) async {
      var opened = false;
      await pumpSheet(
        tester,
        ops: _FakeOps(tokenError: _apiError(409, 'ORDER_UNPAID', 'Đơn chưa thanh toán.')),
        opener: (ticket, onStep) async {
          opened = true;
          return BleOpenOutcome.ok(ticket.boxNumber);
        },
      );
      await tester.pumpAndSettle();
      expect(opened, isFalse);
      expect(find.text('Đơn chưa thanh toán.'), findsOneWidget);
      expect(find.text('Thử lại Bluetooth'), findsOneWidget);
      expect(find.text('Quét mã QR'), findsNothing);
      expect(find.text('Dùng mã OTP'), findsNothing);
    });

    testWidgets('mất mạng khi xin mã ⇒ vẫn cho chọn cách khác', (tester) async {
      final options = RequestOptions(path: '/api/iot/ble/orders/9/token');
      await pumpSheet(
        tester,
        ops: _FakeOps(
          tokenError: DioException(requestOptions: options, type: DioExceptionType.connectionError),
        ),
        opener: (ticket, onStep) async => BleOpenOutcome.ok(ticket.boxNumber),
      );
      await tester.pumpAndSettle();
      expect(find.text('Quét mã QR'), findsOneWidget);
      expect(find.text('Dùng mã OTP'), findsOneWidget);
    });
  });
}
