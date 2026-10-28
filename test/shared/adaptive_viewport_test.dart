import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/shared/widgets/adaptive_viewport.dart';

/// Màn OPPO A77s: 720×1612 px, devicePixelRatio 2 ⇒ 360×806 dp.
const _oppoA77s = Size(720, 1612);

void main() {
  group('AdaptiveViewport.scaleFor', () {
    test('máy rộng bằng hoặc hơn máy ảo giữ nguyên', () {
      expect(AdaptiveViewport.scaleFor(const Size(411, 914)), 1);
      expect(AdaptiveViewport.scaleFor(const Size(800, 1280)), 1);
    });

    test('máy hẹp thu nhỏ theo cạnh ngắn, kể cả khi xoay ngang', () {
      expect(AdaptiveViewport.scaleFor(const Size(360, 806)), 360 / 411);
      expect(AdaptiveViewport.scaleFor(const Size(806, 360)), 360 / 411);
    });

    test('không thu nhỏ quá minScale', () {
      expect(
        AdaptiveViewport.scaleFor(const Size(280, 600)),
        AdaptiveViewport.minScale,
      );
    });
  });

  testWidgets('máy 360dp thấy màn ảo rộng 411dp và chạm đúng vị trí', (
    tester,
  ) async {
    tester.view.physicalSize = _oppoA77s;
    tester.view.devicePixelRatio = 2;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    late MediaQueryData inner;
    var tapped = 0;
    await tester.pumpWidget(
      MediaQuery.fromView(
        view: tester.view,
        child: AdaptiveViewport(
          child: Builder(
            builder: (context) {
              inner = MediaQuery.of(context);
              return Directionality(
                textDirection: TextDirection.ltr,
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => tapped++,
                    child: const SizedBox(
                      key: Key('target'),
                      width: 100,
                      height: 100,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    expect(inner.size.width, closeTo(AdaptiveViewport.designWidth, 0.001));
    expect(inner.size.height, closeTo(806 * 411 / 360, 0.001));
    // Pixel vật lý không đổi: kích thước ảo × dpr mới = 720 px.
    expect(inner.size.width * inner.devicePixelRatio, closeTo(720, 0.001));
    expect(inner.textScaler.scale(10), 10 * AdaptiveViewport.maxTextScale);

    // Hộp 100dp ảo chiếm 100 × 360/411 dp thật ở góc dưới phải màn hình.
    final rect = tester.getRect(find.byKey(const Key('target')));
    expect(rect.right, closeTo(360, 0.001));
    expect(rect.bottom, closeTo(806, 0.001));
    expect(rect.width, closeTo(100 * 360 / 411, 0.001));

    await tester.tapAt(rect.center);
    expect(tapped, 1);
    // Chạm ngay ngoài hộp đã thu nhỏ không được tính.
    await tester.tapAt(rect.topLeft - const Offset(2, 2));
    expect(tapped, 1);
  });
}
