import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/shared/widgets/home_motion.dart';

void main() {
  Future<void> pumpStrip(
    WidgetTester tester, {
    required int count,
    bool reduceMotion = false,
  }) async {
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: const Size(400, 800),
          disableAnimations: reduceMotion,
        ),
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                child: AutoScrollStrip(
                  height: 100,
                  itemWidth: 250,
                  itemCount: count,
                  itemBuilder: (_, i) =>
                      Container(key: ValueKey('card-$i'), color: Colors.blue),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  double offset(WidgetTester tester) =>
      tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels;

  Future<void> run(WidgetTester tester, Duration d) async {
    for (var t = Duration.zero; t < d; t += const Duration(milliseconds: 16)) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  testWidgets(
    'dãy dài hơn màn hình tự trôi và nối vòng (thẻ đầu xuất hiện lại sau thẻ cuối)',
    (tester) async {
      await pumpStrip(tester, count: 3);
      await run(tester, const Duration(seconds: 2));
      expect(offset(tester), greaterThan(30));

      // 3 thẻ × 264 = 792 px: trôi quá một vòng vẫn còn thẻ để hiện.
      await run(tester, const Duration(seconds: 32));
      expect(offset(tester), greaterThan(792));
      expect(find.byKey(const ValueKey('card-0')), findsWidgets);
    },
  );

  testWidgets('chạm vào thì dừng, thả tay 3 giây sau mới trôi tiếp', (
    tester,
  ) async {
    await pumpStrip(tester, count: 3);
    await run(tester, const Duration(milliseconds: 500));

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(AutoScrollStrip)),
      kind: PointerDeviceKind.touch,
    );
    await tester.pump();
    final held = offset(tester);
    await run(tester, const Duration(seconds: 1));
    expect(offset(tester), held);

    await gesture.up();
    await run(tester, const Duration(seconds: 2));
    expect(offset(tester), held);
    await run(tester, const Duration(seconds: 2));
    expect(offset(tester), greaterThan(held));
  });

  testWidgets('dãy vừa màn hình hoặc bật giảm chuyển động ⇒ đứng yên', (
    tester,
  ) async {
    await pumpStrip(tester, count: 1);
    await run(tester, const Duration(seconds: 2));
    expect(offset(tester), 0);

    await pumpStrip(tester, count: 3, reduceMotion: true);
    await run(tester, const Duration(seconds: 2));
    expect(offset(tester), 0);
  });
}
