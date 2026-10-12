import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/delegations/presentation/pages/my_delegations_page.dart';
import 'package:smart_laundry_locker/features/delegations/presentation/providers/delegation_provider.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';

import '../../helpers/test_helpers.dart';

class _FakeService extends LockerOpsService {
  _FakeService() : super(dio: createMockDio().dio);

  @override
  Future<List<Map<String, dynamic>>> delegatedToMe({
    bool activeOnly = false,
  }) async => [
    {
      'id': 40,
      'orderCode': 'ORD-40',
      'type': 'RENTAL',
      'status': 'STORING',
      'senderName': 'Trần Bình',
      'lockerId': 7,
      'lockerName': 'Tủ thư viện',
      'boxNumber': 5,
      'readyForPickup': true,
      'pickupPin': '864209',
      'delegated': true,
      'delegateNote': 'Lấy giúp mình trước 5h',
    },
  ];
}

void main() {
  setUp(() {
    mockSecureStorage({
      'access_token': makeFakeJwt(sub: '99', roles: ['CUSTOMER']),
    });
    useBusinessConfig();
  });

  testWidgets('Đơn ủy quyền: đọc delegated-to-me, hiện mã và nút mở ô', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: MyDelegationsPage(
          provider: DelegationProvider(service: _FakeService()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('#ORD-40'), findsOneWidget);
    expect(find.text('Trần Bình'), findsOneWidget);
    expect(find.text('Lấy giúp mình trước 5h'), findsOneWidget);
    final creds = tester.widget<AccessCredentials>(
      find.byType(AccessCredentials),
    );
    expect(creds.pin, '864209');
    expect(find.text('Mở ô số 5 lấy hàng'), findsOneWidget);
    // Màn của người lấy hộ không hiện cảnh báo "đã ủy quyền người khác".
    expect(find.textContaining('mã lấy hàng không còn hiện'), findsNothing);
  });
}
