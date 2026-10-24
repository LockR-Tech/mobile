import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/core/services/locker_ble_open_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/pages/ble_test_page.dart';

import '../../helpers/test_helpers.dart';

class _FakeBleOps extends LockerOpsService {
  _FakeBleOps({this.granted = const []}) : super(dio: createMockDio().dio);

  final List<Map<String, dynamic>> granted;
  final List<int> tokenBoxes = [];

  @override
  Future<List<Map<String, dynamic>>> bleTestLockers() async => granted;

  @override
  Future<Map<String, dynamic>> layout(int lockerId) async => {
        'lockerId': lockerId,
        'cells': [
          {'id': 39, 'boxNumber': 2, 'rowIndex': 1, 'colIndex': 1, 'cellType': 'DRONE', 'status': 'AVAILABLE'},
          {'id': 40, 'boxNumber': 3, 'rowIndex': 1, 'colIndex': 2, 'cellType': 'DRONE', 'status': 'OCCUPIED'},
          {'id': 38, 'boxNumber': 1, 'rowIndex': 2, 'colIndex': 0, 'cellType': 'XL', 'size': 'XL', 'status': 'AVAILABLE'},
        ],
      };

  @override
  Future<Map<String, dynamic>> bleOpenToken(int lockerId, int boxNumber) async {
    tokenBoxes.add(boxNumber);
    return {
      'token': base64Url.encode(List<int>.filled(91, 1)),
      'nonce': 'ab',
      'deviceName': 'LOCKR_CAB-TU01',
      'lockerCode': 'CAB-TU01',
      'lockerId': lockerId,
      'boxNumber': boxNumber,
      'serviceUuid': '06776521-9674-432d-b886-5e951244ffa3',
      'openCharUuid': '54af4ad7-dcde-47dc-ad44-fa2c7438dd36',
      'resultCharUuid': '8a6e33a5-1b26-4e80-8faa-026bab93ad4e',
    };
  }
}

void main() {
  const tu01 = {'lockerId': 7, 'code': 'CAB-TU01', 'name': 'Tủ thật TU01'};

  Future<void> pump(WidgetTester tester, Widget page) async {
    await tester.binding.setSurfaceSize(const Size(420, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(home: page));
    await tester.pumpAndSettle();
  }

  testWidgets('chưa được cấp quyền ⇒ báo, không có nút mở', (tester) async {
    await pump(tester, BleTestPage(service: _FakeBleOps()));
    expect(find.text('Chưa được cho thử'), findsOneWidget);
    expect(find.textContaining('qua Bluetooth', findRichText: true), findsWidgets);
    expect(find.textContaining('Mở ô'), findsNothing);
  });

  testWidgets('chọn ô rồi mở: xin mã đúng ô, ghi qua BLE, báo đã mở', (tester) async {
    final ops = _FakeBleOps(granted: [tu01]);
    BleOpenTicket? sent;
    await pump(
      tester,
      BleTestPage(
        service: ops,
        opener: (ticket, onStep) async {
          sent = ticket;
          onStep(BleOpenStep.scanning);
          return BleOpenOutcome.ok(ticket.boxNumber);
        },
      ),
    );
    expect(find.text('Tủ thật TU01 (CAB-TU01)'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('ble-box-2')));
    await tester.pump();
    await tester.tap(find.text('Mở ô 2 qua Bluetooth'));
    await tester.pumpAndSettle();

    expect(ops.tokenBoxes, [2]);
    expect(sent!.token.length, 91);
    expect(find.text('Đã mở ô 2'), findsOneWidget);
  });

  testWidgets('ô đang có hàng phải xác nhận trước khi mở', (tester) async {
    final ops = _FakeBleOps(granted: [tu01]);
    await pump(
      tester,
      BleTestPage(service: ops, opener: (t, _) async => const BleOpenOutcome.failed('NOT_FOUND')),
    );
    await tester.tap(find.byKey(const ValueKey('ble-box-3')));
    await tester.pump();
    await tester.tap(find.text('Mở ô 3 qua Bluetooth'));
    await tester.pumpAndSettle();
    expect(find.text('Ô 3 đang có hàng'), findsOneWidget);

    await tester.tap(find.text('Huỷ'));
    await tester.pumpAndSettle();
    expect(ops.tokenBoxes, isEmpty);

    await tester.tap(find.text('Mở ô 3 qua Bluetooth'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vẫn mở'));
    await tester.pumpAndSettle();
    expect(ops.tokenBoxes, [3]);
    expect(find.text('Chưa mở được'), findsOneWidget);
    expect(find.textContaining('đứng sát tủ'), findsOneWidget);
  });
}
