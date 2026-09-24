import 'package:flutter/material.dart';
import 'package:smart_laundry_locker/shared/widgets/app_lottie.dart';

/// Loading indicator sử dụng animation Delivery-05 theo chuẩn toàn app.
class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({
    super.key,
    this.size = 84.0,
    this.message,
    this.messageColor,
    this.fullScreen = false,
  });

  /// Kích thước hiển thị (chiều cao & chiều rộng của animation).
  final double size;

  /// Nội dung thông điệp hiển thị kèm theo dưới animation (nếu có).
  final String? message;

  /// Màu sắc của text thông điệp.
  final Color? messageColor;

  /// Nếu true, tự động bọc trong Center và thêm padding thích hợp để căn giữa trang/khung chứa.
  final bool fullScreen;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final widgetContent = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: const AppLottie(
            AppLottieAssets.deliveryLoading,
            animate: true,
            repeat: true,
            fit: BoxFit.contain,
          ),
        ),
        if (message != null && message!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            message!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: messageColor ??
                  (isDark ? Colors.white70 : const Color(0xFF334155)),
              fontWeight: FontWeight.w600,
              fontSize: size >= 70 ? 14 : 12,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ],
    );

    if (fullScreen) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: widgetContent,
        ),
      );
    }

    return widgetContent;
  }
}
