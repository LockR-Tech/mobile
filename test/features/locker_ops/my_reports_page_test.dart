import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/pages/my_reports_page.dart';

import '../../helpers/test_helpers.dart';

class _FakeReportsService extends LockerOpsService {
  _FakeReportsService(this._mockReports) : super(dio: createMockDio().dio);

  final List<Map<String, dynamic>> _mockReports;

  @override
  Future<List<Map<String, dynamic>>> myReports() async => _mockReports;
}

void main() {
  Future<void> pumpPage(
    WidgetTester tester,
    LockerOpsService service,
  ) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: MyReportsPage(service: service),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('hiển thị danh sách báo cáo với phân loại theo ngày và bộ lọc', (
    tester,
  ) async {
    final mockReports = [
      {
        'id': 29,
        'status': 'OPEN',
        'title': 'tu hu o 6',
        'description': 'gffdgdf',
        'lockerName': 'Tủ Vinhomes Grand Park S5.02',
        'boxNumber': 6,
        'createdAt': '2026-10-16T08:00:00Z',
        'attachments': [
          {'url': 'https://example.com/p1.jpg', 'type': 'REPORT'},
        ],
      },
      {
        'id': 20,
        'status': 'RESOLVED',
        'title': 'tu hu 1/10',
        'description': 'o so 3 hu',
        'lockerName': 'Tủ Vinhomes Grand Park S5.02',
        'boxNumber': 3,
        'createdAt': '2026-10-01T08:00:00Z',
        'attachments': [
          {'url': 'https://example.com/p2.jpg', 'type': 'REPORT'},
        ],
      },
      {
        'id': 19,
        'status': 'RESOLVED',
        'title': 'test 2909',
        'description': 'dasfbalsdkjflaskdj',
        'lockerName': 'Tủ Vinhomes Grand Park S5.02',
        'boxNumber': 3,
        'createdAt': '2026-09-29T08:00:00Z',
        'attachments': const [],
      },
    ];

    final service = _FakeReportsService(mockReports);
    await pumpPage(tester, service);

    // Verify filter chips exist
    expect(find.text('Tất cả'), findsOneWidget);
    expect(find.text('Chờ tiếp nhận'), findsWidgets);
    expect(find.text('Đã xong'), findsWidgets);
    expect(find.text('Có ảnh'), findsOneWidget);

    // Verify date headers exist
    expect(find.textContaining('16 tháng 10'), findsWidgets);
    expect(find.textContaining('1 tháng 10'), findsWidgets);

    // Verify report cards
    expect(find.text('Phiếu sự cố #29'), findsOneWidget);
    expect(find.text('Phiếu sự cố #20'), findsOneWidget);

    // Tap on 'Chờ tiếp nhận' filter chip
    await tester.tap(find.text('Chờ tiếp nhận').first);
    await tester.pumpAndSettle();

    // Only report #29 should be visible
    expect(find.text('Phiếu sự cố #29'), findsOneWidget);
    expect(find.text('Phiếu sự cố #20'), findsNothing);
    expect(find.text('Phiếu sự cố #19'), findsNothing);

    // Tap on 'Đang xử lý' filter (0 items)
    await tester.ensureVisible(find.text('Đang xử lý').first);
    await tester.tap(find.text('Đang xử lý').first);
    await tester.pumpAndSettle();

    expect(find.text('Không có báo cáo phù hợp'), findsOneWidget);
    expect(find.text('Xem tất cả báo cáo'), findsOneWidget);

    // Tap 'Xem tất cả báo cáo'
    await tester.tap(find.text('Xem tất cả báo cáo'));
    await tester.pumpAndSettle();

    // All reports should be visible again
    expect(find.text('Phiếu sự cố #29'), findsOneWidget);
    expect(find.text('Phiếu sự cố #20'), findsOneWidget);
  });
}
