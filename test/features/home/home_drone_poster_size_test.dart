import 'dart:ui' show Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/home/presentation/pages/home_page.dart';

/// Bề ngang khung = màn hình trừ lề 20 mỗi bên.
Size _poster(double screenWidth, double screenHeight) => homeDronePosterSize(
  availableWidth: screenWidth - 40,
  screenHeight: screenHeight,
);

void main() {
  test(
    'điện thoại phổ biến: poster cao ~24% màn hình, không chiếm nửa trang',
    () {
      for (final (w, h) in [(360.0, 780.0), (393.0, 852.0), (412.0, 915.0)]) {
        final size = _poster(w, h);
        expect(size.width, w - 40);
        expect(size.height, closeTo(h * 0.24, 0.01), reason: '$w×$h');
        expect(size.height / h, lessThan(0.25));
        // Cùng dáng banner trên mọi điện thoại.
        expect(size.width / size.height, inInclusiveRange(1.6, 1.75));
      }
    },
  );

  test('máy màn thấp (SE) vẫn giữ tối thiểu 150 để đọc được chữ', () {
    expect(_poster(320, 568).height, 150);
  });

  test(
    'màn rất hẹp: không cao quá mức vừa khít bề ngang (ảnh lấp đầy, không viền)',
    () {
      final size = _poster(200, 800);
      expect(size.height, closeTo(160 * 1331 / 1600, 0.01));
    },
  );

  test('tablet: cao tối đa 240, khung gọn ở giữa cùng dáng banner', () {
    for (final (w, h) in [(820.0, 1180.0), (1024.0, 1366.0)]) {
      final size = _poster(w, h);
      expect(size.height, 240);
      expect(size.width, closeTo(240 * 1600 / 1331 * 1.45, 0.01));
    }
  });

  test('xoay ngang: thấp 150 để còn chỗ cho nội dung khác', () {
    final size = _poster(780, 360);
    expect(size.height, 150);
    expect(size.width, closeTo(150 * 1600 / 1331 * 1.45, 0.01));
  });
}
