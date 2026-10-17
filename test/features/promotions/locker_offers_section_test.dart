import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/promotions/presentation/widgets/locker_offers_section.dart';

import '../../helpers/test_helpers.dart';

class _FakePromotionsService extends LockerOpsService {
  _FakePromotionsService(this.promotions) : super(dio: createMockDio().dio);

  final List<Map<String, dynamic>> promotions;
  final List<int?> requestedLockerIds = [];

  @override
  Future<List<Map<String, dynamic>>> activePromotions({int? lockerId}) async {
    requestedLockerIds.add(lockerId);
    return promotions;
  }
}

void main() {
  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
    await tester.pumpAndSettle();
  }

  testWidgets('chỉ liệt kê mã riêng của tủ này, lưu được vào ví', (
    tester,
  ) async {
    final service = _FakePromotionsService([
      {
        'id': 1,
        'code': 'TOANQUOC',
        'name': 'Toàn hệ thống',
        'discountType': 'FIXED_AMOUNT',
        'discountValue': 5000,
      },
      {
        'id': 2,
        'code': 'TU7',
        'name': 'Giảm 10% tại tủ',
        'discountType': 'PERCENTAGE',
        'discountValue': 10,
        'lockerId': 7,
        'lockerName': 'Tủ Thư viện',
      },
      {
        'id': 3,
        'code': 'TU9',
        'name': 'Tủ khác',
        'discountType': 'FIXED_AMOUNT',
        'discountValue': 9000,
        'lockerId': 9,
      },
    ]);
    final claimed = <int>[];

    await pump(
      tester,
      LockerOffersSection(
        lockerId: 7,
        service: service,
        claimPromotion: (id) async => claimed.add(id),
      ),
    );

    expect(service.requestedLockerIds, [7]);
    expect(find.text('Ưu đãi tại tủ này'), findsOneWidget);
    expect(find.text('TU7'), findsOneWidget);
    expect(find.text('TOANQUOC'), findsNothing);
    expect(find.text('TU9'), findsNothing);

    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    expect(claimed, [2]);
    expect(find.text('Đã lưu'), findsOneWidget);
  });

  testWidgets('tủ không có mã riêng ⇒ ẩn hẳn mục ưu đãi', (tester) async {
    await pump(
      tester,
      LockerOffersSection(
        lockerId: 7,
        service: _FakePromotionsService([
          {'id': 1, 'code': 'TOANQUOC', 'name': 'x'},
        ]),
      ),
    );
    expect(find.text('Ưu đãi tại tủ này'), findsNothing);
  });
}
