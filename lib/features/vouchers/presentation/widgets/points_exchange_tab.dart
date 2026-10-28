import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:smart_laundry_locker/core/config/business_config_service.dart';
import 'package:smart_laundry_locker/features/promotions/presentation/widgets/promotion_scope_tag.dart';
import 'package:smart_laundry_locker/shared/shared.dart';
import 'package:smart_laundry_locker/shared/widgets/user_ui_kit.dart';

import '../../data/models/exchangeable_voucher_model.dart';
import '../providers/voucher_provider.dart';

final _number = NumberFormat.decimalPattern('vi_VN');

/// `200.000 điểm`.
String fmtPointsText(int points) => '${_number.format(points)} điểm';

/// `Giảm 10.000đ` / `Giảm 15% (tối đa 30.000đ)`.
String exchangeVoucherRewardText(ExchangeableVoucherModel voucher) {
  if (voucher.isPercentage) {
    final max = voucher.maxDiscountAmount;
    return 'Giảm ${voucher.discountValue.round()}%'
        '${max != null && max > 0 ? ' (tối đa ${_number.format(max)}đ)' : ''}';
  }
  return 'Giảm ${_number.format(voucher.discountValue)}đ';
}

/// Tab "Đổi điểm" ở "Ưu đãi của tôi": số điểm hiện có và các voucher đổi được.
/// Đổi xong voucher nằm ở tab "Khả dụng" và dùng như mã giảm giá khi đặt đơn.
class PointsExchangeTab extends StatelessWidget {
  const PointsExchangeTab({super.key, this.onExchanged});

  /// Gọi sau khi đổi thành công (trang cha chuyển sang tab Khả dụng).
  final VoidCallback? onExchanged;

  @override
  Widget build(BuildContext context) {
    return Consumer<VoucherProvider>(
      builder: (context, provider, _) {
        if (provider.exchangeLoading && provider.exchangeable.isEmpty) {
          return const Center(
            child: AppLoadingIndicator(message: 'Đang tải voucher đổi điểm...'),
          );
        }
        final balance = provider.pointsBalance;
        return RefreshIndicator(
          onRefresh: provider.loadExchange,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _BalanceCard(balance: balance),
              const SizedBox(height: 16),
              if (provider.exchangeError != null)
                _Message(
                  icon: LucideIcons.cloudOff,
                  text: provider.exchangeError!,
                  onRetry: provider.loadExchange,
                )
              else if (provider.exchangeable.isEmpty)
                const _Message(
                  icon: LucideIcons.ticket,
                  text: 'Hiện chưa có voucher nào để đổi điểm',
                )
              else
                for (final voucher in provider.exchangeable) ...[
                  _ExchangeCard(
                    voucher: voucher,
                    balance: balance,
                    busy: provider.exchangingId == voucher.id,
                    onExchange: () => _confirmAndExchange(context, voucher),
                  ),
                  const SizedBox(height: 12),
                ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmAndExchange(
    BuildContext context,
    ExchangeableVoucherModel voucher,
  ) async {
    final provider = context.read<VoucherProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đổi voucher?'),
        content: Text(
          'Dùng ${fmtPointsText(voucher.pointsCost)} đổi voucher '
          '"${exchangeVoucherRewardText(voucher)}". Voucher sẽ nằm trong mục '
          'Khả dụng, dùng bằng mã ${voucher.code} khi đặt đơn.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Đổi'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final error = await provider.exchange(voucher);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          error ?? 'Đã đổi voucher ${voucher.code} — xem ở mục Khả dụng',
        ),
      ),
    );
    if (error == null) onExchanged?.call();
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance});

  final int? balance;

  @override
  Widget build(BuildContext context) {
    final config = BusinessConfigService.instance.current;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: AislBrand.brandGradient),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.sparkles, color: Colors.white, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Điểm của bạn',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  balance == null ? '—' : fmtPointsText(balance!),
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '1 điểm = ${_number.format(config.redeemVndPerPoint)}đ · '
                  'đổi lấy voucher giảm giá cho đơn',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExchangeCard extends StatelessWidget {
  const _ExchangeCard({
    required this.voucher,
    required this.balance,
    required this.busy,
    required this.onExchange,
  });

  final ExchangeableVoucherModel voucher;
  final int? balance;
  final bool busy;
  final VoidCallback onExchange;

  @override
  Widget build(BuildContext context) {
    final missing = balance == null ? 0 : voucher.pointsCost - balance!;
    final minOrder = voucher.minOrderAmount ?? 0;
    final Widget action;
    if (voucher.held) {
      action = const _StatusChip(text: 'Đã có', color: Color(0xFF15803D));
    } else if (missing > 0) {
      action = _StatusChip(
        text: 'Thiếu ${_number.format(missing)}',
        color: Colors.grey.shade600,
      );
    } else {
      action = FilledButton(
        onPressed: busy ? null : onExchange,
        style: FilledButton.styleFrom(
          backgroundColor: AislBrand.blue,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          minimumSize: const Size(0, 36),
        ),
        child: busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text('Đổi'),
      );
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AislBrand.navy.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              LucideIcons.ticketPercent,
              color: AislBrand.navy,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exchangeVoucherRewardText(voucher),
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  fmtPointsText(voucher.pointsCost),
                  style: const TextStyle(
                    color: AislBrand.blue,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                PromotionScopeTag(
                  label: voucher.scopeLabel,
                  lockerScoped: voucher.lockerId != null,
                  fontSize: 10.5,
                ),
                if (minOrder > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Đơn từ ${_number.format(minOrder)}đ',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          action,
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.onRetry});

  final IconData icon;
  final String text;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(icon, size: 52, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          if (onRetry != null)
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: const Text('Thử lại'),
            ),
        ],
      ),
    );
  }
}
