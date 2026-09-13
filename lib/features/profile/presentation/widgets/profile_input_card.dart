import 'package:smart_laundry_locker/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// card email / phone / password
class ProfileInputCard extends StatelessWidget {
  ProfileInputCard({
    super.key,
    required this.label,
    required this.value,
    this.hintText,
    this.leadingIcon,
    this.trailingIcon,
    this.trailing,
    this.helperText,
    this.isPassword = false,
    this.obscured = false,
  });

  final String label;
  final String value;
  final String? hintText;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final Widget? trailing;
  final String? helperText;
  final bool isPassword;
  final bool obscured;

  @override
  Widget build(BuildContext context) {
    final hasValue = value.isNotEmpty;
    final effectiveObscured = isPassword || obscured;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              if (leadingIcon != null) ...[
                Icon(leadingIcon, size: 20, color: AppColors.onSurfaceVariant),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  hasValue
                      ? (effectiveObscured ? '•' * 10 : value)
                      : (hintText ?? ''),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: hasValue ? FontWeight.w500 : FontWeight.w400,
                    color: hasValue
                        ? AppColors.onBackground
                        : AppColors.grey500,
                  ),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 12),
                trailing!,
              ] else if (trailingIcon != null) ...[
                const SizedBox(width: 12),
                Icon(trailingIcon, size: 20, color: AppColors.onSurfaceVariant),
              ],
            ],
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 4),
          Text(
            helperText!,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
