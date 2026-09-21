import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/complete_inspection_sheet.dart';

import '../../helpers/test_helpers.dart';

class _FakeInspectionService extends LockerOpsService {
  _FakeInspectionService() : super(dio: createMockDio().dio);

  int? completedId;
  Map<String, dynamic>? completedData;
  int layoutCalls = 0;

  @override
  Future<Map<String, dynamic>> layout(int lockerId) async {
    layoutCalls++;
    return {
      'lockerId': lockerId,
      'cells': [
        {'id': 101, 'boxNumber': 1, 'status': 'AVAILABLE'},
        {'id': 102, 'boxNumber': 2, 'status': 'OCCUPIED'},
      ],
    };
  }

  // completeInspection() dựng body rồi gọi completeSchedule ⇒ bắt payload thật.
  @override
  Future<Map<String, dynamic>> completeSchedule(
    int scheduleId, {
    Map<String, dynamic>? data,
  }) async {
    completedId = scheduleId;
    completedData = data;
    final items = (data?['items'] as List?) ?? const [];
    final failed =
        items.any((i) => (i as Map)['result'] == 'FAIL') ||
        data?['status'] == 'FAILED';
    return {
      'id': scheduleId,
      'lastResult': failed ? 'FAILED' : 'PASSED',
      'pendingReportId': failed ? 91 : null,
    };
  }
}

Map<String, dynamic> _schedule({
  List<String>? checklistItems,
  String? checklist,
}) => {
  'id': 5,
  'lockerId': 3,
  'lockerName': 'Tủ A',
  'title': 'Kiểm tra tháng',
  'intervalDays': 30,
  if (checklistItems != null) 'checklistItems': checklistItems,
  if (checklist != null) 'checklist': checklist,
};

void main() {
  late _FakeInspectionService service;
  Map<String, dynamic>? popped;

  setUp(() {
    service = _FakeInspectionService();
    popped = null;
  });

  Future<void> openSheet(
    WidgetTester tester,
    Map<String, dynamic> schedule,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  popped = await showModalBottomSheet<Map<String, dynamic>>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => CompleteInspectionSheet(
                      schedule: schedule,
                      service: service,
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Finder item(int index, String code) =>
      find.byKey(ValueKey('inspection-item-$index-$code'));

  final submit = find.byKey(const ValueKey('inspection-submit'));

  bool submitEnabled(WidgetTester tester) =>
      tester.widget<ElevatedButton>(submit).onPressed != null;

  test('checklist falls back to splitting the stored checklist text', () {
    expect(
      inspectionChecklistItems({'checklist': 'Khóa\r\nNguồn ; IoT;;Khóa'}),
      ['Khóa', 'Nguồn', 'IoT'],
    );
    expect(
      inspectionChecklistItems({
        'checklistItems': ['A', 'B'],
        'checklist': 'X; Y',
      }),
      ['A', 'B'],
    );
    expect(inspectionChecklistItems({'checklistItems': <String>[]}), isEmpty);
  });

  testWidgets(
    'renders checklistItems and enables submit only when every item has a result',
    (tester) async {
      await openSheet(
        tester,
        _schedule(
          checklistItems: ['Khóa điện tử', 'Nguồn UPS', 'Kết nối IoT'],
          checklist: 'Mục cũ; Không dùng',
        ),
      );

      expect(find.text('1. Khóa điện tử'), findsOneWidget);
      expect(find.text('2. Nguồn UPS'), findsOneWidget);
      expect(find.text('3. Kết nối IoT'), findsOneWidget);
      expect(find.textContaining('Mục cũ'), findsNothing);
      expect(find.text('Đạt'), findsNWidgets(3));
      expect(find.text('Không áp dụng'), findsNWidgets(3));
      expect(submitEnabled(tester), isFalse);

      await tapVisible(tester, item(0, 'PASS'));
      await tapVisible(tester, item(1, 'PASS'));
      expect(submitEnabled(tester), isFalse);
      expect(find.textContaining('Còn 1/3 hạng mục'), findsOneWidget);

      await tapVisible(tester, item(2, 'NA'));
      expect(submitEnabled(tester), isTrue);
      expect(find.textContaining('Kết quả: ĐẠT'), findsOneWidget);
      // Không có mục Không đạt ⇒ không hỏi ô hỏng, không tải layout.
      expect(find.byKey(const ValueKey('inspection-fault-box')), findsNothing);
      expect(service.layoutCalls, 0);

      await tapVisible(tester, submit);

      expect(service.completedId, 5);
      expect(service.completedData, {
        'items': [
          {'label': 'Khóa điện tử', 'result': 'PASS'},
          {'label': 'Nguồn UPS', 'result': 'PASS'},
          {'label': 'Kết nối IoT', 'result': 'NA'},
        ],
      });
      expect(popped?['lastResult'], 'PASSED');
    },
  );

  testWidgets('a failed item picks a faulty box and sends it with the items', (
    tester,
  ) async {
    await openSheet(
      tester,
      _schedule(checklistItems: ['Khóa điện tử', 'Cửa ô']),
    );

    await tapVisible(tester, item(0, 'PASS'));
    await tapVisible(tester, item(1, 'FAIL'));
    expect(find.textContaining('Kết quả: KHÔNG ĐẠT'), findsOneWidget);
    expect(service.layoutCalls, 1);

    await tester.enterText(
      find.widgetWithText(TextField, 'Mô tả lỗi phát hiện (tuỳ chọn)'),
      'Bản lề lệch',
    );
    await tapVisible(
      tester,
      find.byKey(const ValueKey('inspection-fault-box')),
    );
    await tester.tap(find.text('Ô #2 · Có đồ').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Mô tả sự cố (tuỳ chọn)'),
      'Ô 2 kẹt cửa',
    );

    await tapVisible(tester, submit);

    expect(service.completedData, {
      'items': [
        {'label': 'Khóa điện tử', 'result': 'PASS'},
        {'label': 'Cửa ô', 'result': 'FAIL', 'note': 'Bản lề lệch'},
      ],
      'faultBoxId': 102,
      'faultReason': 'Ô 2 kẹt cửa',
    });
    expect(popped?['pendingReportId'], 91);
  });

  testWidgets('schedule without checklist sends the legacy status', (
    tester,
  ) async {
    await openSheet(tester, _schedule());

    expect(find.textContaining('chưa có checklist'), findsOneWidget);
    expect(submitEnabled(tester), isFalse);

    await tapVisible(
      tester,
      find.byKey(const ValueKey('inspection-overall-FAIL')),
    );
    expect(submitEnabled(tester), isTrue);

    await tapVisible(tester, submit);

    expect(service.completedData, {'status': 'FAILED'});
    expect(popped?['lastResult'], 'FAILED');
  });
}
