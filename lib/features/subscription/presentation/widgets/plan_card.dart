import 'package:smart_laundry_locker/core/constants/app_colors.dart';
import 'package:smart_laundry_locker/features/subscription/presentation/models/plan_ui_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PlanCard extends StatelessWidget {
  const PlanCard({super.key, required this.plan, required this.onTap});

  final PlanUIModel plan;
  final VoidCallback onTap;

  String _formatVnd(int amount) {
    return NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    ).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = plan.name.toLowerCase().contains('premium');
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isPremium
                  ? AppColors.success.withValues(alpha: 0.45)
                  : AppColors.grey200,
              width: isPremium ? 1.6 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      plan.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  if (isPremium)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Đề xuất',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${_formatVnd(plan.priceVnd)}/tháng',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.success,
                ),
              ),
              if ((plan.description ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  plan.description!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.grey700,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _Benefit(text: 'Tối đa ${plan.maxLockers} ô tủ'),
              _Benefit(text: 'Giảm ${plan.discountLockerRental}% phí thuê tủ'),
              _Benefit(text: '${plan.fixedLocker} ô cố định'),
              if (plan.pricings.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text(
                  'Bảng giá chi tiết',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                ...plan.pricings.map(
                  (p) => Text(
                    '- ${_formatVnd(p.feePerBlockVnd)}/${p.blockDuration} ${p.blockUnit.toLowerCase()}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.grey700,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              const Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Nhấn để xem chi tiết',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 18, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
