import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:smart_laundry_locker/core/theme/shadcn_theme.dart';

/// Sheet nhắc người nhận chuẩn bị ra nhận khi drone sắp đến (mốc `approaching`).
/// Mirror bố cục `finding_courier_sheet.dart` nhưng tối giản cho Phase 1.
class DroneApproachingSheet extends StatelessWidget {
  final String? etaText;
  final String? droneCode;

  const DroneApproachingSheet({super.key, this.etaText, this.droneCode});

  /// Hiện sheet dạng bottom-sheet. Trả về khi người dùng đóng.
  static Future<void> show(
    BuildContext context, {
    String? etaText,
    String? droneCode,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) =>
          DroneApproachingSheet(etaText: etaText, droneCode: droneCode),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AISLShadcnTheme.navyAccent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.navigation,
              color: AISLShadcnTheme.navyAccent,
              size: 34,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Drone sắp đến nơi',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AISLShadcnTheme.navyPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vui lòng chuẩn bị ra nhận hàng.'
            '${droneCode != null && droneCode!.isNotEmpty ? '\nMã drone: $droneCode' : ''}',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 15, height: 1.4),
          ),
          if (etaText != null && etaText!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AISLShadcnTheme.navySurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    LucideIcons.clock,
                    size: 16,
                    color: AISLShadcnTheme.navySecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Dự kiến: $etaText',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AISLShadcnTheme.navySecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ShadButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Đã hiểu'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
