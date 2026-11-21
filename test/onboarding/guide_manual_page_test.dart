// Trang HDSD trong app (F3-G13): mỗi nhóm tóm tắt + số thứ tự ↔ bước theo file toạ độ của ảnh; thiếu file thì
// đánh số theo thứ tự bước có neo; "Xem trên màn hình" chỉ có ở nhóm chạy được trên app.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/onboarding/data/onboarding_repository.dart';
import 'package:smart_laundry_locker/features/onboarding/domain/tour_models.dart';
import 'package:smart_laundry_locker/features/onboarding/presentation/guide_manual_page.dart';

/// `implements` (không `extends`) để không dựng ApiClient thật — nó đọc token từ secure storage.
class _FakeRepo implements OnboardingRepository {
  _FakeRepo(this.marks);

  final Map<String, List<ManualMark>?> marks;

  @override
  Future<List<ManualMark>?> loadManualMarks(String group) async => marks[group];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

TourStep _s(String id, String? anchor, List<String> platforms) => TourStep(id: id, anchor: anchor, platforms: platforms);

void main() {
  final appGroup = TourGroup(id: 'customer-home', version: 1, roles: const ['CUSTOMER'], steps: [
    _s('c-intro', null, const ['mobile']),
    _s('c-a', 'home-a', const ['mobile']),
    _s('c-b', 'home-b', const ['mobile']),
  ]);
  final webGroup = TourGroup(id: 'admin-orders', version: 1, roles: const ['ADMIN'], steps: [
    _s('o-filters', 'orders-filters', const ['web']),
    _s('o-list', 'orders-list', const ['web']),
  ]);

  Future<List<String>> pump(WidgetTester tester, Map<String, List<ManualMark>?> marks) async {
    final ran = <String>[];
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => GuideManualPage(
                groups: [webGroup, appGroup],
                text: (key) => key,
                repository: _FakeRepo(marks),
                showImages: false,
                onRun: (g) => ran.add(g.id),
              ),
            )),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return ran;
  }

  testWidgets('số theo file toạ độ, nhóm web không có nút chạy, nhóm app chạy được', (tester) async {
    final ran = await pump(tester, {
      'admin-orders': const [ManualMark(1, 'o-list'), ManualMark(2, 'o-filters')],
      'customer-home': null,
    });
    expect(find.byKey(const ValueKey('tour-manual')), findsOneWidget);
    expect(find.text('groups.admin-orders.title'), findsOneWidget);
    expect(find.text('groups.customer-home.summary'), findsOneWidget);
    // Thứ tự theo file toạ độ: o-list là số 1.
    final listY = tester.getTopLeft(find.text('steps.o-list.title')).dy;
    final filtersY = tester.getTopLeft(find.text('steps.o-filters.title')).dy;
    expect(listY, lessThan(filtersY));
    // Bước không neo của nhóm app là đoạn giới thiệu, không có số.
    expect(find.text('steps.c-intro.body'), findsOneWidget);
    expect(find.text('steps.c-intro.title'), findsNothing);
    // Chỉ nhóm app có nút "Xem trên màn hình".
    final run = find.byType(OutlinedButton);
    expect(run, findsOneWidget);
    await tester.ensureVisible(run);
    await tester.tap(run);
    await tester.pumpAndSettle();
    expect(ran, ['customer-home']);
    expect(find.byKey(const ValueKey('tour-manual')), findsNothing);
  });

  testWidgets('thiếu file toạ độ: đánh số theo thứ tự bước có neo', (tester) async {
    await pump(tester, const {});
    final aY = tester.getTopLeft(find.text('steps.c-a.title')).dy;
    final bY = tester.getTopLeft(find.text('steps.c-b.title')).dy;
    expect(aY, lessThan(bY));
    expect(find.text('1'), findsNWidgets(2));
    expect(find.text('2'), findsNWidgets(2));
  });
}
