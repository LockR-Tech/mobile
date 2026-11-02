import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/core/theme/shadcn_theme.dart';

/// Loại tin của toast — quyết định icon và màu nhấn.
enum ToastTone { success, error, warning, info }

/// Đoán loại tin từ câu (tiếng Việt hoặc tiếng Anh, kể cả câu server trả về
/// đã dịch). Xét lỗi trước: "Đã xảy ra lỗi" là lỗi chứ không phải "đã xong".
ToastTone toastToneOf(String message) {
  final m = message.toLowerCase();
  bool any(List<String> words) => words.any(m.contains);

  if (any(const [
    'lỗi',
    'thất bại',
    'không thành công',
    'chưa thành công',
    'không thể',
    'không được',
    'không hợp lệ',
    'không đúng',
    'không đủ',
    'không tìm thấy',
    'hết hạn',
    'không phản hồi',
    'bị từ chối',
    'sai ',
    'chưa gửi được',
    'chưa tải được',
    'error',
    'failed',
    'unsuccessful',
    'invalid',
    'cannot',
    "can't",
    'could not',
    'did not',
    'not found',
    'expired',
    'incorrect',
    'wrong',
    'denied',
    'rejected',
    'insufficient',
    'not enough',
    'unable',
  ])) {
    return ToastTone.error;
  }
  if (any(const [
    'thành công',
    'đã ',
    'xong',
    'hoàn tất',
    'success',
    'saved',
    'sent',
    'done',
    'completed',
    'confirmed',
    'updated',
    'added',
    'copied',
    'approved',
    'cancelled',
    'canceled',
    'deleted',
  ])) {
    return ToastTone.success;
  }
  if (any(const [
    'cảnh báo',
    'chú ý',
    'vui lòng',
    'hãy ',
    'cần ',
    'warning',
    'please',
    'required',
    'must ',
  ])) {
    return ToastTone.warning;
  }
  return ToastTone.info;
}

/// Toast toàn app (SmartDialog `toastBuilder`): thẻ nổi nền trắng/than, viền
/// mảnh, icon màu theo loại tin — cùng ngôn ngữ thiết kế với shadcn_ui.
class AppToast extends StatelessWidget {
  const AppToast({
    super.key,
    required this.message,
    this.tone,
    this.margin = const EdgeInsets.fromLTRB(16, 0, 16, 48),
  });

  final String message;

  /// Mặc định chừa chỗ thanh điều hướng dưới (toast nằm đáy màn hình).
  final EdgeInsets margin;

  /// Bỏ trống ⇒ đoán từ câu bằng [toastToneOf].
  final ToastTone? tone;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolved = tone ?? toastToneOf(message);
    final (IconData icon, Color accent) = switch (resolved) {
      ToastTone.success => (
        LucideIcons.circleCheck,
        isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
      ),
      ToastTone.error => (
        LucideIcons.circleX,
        isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
      ),
      ToastTone.warning => (
        LucideIcons.triangleAlert,
        isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
      ),
      ToastTone.info => (
        LucideIcons.info,
        isDark ? const Color(0xFF93C5FD) : AISLShadcnTheme.navyAccent,
      ),
    };

    return Padding(
      padding: margin,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Semantics(
          liveRegion: true,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1F24) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF2E333A)
                    : const Color(0xFFE4E7EC),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Icon(icon, size: 18, color: accent),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      message,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFFF4F5F7)
                            : const Color(0xFF111827),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
