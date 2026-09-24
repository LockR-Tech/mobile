import 'package:flutter/material.dart';
import 'package:smart_laundry_locker/shared/widgets/app_lottie.dart';

/// Trạng thái kết quả thanh toán: Thành công hoặc Thất bại.
enum PaymentStatusType {
  success,
  failure,
}

/// Widget hiển thị kết quả giao dịch thanh toán kèm animation 3D Lottie mượt mà.
class AppPaymentStatusView extends StatelessWidget {
  const AppPaymentStatusView({
    super.key,
    required this.type,
    this.title,
    this.amountText,
    this.message,
    this.primaryButtonText,
    this.onPrimaryAction,
    this.secondaryButtonText,
    this.onSecondaryAction,
    this.iconSize = 130.0,
    this.detailsWidget,
  });

  /// Loại kết quả: Thành công hoặc Thất bại
  final PaymentStatusType type;

  /// Tiêu đề (Mặc định: 'Thanh toán thành công' hoặc 'Thanh toán thất bại')
  final String? title;

  /// Số tiền giao dịch hiển thị nổi bật (vd: '50.000 đ')
  final String? amountText;

  /// Mô tả chi tiết hoặc nguyên nhân
  final String? message;

  /// Nhãn nút chính (vd: 'Xem đơn hàng', 'Về trang chủ', 'Thử lại')
  final String? primaryButtonText;

  /// Callback khi ấn nút chính
  final VoidCallback? onPrimaryAction;

  /// Nhãn nút phụ (vd: 'Đóng', 'Hủy')
  final String? secondaryButtonText;

  /// Callback khi ấn nút phụ
  final VoidCallback? onSecondaryAction;

  /// Kích thước của hình minh hoạ 3D Lottie
  final double iconSize;

  /// Widget mở rộng để truyền thêm thông tin chi tiết (nếu có)
  final Widget? detailsWidget;

  bool get isSuccess => type == PaymentStatusType.success;

  @override
  Widget build(BuildContext context) {
    final effectiveTitle = title ??
        (isSuccess ? 'Thanh toán thành công' : 'Thanh toán thất bại');

    final effectiveColor =
        isSuccess ? const Color(0xFF16A34A) : const Color(0xFFDC2626);

    final lottieAsset = isSuccess
        ? AppLottieAssets.daThanhToan
        : AppLottieAssets.thatBaiThanhToan;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            // Hiệu ứng chuyển động xuất hiện mượt mà (Scale + Bounce) cho hình 3D Lottie
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 700),
              curve: Curves.elasticOut,
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: child,
                );
              },
              child: Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: effectiveColor.withValues(alpha: 0.18),
                      blurRadius: 36,
                      spreadRadius: 8,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: AppLottie(
                  lottieAsset,
                  animate: true,
                  fit: BoxFit.contain,
                  fallback: (_) => Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSuccess
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFFEE2E2),
                    ),
                    child: Icon(
                      isSuccess ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      size: iconSize * 0.65,
                      color: effectiveColor,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Tiêu đề
            Text(
              effectiveTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: effectiveColor,
                letterSpacing: -0.3,
              ),
            ),

            // Số tiền nếu có
            if (amountText != null && amountText!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                amountText!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
            ],

            // Lời nhắn / Mô tả
            if (message != null && message!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                  height: 1.45,
                ),
              ),
            ],

            // Chi tiết bổ sung (nếu có)
            if (detailsWidget != null) ...[
              const SizedBox(height: 18),
              detailsWidget!,
            ],

            const SizedBox(height: 24),

            // Các nút thao tác
            if (primaryButtonText != null)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: onPrimaryAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: effectiveColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    primaryButtonText!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

            if (secondaryButtonText != null) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: onSecondaryAction,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF475569),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    secondaryButtonText!,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Helper hiển thị Modal Dialog kết quả thanh toán
Future<T?> showPaymentResultDialog<T>(
  BuildContext context, {
  required PaymentStatusType type,
  String? title,
  String? amountText,
  String? message,
  String? primaryButtonText,
  VoidCallback? onPrimaryAction,
  String? secondaryButtonText,
  VoidCallback? onSecondaryAction,
  Widget? detailsWidget,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: AppPaymentStatusView(
        type: type,
        title: title,
        amountText: amountText,
        message: message,
        detailsWidget: detailsWidget,
        primaryButtonText: primaryButtonText ??
            (type == PaymentStatusType.success ? 'Hoàn tất' : 'Đóng'),
        onPrimaryAction: () {
          Navigator.of(dialogContext).pop();
          onPrimaryAction?.call();
        },
        secondaryButtonText: secondaryButtonText,
        onSecondaryAction: () {
          Navigator.of(dialogContext).pop();
          onSecondaryAction?.call();
        },
      ),
    ),
  );
}
