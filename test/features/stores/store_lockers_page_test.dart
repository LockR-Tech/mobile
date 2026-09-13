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
}
