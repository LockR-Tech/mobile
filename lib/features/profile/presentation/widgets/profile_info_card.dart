import 'package:smart_laundry_locker/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// card trạng thái và xác thực tài khoản
class ProfileInfoCard extends StatelessWidget {
  const ProfileInfoCard({
    super.key,
    required this.status,
    required this.isVerified,
  });

  final String status; // ACTIVE, INACTIVE, BLOCKED
  final bool isVerified;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toUpperCase();

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (normalized) {
      case 'ACTIVE':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_rounded;
        statusText = 'ACTIVE';
        break;
      case 'INACTIVE':
        statusColor = const Color(0xFF0A2342);
        statusIcon = Icons.schedule_rounded;
        statusText = 'INACTIVE';
        break;
      case 'BLOCKED':
        statusColor = Colors.red;
        statusIcon = Icons.block_rounded;
        statusText = 'BLOCKED';
        break;
      default:
        statusColor = AppColors.grey500;
        statusIcon = Icons.info_rounded;
        statusText = normalized;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
      child: Column(
        children: [
          _buildRow(
            label: 'Trạng thái',
            value: statusText,
            color: statusColor,
            icon: statusIcon,
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          _buildRow(
            label: 'Xác thực',
            value: isVerified ? 'Đã xác thực' : 'Chưa xác thực',
            color: isVerified ? AppColors.info : AppColors.grey500,
            icon: isVerified ? Icons.verified_rounded : Icons.verified_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildRow({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onBackground,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
