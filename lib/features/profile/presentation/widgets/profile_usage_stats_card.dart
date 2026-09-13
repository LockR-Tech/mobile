import 'package:smart_laundry_locker/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// card tổng thời gian sử dụng
class ProfileUsageStatsCard extends StatelessWidget {
  const ProfileUsageStatsCard({
    super.key,
    required this.totalUsageTime,
    this.obscured = true,
    this.onToggle,
  });

  final double totalUsageTime;
  final bool obscured;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final displayText = obscured
        ? '••••••'
        : '${totalUsageTime.toStringAsFixed(1)} giờ';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.lock_clock_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tổng thời gian sử dụng',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  displayText,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onBackground,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: onToggle,
            icon: Icon(
              obscured ? LucideIcons.eyeOff : LucideIcons.eye,
              size: 20,
              color: obscured ? AppColors.onSurfaceVariant : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
