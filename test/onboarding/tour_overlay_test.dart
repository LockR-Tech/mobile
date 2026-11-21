// Lớp khoanh của hướng dẫn lần đầu (F3-G13): khoanh phần tử có neo, bước optional thiếu phần tử bị bỏ qua,
// bước thường thiếu phần tử hiện câu báo, Tiếp/Quay lại/Esc, ghi "đã xem" khi xong nhóm.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/onboarding/domain/tour_models.dart';
import 'package:smart_laundry_locker/features/onboarding/presentation/tour_anchor.dart';
import 'package:smart_laundry_locker/features/onboarding/presentation/tour_overlay.dart';

TourStep _step(String id, String? anchor, {bool optional = false}) =>
    TourStep(id: id, anchor: anchor, optional: optional, platforms: const ['mobile']);

void main() {
  late List<String> done;
  late List<bool> closed;

  Future<void> pump(WidgetTester tester, List<TourGroup> groups) async {
    done = [];
    closed = [];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            Column(
              children: const [
                SizedBox(height: 80),
                TourAnchor('btn-a', child: SizedBox(width: 120, height: 40, child: Text('A'))),
                SizedBox(height: 200),
                TourAnchor('btn-b', child: SizedBox(width: 120, height: 40, child: Text('B'))),
              ],
            ),
            Positioned.fill(
              child: TourOverlay(
                groups: groups,
                text: (key) => key,
                findTimeout: const Duration(milliseconds: 300),
                onGroupDone: (g) => done.add(g.id),
                onClose: closed.add,
              ),
            ),
          ],
        ),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  String title(WidgetTester tester) => tester.widget<Text>(find.byKey(const ValueKey('tour-step-title'))).data!;

  testWidgets('đi qua các bước, bỏ qua bước optional thiếu, báo bước thường thiếu, xong thì ghi đã xem',
      (tester) async {
    await pump(tester, [
      TourGroup(id: 'g1', version: 2, roles: const ['CUSTOMER'], steps: [
        _step('g1-intro', null),
        _step('g1-a', 'btn-a'),
        _step('g1-skip', 'khong-co', optional: true),
        _step('g1-missing', 'cung-khong-co'),
      ]),
      TourGroup(id: 'g2', version: 1, roles: const ['CUSTOMER'], steps: [_step('g2-b', 'btn-b')]),
    ]);
    expect(title(tester), 'steps.g1-intro.title');
    expect(find.byKey(const ValueKey('tour-missing')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('tour-next')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(title(tester), 'steps.g1-a.title');

    await tester.tap(find.byKey(const ValueKey('tour-next')));
    await tester.pump();
    // bước optional: chờ hết thời gian tìm rồi tự bỏ qua, sang bước thường cũng không có phần tử
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(title(tester), 'steps.g1-missing.title');
    expect(find.byKey(const ValueKey('tour-missing')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('tour-next')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(done, ['g1']);
    expect(title(tester), 'steps.g2-b.title');

    await tester.tap(find.byKey(const ValueKey('tour-next')));
    await tester.pump();
    expect(done, ['g1', 'g2']);
    expect(closed, [true]);
  });

  testWidgets('Quay lại và phím mũi tên, Esc đóng mà không ghi đã xem', (tester) async {
    await pump(tester, [
      TourGroup(id: 'g1', version: 1, roles: const ['CUSTOMER'], steps: [
        _step('g1-a', 'btn-a'),
        _step('g1-b', 'btn-b'),
      ]),
    ]);
    await tester.pump(const Duration(milliseconds: 400));
    expect(title(tester), 'steps.g1-a.title');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(title(tester), 'steps.g1-b.title');
    await tester.tap(find.byKey(const ValueKey('tour-prev')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(title(tester), 'steps.g1-a.title');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(closed, [false]);
    expect(done, isEmpty);
  });
}
