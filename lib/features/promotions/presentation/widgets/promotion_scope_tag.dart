import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Nhãn phạm vi áp dụng của một mã giảm giá: `Toàn hệ thống` hoặc
/// `Áp dụng tại: <tên tủ>`. Một dòng, quá dài thì cắt "…".
class PromotionScopeTag extends StatelessWidget {
  const PromotionScopeTag({
    super.key,
    required this.label,
    required this.lockerScoped,
    this.fontSize = 11,
    this.muted = false,
  });

  final String label;

  /// Mã chỉ dùng được ở một tủ (tô màu nổi hơn mã toàn hệ thống).
  final bool lockerScoped;
  final double fontSize;

  /// Voucher đã dùng/hết hạn — hiện xám.
  final bool muted;

  static const scopedColor = Color(0xFFB45309);
  static const globalColor = Color(0xFF0369A1);

  @override
  Widget build(BuildContext context) {
    final color = muted
        ? const Color(0xFF94A3B8)
        : (lockerScoped ? scopedColor : globalColor);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            lockerScoped ? LucideIcons.mapPin : LucideIcons.globe,
            size: fontSize,
            color: color,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: fontSize,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
