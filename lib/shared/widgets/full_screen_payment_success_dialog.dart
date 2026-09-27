import 'dart:async';

import 'package:flutter/material.dart';
import 'package:smart_laundry_locker/shared/widgets/app_lottie.dart';

/// Màn hình / Dialog hiển thị animation thanh toán thành công full màn hình
/// trước khi chuyển sang màn hình hiển thị thông tin mã PIN (Hình 2).
class FullScreenPaymentSuccessDialog extends StatefulWidget {
  const FullScreenPaymentSuccessDialog({
    super.key,
    this.duration = const Duration(milliseconds: 3200),
    this.onPrepareNextScreen,
  });

  /// Thời lượng hiển thị animation trước khi tự động đóng để chuyển màn hình.
  final Duration duration;

  /// Tác vụ chuẩn bị dữ liệu nền (vd: làm mới đơn hàng) trong lúc animation đang chạy.
  final Future<void> Function()? onPrepareNextScreen;

  /// Hiển thị dialog toàn màn hình.
  static Future<void> show(
    BuildContext context, {
    Duration duration = const Duration(milliseconds: 3200),
    Future<void> Function()? onPrepareNextScreen,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.white,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, __, ___) => FullScreenPaymentSuccessDialog(
        duration: duration,
        onPrepareNextScreen: onPrepareNextScreen,
      ),
      transitionBuilder: (_, anim, __, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: child,
        );
      },
    );
  }

  @override
  State<FullScreenPaymentSuccessDialog> createState() =>
      _FullScreenPaymentSuccessDialogState();
}

class _FullScreenPaymentSuccessDialogState
    extends State<FullScreenPaymentSuccessDialog> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Tải trước dữ liệu màn hình sau trong lúc xem animation
    if (widget.onPrepareNextScreen != null) {
      unawaited(widget.onPrepareNextScreen!());
    }

    _timer = Timer(widget.duration, () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _dismissNow() {
    _timer?.cancel();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: InkWell(
            onTap: _dismissNow,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: SizedBox.expand(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),

                  // Tiêu đề nhỏ gọn ở trên đầu theo yêu cầu
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF16A34A),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Thanh toán thành công!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF16A34A),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Đang chuẩn bị mã PIN mở ô tủ...',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  // Animation phóng to tối đa chiếm trọn màn hình
                  Expanded(
                    child: Center(
                      child: Transform.scale(
                        scale: 1.18,
                        child: const AppLottie(
                          AppLottieAssets.thanhCongAnimation,
                          animate: true,
                          repeat: false,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),

                  // Gợi ý chạm để tiếp tục
                  TextButton(
                    onPressed: _dismissNow,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF94A3B8),
                    ),
                    child: const Text(
                      'Chạm để tiếp tục',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
