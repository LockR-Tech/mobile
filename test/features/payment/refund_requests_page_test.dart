import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/payment/data/payment_service.dart';
import 'package:smart_laundry_locker/features/payment/presentation/pages/refund_requests_page.dart';

import '../../helpers/test_helpers.dart';

class _FakePaymentService extends PaymentService {
  _FakePaymentService(this.refunds) : super(apiClient: createMockApiClient().apiClient);

  final List<Map<String, dynamic>> refunds;

  @override
  Future<List<Map<String, dynamic>>> myRefunds({List<int>? orderIds}) async {
    return refunds;
  }
}

class _FakeLockerOpsService extends LockerOpsService {
  _FakeLockerOpsService() : super(dio: createMockDio().dio);

  @override
  Future<List<Map<String, dynamic>>> myOrders() async => const [];
}

void main() {
  testWidgets('RefundRequestsPage displays filter chips and date classification headers', (tester) async {
    final now = DateTime.now().toUtc();
    final todayStr = now.toIso8601String();
    final yesterdayStr = now.subtract(const Duration(days: 1)).toIso8601String();
    final oldDate = DateTime.utc(2026, 10, 12, 18, 0, 0);
    final oldDateStr = oldDate.toIso8601String();

    final refunds = [
      {
        'id': 10,
        'amount': 4000,
        'status': 'COMPLETED',
        'orderCode': 'ORD-10',
        'requestedAt': todayStr,
      },
      {
        'id': 9,
        'amount': 2000,
        'status': 'PENDING',
        'orderCode': 'ORD-9',
        'requestedAt': yesterdayStr,
      },
      {
        'id': 8,
        'amount': 5000,
        'status': 'REJECTED',
        'orderCode': 'ORD-8',
        'requestedAt': oldDateStr,
      },
    ];

    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final paymentService = _FakePaymentService(refunds);
    final lockerService = _FakeLockerOpsService();

    await tester.pumpWidget(
      MaterialApp(
        home: RefundRequestsPage(
          paymentService: paymentService,
          lockerService: lockerService,
        ),
      ),
    );

    // Initial pump and wait for futures
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final filterChipsBar = find.byType(SingleChildScrollView).first;

    // Verify filter chips are rendered
    expect(find.descendant(of: filterChipsBar, matching: find.text('Tất cả')), findsOneWidget);
    expect(find.descendant(of: filterChipsBar, matching: find.text('Gần đây')), findsOneWidget);
    expect(find.descendant(of: filterChipsBar, matching: find.text('Chờ xử lý')), findsOneWidget);
    expect(find.descendant(of: filterChipsBar, matching: find.text('Đã chuyển tiền')), findsOneWidget);
    expect(find.descendant(of: filterChipsBar, matching: find.text('Bị từ chối')), findsOneWidget);

    // Verify counts on chips
    expect(find.text('(3)'), findsWidgets); // 'Tất cả' has (3)

    // Verify date headers are displayed
    expect(find.text('Hôm nay'), findsOneWidget);
    expect(find.text('Hôm qua'), findsOneWidget);

    // Verify refund cards are displayed
    expect(find.text('Phiếu hoàn tiền #10'), findsOneWidget);
    expect(find.text('Phiếu hoàn tiền #9'), findsOneWidget);
    expect(find.text('Phiếu hoàn tiền #8'), findsOneWidget);

    // Tap on 'Chờ xử lý' filter chip
    await tester.tap(find.descendant(of: filterChipsBar, matching: find.text('Chờ xử lý')));
    await tester.pumpAndSettle();

    // Now only refund #9 should be visible
    expect(find.text('Phiếu hoàn tiền #9'), findsOneWidget);
    expect(find.text('Phiếu hoàn tiền #10'), findsNothing);
    expect(find.text('Phiếu hoàn tiền #8'), findsNothing);

    // Tap on 'Đã chuyển tiền' filter chip
    await tester.tap(find.descendant(of: filterChipsBar, matching: find.text('Đã chuyển tiền')));
    await tester.pumpAndSettle();

    // Now only refund #10 should be visible
    expect(find.text('Phiếu hoàn tiền #10'), findsOneWidget);
    expect(find.text('Phiếu hoàn tiền #9'), findsNothing);
    expect(find.text('Phiếu hoàn tiền #8'), findsNothing);
  });
}
