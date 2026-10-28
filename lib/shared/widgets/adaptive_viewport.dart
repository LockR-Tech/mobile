import 'dart:math' as math;
import 'dart:ui' show DisplayFeature;

import 'package:flutter/widgets.dart';

/// Giữ bố cục toàn app giống nhau trên mọi điện thoại.
///
/// UI được thiết kế và kiểm tra trên máy ảo Pixel (cạnh ngắn ~411dp). Nhiều máy
/// thật hẹp hơn hẳn — ví dụ OPPO A77s chỉ 360dp — nên cùng một widget kích
/// thước cố định chiếm nhiều chỗ hơn, trông to ra và dễ tràn (overflow).
///
/// Widget này cho cây con một "màn hình ảo" rộng [designWidth] rồi thu nhỏ đều
/// toàn bộ khi vẽ, nên máy hẹp hiển thị đúng bố cục như trên máy ảo. Máy rộng
/// hơn [designWidth] (máy lớn, tablet, web desktop) giữ nguyên tỉ lệ 1.
///
/// Đặt ngay quanh `child` trong `builder` của app để mọi route, bottom sheet,
/// dialog và toast của Navigator đều nằm trong màn hình ảo.
class AdaptiveViewport extends StatelessWidget {
  const AdaptiveViewport({super.key, required this.child});

  final Widget child;

  /// Cạnh ngắn (dp) của máy ảo Pixel dùng để thiết kế UI.
  static const double designWidth = 411;

  /// Không thu nhỏ quá mức này để chữ trên máy rất hẹp (≤ 320dp) vẫn đọc được.
  static const double minScale = 0.8;

  /// Cỡ chữ hệ thống tối đa app chấp nhận. ColorOS/One UI thường đặt cỡ chữ
  /// mặc định lớn hơn 1, làm chữ to và vỡ bố cục so với máy ảo.
  static const double maxTextScale = 1.1;

  /// Tỉ lệ thu nhỏ cho màn hình [size] (theo cạnh ngắn nên xoay ngang vẫn giữ
  /// cùng tỉ lệ).
  static double scaleFor(Size size) {
    final shortestSide = size.shortestSide;
    if (shortestSide <= 0 || shortestSide >= designWidth) return 1;
    return math.max(shortestSide / designWidth, minScale);
  }

  /// Giới hạn cỡ chữ hệ thống cho [child] — dùng cho lớp phủ nằm ngoài
  /// [AdaptiveViewport] (toast, loading của SmartDialog).
  static Widget clampTextScale({required Widget child}) =>
      MediaQuery.withClampedTextScaling(
        maxScaleFactor: maxTextScale,
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final scale = scaleFor(media.size);
    final textScaler = media.textScaler.clamp(maxScaleFactor: maxTextScale);

    if (scale == 1) {
      return MediaQuery(
        data: media.copyWith(textScaler: textScaler),
        child: child,
      );
    }

    // Mọi kích thước logic trong MediaQuery chia cho [scale]; devicePixelRatio
    // nhân [scale] để số pixel vật lý (ảnh cache, độ nét) không đổi.
    final virtualSize = media.size / scale;
    return MediaQuery(
      data: media.copyWith(
        size: virtualSize,
        devicePixelRatio: media.devicePixelRatio * scale,
        textScaler: textScaler,
        padding: media.padding / scale,
        viewPadding: media.viewPadding / scale,
        viewInsets: media.viewInsets / scale,
        systemGestureInsets: media.systemGestureInsets / scale,
        displayFeatures: [
          for (final feature in media.displayFeatures)
            DisplayFeature(
              bounds: Rect.fromLTRB(
                feature.bounds.left / scale,
                feature.bounds.top / scale,
                feature.bounds.right / scale,
                feature.bounds.bottom / scale,
              ),
              type: feature.type,
              state: feature.state,
            ),
        ],
      ),
      // FittedBox vẽ cây con với phép scale và đổi toạ độ chạm tương ứng, nên
      // nút bấm, cuộn, popup đều đúng vị trí.
      child: FittedBox(
        fit: BoxFit.fill,
        alignment: Alignment.topLeft,
        child: SizedBox.fromSize(size: virtualSize, child: child),
      ),
    );
  }
}
