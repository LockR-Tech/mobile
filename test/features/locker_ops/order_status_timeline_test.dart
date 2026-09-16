import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/order_status_timeline.dart';

import '../../helpers/test_helpers.dart';

/// Trả về đúng những gì bài kiểm thử dựng sẵn cho `GET /api/orders/{id}/timeline`.
class _FakeTimelineService extends LockerOpsService {
  _FakeTimelineService({this.events, this.fails = false})
    : super(dio: createMockDio().dio);

  final List<Map<String, dynamic>>? events;
  final bool fails;

  @override
  Future<List<Map<String, dynamic>>> orderTimeline(int orderId) async {
    if (fails) throw Exception('mạng lỗi');
    return events ?? const [];
  }
}

Widget _wrap(LockerOpsService service) => MaterialApp(
  home: Scaffold(
    body: SingleChildScrollView(
      child: OrderStatusTimeline(orderId: 21, service: service),
    ),
  ),
);

void main() {
  testWidgets('hiện từng lần chuyển trạng thái kèm giờ:phút:giây', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        _FakeTimelineService(
          events: [
            {
              'oldStatus': null,
              'newStatus': 'INITIALIZED',
              'note': 'Order created',
              'createdAt': '2026-09-15T02:10:44',
            },
            {
              'oldStatus': 'INITIALIZED',
              'newStatus': 'STORING',
              'note': 'Sender dropped parcel',
              'createdAt': '2026-09-15T02:20:00',
            },
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Nhãn tiếng Việt của trạng thái, không phải mã thô.
    expect(find.text('Chờ bỏ đồ'), findsOneWidget);
    expect(find.text('Đang trong tủ'), findsOneWidget);

    // Trạng thái trước đó giúp đọc được đơn đã đi qua đường nào.
    expect(find.text('Từ Chờ bỏ đồ'), findsOneWidget);

    expect(find.text('Order created'), findsOneWidget);
    expect(find.text('Sender dropped parcel'), findsOneWidget);

    // Thời gian đúng định dạng dùng chung của app và CÓ ĐỦ GIÂY.
    // Không khẳng định giờ tuyệt đối: `fmtDateTime` đổi sang giờ máy chạy, mà
    // runner CI chạy UTC còn máy dev chạy giờ Việt Nam.
    final timeFormat = RegExp(r'^\d{2}:\d{2}:\d{2} \d{2}/\d{2}/\d{4}$');
    expect(
      find.byWidgetPredicate(
        (w) => w is Text && timeFormat.hasMatch(w.data ?? ''),
      ),
      findsNWidgets(2),
    );
  });

  testWidgets('đơn chưa có bản ghi nào thì nói rõ, không để trống', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(_FakeTimelineService(events: const [])));
    await tester.pumpAndSettle();

    expect(find.text('Chưa có chuyển trạng thái nào.'), findsOneWidget);
  });

  testWidgets('lỗi mạng thì báo lỗi và cho bấm tải lại', (tester) async {
    await tester.pumpWidget(_wrap(_FakeTimelineService(fails: true)));
    await tester.pumpAndSettle();

    expect(find.text('Không tải được lịch sử trạng thái.'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
  });
}
