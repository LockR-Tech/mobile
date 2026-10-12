import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/schedule_detail_modal_sheet.dart';

import '../../helpers/test_helpers.dart';

class _FakeLockerOpsService extends LockerOpsService {
  _FakeLockerOpsService({this.logs = const [], this.fail = false})
      : super(dio: createMockDio().dio);

  final List<Map<String, dynamic>> logs;
  final bool fail;
  int logsCalledForScheduleId = -1;

  @override
  Future<List<Map<String, dynamic>>> scheduleInspectionLogs(int scheduleId) async {
    logsCalledForScheduleId = scheduleId;
    if (fail) throw Exception('network down');
    return logs;
  }
}

void main() {
  testWidgets('renders all Admin fields and loads inspection logs',
      (tester) async {
    final fakeService = _FakeLockerOpsService(
      logs: [
        {
          'id': 99,
          'status': 'FAILED',
          'note': 'Cảm biến ngăn 4 bị lệch',
          'technicianName': 'Nguyễn Văn A',
          'createdAt': '2026-09-24T10:00:00',
          'checklistResults':
              '[{"label":"Kiểm tra khóa điện tử & tiếp điểm cửa","result":"PASS","note":""},{"label":"Kiểm tra cảm biến nhận diện ô tủ","result":"FAIL","note":"Ngăn 4 chập chờn"}]',
          'createdReportId': 18,
          'photoUrls': ['https://example.com/photo1.jpg'],
        }
      ],
    );

    final schedule = {
      'id': 12,
      'lockerId': 3,
      'lockerName': 'Tủ Landmark 81 B1',
      'lockerCode': 'CAB-LM81-01',
      'title': 'Kiểm tra định kỳ ổ khóa, cảm biến & nguồn UPS',
      'intervalDays': 30,
      'priority': 'HIGH',
      'locationNote': 'Tầng hầm B1, sảnh tháp A, cạnh thang máy',
      'address': '208 Nguyễn Hữu Cảnh, P.22, Bình Thạnh',
      'scheduledTimeSlot': 'Ca sáng (08:00 - 11:30) · Giờ thấp điểm',
      'description': 'Kiểm tra kỹ cảm biến quang ngăn số 4, vệ sinh đầu đọc QR.',
      'checklistItems': [
        'Kiểm tra khóa điện tử & tiếp điểm cửa',
        'Kiểm tra cảm biến nhận diện ô tủ',
        'Kiểm tra nguồn cấp & pin lưu điện UPS',
      ],
      'nextDueAt': '2026-09-25T09:00:00',
      'due': true,
      'assignedTechnicianId': 7,
      'assignedTechnicianName': 'Trần KTV',
      'pendingReportId': 18,
    };

    int? openedReportId;
    Map<String, dynamic>? directionsItem;
    Map<String, dynamic>? startedSchedule;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScheduleDetailModalSheet(
            schedule: schedule,
            service: fakeService,
            isMine: true,
            onOpenDirections: (item) => directionsItem = item,
            onOpenReport: (id) => openedReportId = id,
            onStartInspection: (s) => startedSchedule = s,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Schedule Header and ID
    expect(find.text('#12'), findsOneWidget);
    expect(find.text('Kiểm tra định kỳ ổ khóa, cảm biến & nguồn UPS'),
        findsOneWidget);

    // Verify Admin fields
    expect(find.textContaining('CAB-LM81-01'), findsWidgets);
    expect(find.textContaining('Tầng hầm B1, sảnh tháp A, cạnh thang máy'),
        findsWidgets);
    expect(find.textContaining('208 Nguyễn Hữu Cảnh'), findsWidgets);
    expect(find.textContaining('Ca sáng (08:00 - 11:30)'), findsWidgets);
    expect(find.textContaining('Mỗi 30 ngày'), findsWidgets);
    expect(find.textContaining('Cao'), findsWidgets);
    expect(find.textContaining('Kiểm tra kỹ cảm biến quang ngăn số 4'),
        findsWidgets);

    // Verify Checklist SOP items
    expect(find.textContaining('Kiểm tra khóa điện tử'), findsWidgets);
    expect(find.textContaining('Kiểm tra cảm biến'), findsWidgets);
    expect(find.textContaining('Kiểm tra nguồn cấp'), findsWidgets);

    // Verify Previous Inspection Log Results (Hình 2)
    expect(find.textContaining('KHÔNG ĐẠT'), findsWidgets);
    expect(find.textContaining('Cảm biến ngăn 4 bị lệch'), findsWidgets);
    expect(find.textContaining('Ngăn 4 chập chờn'), findsWidgets);
    expect(find.textContaining('Đạt'), findsWidgets);
    expect(find.textContaining('Không đạt'), findsWidgets);
    // Mã phiếu hiển thị theo định dạng RPT-<id> thống nhất toàn app.
    expect(find.textContaining('Phiếu sự cố kỹ thuật liên quan: RPT-18'),
        findsWidgets);

    // Tap pinned bottom action bar button "Xử lý phiếu sự cố RPT-18"
    final bottomBtn = find.text('Xử lý phiếu sự cố RPT-18');
    expect(bottomBtn, findsOneWidget);
    await tester.tap(bottomBtn);
    expect(openedReportId, 18);
  });

  testWidgets('renders fresh schedule with no previous logs and enables start inspection',
      (tester) async {
    final fakeService = _FakeLockerOpsService(logs: []);

    final schedule = {
      'id': 15,
      'lockerId': 3,
      'lockerName': 'Tủ Kiosk Park 5',
      'title': 'Bảo dưỡng trạm',
      'intervalDays': 14,
      'priority': 'NORMAL',
      'checklistItems': ['Vệ sinh trạm tủ', 'Kiểm tra 4G'],
      'nextDueAt': '2026-09-30T09:00:00',
      'due': false,
    };

    Map<String, dynamic>? startedSchedule;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScheduleDetailModalSheet(
            schedule: schedule,
            service: fakeService,
            isMine: true,
            onOpenDirections: (_) {},
            onOpenReport: (_) {},
            onStartInspection: (s) => startedSchedule = s,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('#15'), findsOneWidget);
    expect(find.text('Bảo dưỡng trạm'), findsOneWidget);
    expect(find.textContaining('Chưa có dữ liệu kiểm tra lần trước'),
        findsOneWidget);

    final startBtn = find.text('Kiểm tra ngay');
    expect(startBtn, findsOneWidget);
    await tester.tap(startBtn);
    expect(startedSchedule?['id'], 15);
  });

  testWidgets(
      'schedule chỉ có lastDoneAt/lastResult ⇒ chỉ hiện kết quả chung, không bịa từng mục (D18)',
      (tester) async {
    final fakeService = _FakeLockerOpsService(logs: []);

    final schedule = {
      'id': 11,
      'lockerId': 3,
      'lockerName': 'Tủ Landmark 81 B1',
      'lockerCode': 'CAB-LM81-01',
      'title': 'cam biến và nguồn',
      'intervalDays': 3,
      'priority': 'NORMAL',
      'locationNote': 'cạnh thang máy 1',
      'address': 'Tầng hầm B1, Landmark 81',
      'description': 'Quy trình kiểm tra định kỳ tại Kiosk: 1. KTV đến...',
      'checklistItems': [
        'Cảm biến nhận diện ô tủ',
        'Khóa chốt điện tử',
        'Nguồn điện & pin UPS',
      ],
      'nextDueAt': '2026-09-27T21:41:36',
      'lastDoneAt': '2026-09-24T21:41:36',
      'lastResult': 'PASSED',
      'due': false,
      'assignedTechnicianName': 'KTV Kiosk',
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScheduleDetailModalSheet(
            schedule: schedule,
            service: fakeService,
            isMine: true,
            onOpenDirections: (_) {},
            onOpenReport: (_) {},
            onStartInspection: (_) {},
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Kết quả chung lấy từ lịch.
    expect(find.textContaining('ĐẠT — Toàn bộ tiêu chí đạt yêu cầu'), findsOneWidget);
    // Không có nhật ký chi tiết ⇒ không dựng kết quả từng mục.
    expect(find.textContaining('Chi tiết đánh giá từng hạng mục'), findsNothing);
    expect(find.text('✓ Đạt'), findsNothing);
    expect(find.textContaining('không lưu kết quả từng hạng mục'), findsOneWidget);
    // Không suy tên KTV kiểm tra từ người được giao lịch.
    expect(find.textContaining('KTV: KTV Kiosk'), findsNothing);
    // Checklist SOP vẫn hiện ở mục bộ tiêu chí.
    expect(find.textContaining('Cảm biến nhận diện ô tủ'), findsWidgets);
  });

  testWidgets('log chỉ chấm một phần checklist ⇒ không tự thêm mục chưa chấm',
      (tester) async {
    final fakeService = _FakeLockerOpsService(
      logs: [
        {
          'id': 5,
          'status': 'PASSED',
          'createdAt': '2026-09-24T10:00:00',
          'checklistResults':
              '[{"label":"Khóa chốt điện tử","result":"PASS","note":""}]',
        }
      ],
    );
    final schedule = {
      'id': 21,
      'lockerId': 3,
      'title': 'Kiểm tra khoá',
      'intervalDays': 7,
      'checklistItems': ['Khóa chốt điện tử', 'Nguồn điện & pin UPS'],
      'nextDueAt': '2026-09-30T09:00:00',
      'lastDoneAt': '2026-09-24T10:00:00',
      'due': false,
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScheduleDetailModalSheet(
            schedule: schedule,
            service: fakeService,
            isMine: true,
            onOpenDirections: (_) {},
            onOpenReport: (_) {},
            onStartInspection: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('Chi tiết đánh giá từng hạng mục (1 mục):'), findsOneWidget);
    expect(find.text('✓ Đạt'), findsOneWidget);
  });

  testWidgets('lỗi tải nhật ký ⇒ báo lỗi + Thử lại (không coi là chưa kiểm tra)',
      (tester) async {
    final fakeService = _FakeLockerOpsService(fail: true);
    final schedule = {
      'id': 22,
      'lockerId': 3,
      'title': 'Kiểm tra nguồn',
      'intervalDays': 7,
      'checklistItems': <String>[],
      'nextDueAt': '2026-09-30T09:00:00',
      'due': false,
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScheduleDetailModalSheet(
            schedule: schedule,
            service: fakeService,
            isMine: true,
            onOpenDirections: (_) {},
            onOpenReport: (_) {},
            onStartInspection: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('Không tải được nhật ký kiểm tra'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
    expect(find.textContaining('Chưa có dữ liệu kiểm tra lần trước'), findsNothing);
  });

  test('previousInspectionOutcome không mặc định là ĐẠT', () {
    expect(previousInspectionOutcome('PASSED'), isTrue);
    expect(previousInspectionOutcome('fail'), isFalse);
    expect(previousInspectionOutcome(null), isNull);
    expect(previousInspectionOutcome('UNKNOWN'), isNull);
  });
}
