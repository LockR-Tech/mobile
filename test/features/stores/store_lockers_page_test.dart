import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/stores/domain/entities/store.dart';
import 'package:smart_laundry_locker/features/stores/presentation/pages/store_lockers_page.dart';

import '../../helpers/test_helpers.dart';

class _FakeStoreLockerService extends LockerOpsService {
  _FakeStoreLockerService() : super(dio: createMockDio().dio);

  @override
  Future<List<Map<String, dynamic>>> lockersByStore(int storeId) async => [
    {'id': 11, 'name': 'Locker demo', 'status': 'ACTIVE'},
  ];

  @override
  Future<Map<String, dynamic>> layout(int lockerId) async => {
    'cells': [
      {
        'id': 5001,
        'boxNumber': 3,
        'rowIndex': 0,
        'colIndex': 0,
        'status': 'FAULT',
        'faultReason': 'Kẹt cửa',
        'cellType': 'STANDARD',
        'size': 'MEDIUM',
      },
    ],
  };
}

void main() {
  setUp(() {
    mockSecureStorage({
      'access_token': makeFakeJwt(sub: '99', roles: ['CUSTOMER']),
    });
  });

  testWidgets('shows fault warning and tap hint for blocked cells', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: StoreLockerGridPage(
          store: const Store(id: 1, name: 'Cửa hàng A', active: true),
          service: _FakeStoreLockerService(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('HỎNG'), findsOneWidget);
    expect(find.text('Hỏng'), findsOneWidget);

    await tester.tap(find.text('HỎNG'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.textContaining('Ô số 3 đang hỏng'), findsOneWidget);
    expect(find.textContaining('Kẹt cửa'), findsOneWidget);
  });

  _tests();
}

/// Tủ mở thẳng theo id (không qua cửa hàng); `online` do server trả.
class _SingleLockerService extends LockerOpsService {
  _SingleLockerService({required this.online})
    : super(dio: createMockDio().dio);

  final bool? online;
  final calls = <String>[];

  @override
  Future<List<Map<String, dynamic>>> lockersByStore(int storeId) async {
    calls.add('lockersByStore($storeId)');
    return const [];
  }

  @override
  Future<Map<String, dynamic>> locker(int lockerId) async {
    calls.add('locker($lockerId)');
    return {
      'id': lockerId,
      'name': 'Tủ thật',
      'code': 'CAB-TU01',
      'status': 'ACTIVE',
      if (online != null) 'online': online,
    };
  }

  @override
  Future<Map<String, dynamic>> layout(int lockerId) async => {
    'status': 'ACTIVE',
    if (online != null) 'online': online,
    'cells': [
      {
        'id': 9001,
        'boxNumber': 4,
        'rowIndex': 2,
        'colIndex': 1,
        'status': 'AVAILABLE',
        'cellType': 'STANDARD',
        'size': 'MEDIUM',
      },
    ],
  };
}

void _tests() {
  testWidgets('mở theo lockerId: tải đúng tủ, không đoán theo cửa hàng', (
    tester,
  ) async {
    final service = _SingleLockerService(online: true);
    await tester.pumpWidget(
      MaterialApp(
        home: StoreLockerGridPage(
          store: const Store(id: 3, name: 'Cửa hàng B'),
          lockerId: 7,
          service: service,
        ),
      ),
    );
    // Ô trống có hiệu ứng lặp vô hạn ⇒ không dùng pumpAndSettle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(service.calls, ['locker(7)']);
    expect(find.text('Hoạt động'), findsOneWidget);
    // Tên tủ CAB-TU01 không còn bị ép "Mất kết nối" khi server báo online.
    expect(find.text('Mất kết nối'), findsNothing);

    // Gỡ widget để huỷ hiệu ứng lặp của ô trống trước khi test kết thúc.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('tủ offline: chạm ô trống báo lý do, không mở đặt ô', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: StoreLockerGridPage(
          store: const Store(id: 3, name: 'Cửa hàng B'),
          lockerId: 7,
          service: _SingleLockerService(online: false),
        ),
      ),
    );
    // Ô trống có hiệu ứng lặp vô hạn ⇒ không dùng pumpAndSettle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Mất kết nối'), findsOneWidget);
    await tester.tap(find.text('Ô #4'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.textContaining('chưa đặt được ô'), findsWidgets);
    expect(find.text('Bạn muốn làm gì với ô tủ này?'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  });
}
