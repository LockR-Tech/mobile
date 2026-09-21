import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:smart_laundry_locker/core/config/env_config.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';
import 'package:smart_laundry_locker/features/transactions/presentation/pages/top_up_page.dart'
    show TopUpWebViewPage;

enum OrderPaymentOutcome {
  /// Đơn đã được ghi nhận PAID.
  paid,

  /// Đã thanh toán nhưng server chưa ghi nhận xong trong thời gian chờ.
  pending,

  /// Khách đóng bảng chọn phương thức.
  cancelled,
}

/// Chọn phương thức (ví, VNPay, MoMo — app khách không tự xác nhận tiền mặt),
/// thanh toán, rồi chờ tới khi đơn thật sự PAID mới cho sang bước bỏ hàng.
/// Lỗi gọi API được ném ra cho nơi gọi tự báo.
Future<OrderPaymentOutcome> payOrderAndAwaitPaid(
  BuildContext context, {
  required LockerOpsService service,
  required int orderId,
  required double total,
  required List<String> enabledMethods,
}) async {
  num balance = 0;
  try {
    balance = await service.walletBalance();
  } catch (_) {}
  if (!context.mounted) return OrderPaymentOutcome.cancelled;

  final method = await showModalBottomSheet<String>(
    context: context,
    useRootNavigator: true,
    backgroundColor: Colors.white,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (_) => PaymentMethodPicker(
      total: total,
      walletBalance: balance,
      enabledMethods: enabledMethods,
    ),
  );
  if (method == null || !context.mounted) return OrderPaymentOutcome.cancelled;

  final res = await service.checkout(
    orderId,
    method,
    returnUrl: '${EnvConfig.apiBaseUrl}/payments/vnpay/callback',
  );
  final url = res['url'] as String?;
  if ((method == 'VNPAY' || method == 'MOMO') && url != null && url.isNotEmpty) {
    if (!context.mounted) return OrderPaymentOutcome.cancelled;
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => TopUpWebViewPage(paymentUrl: url)),
    );
  }
  final paid = await service.awaitOrderPaid(orderId);
  return paid ? OrderPaymentOutcome.paid : OrderPaymentOutcome.pending;
}

/// Bảng chọn phương thức thanh toán cho đơn tủ.
class PaymentMethodPicker extends StatelessWidget {
  const PaymentMethodPicker({
    super.key,
    required this.total,
    required this.walletBalance,
    required this.enabledMethods,
  });

  final double total;
  final num walletBalance;

  /// Phương thức admin đang bật (`app.payment.enabled-methods`), viết hoa.
  /// Tiền mặt luôn bị bỏ qua: không có ai thu tiền ở tủ để xác nhận.
  final List<String> enabledMethods;

  static const _selfServiceMethods = ['WALLET', 'VNPAY', 'MOMO'];

  @override
  Widget build(BuildContext context) {
    final insufficient = walletBalance < total;
    bool enabled(String method) =>
        _selfServiceMethods.contains(method) && enabledMethods.contains(method);
    final hasAnyMethod = _selfServiceMethods.any(enabled);
    // Bottom sheet thường chỉ cao tối đa ~9/16 màn hình — cho cuộn để máy màn
    // thấp vẫn thấy đủ các phương thức.
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Chọn phương thức thanh toán',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: opsDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Số tiền: ${fmtPrice(total)}',
            style: const TextStyle(fontSize: 14, color: opsMutedText),
          ),
          const SizedBox(height: 16),
          if (!hasAnyMethod)
            const OpsBanner(
              tone: OpsBannerTone.warning,
              icon: LucideIcons.badgeAlert,
              text:
                  'Hiện chưa có phương thức thanh toán nào khả dụng. '
                  'Vui lòng thử lại sau.',
            ),
          if (enabled('WALLET'))
            _MethodTile(
              icon: LucideIcons.wallet,
              title: 'Ví của tôi',
              subtitle: insufficient
                  ? 'Số dư ${fmtPrice(walletBalance)} — không đủ, hãy nạp thêm'
                  : 'Số dư ${fmtPrice(walletBalance)} · thanh toán tức thì',
              enabled: !insufficient,
              onTap: () => Navigator.pop(context, 'WALLET'),
            ),
          if (enabled('VNPAY'))
            _MethodTile(
              icon: LucideIcons.creditCard,
              title: 'VNPay',
              subtitle: 'Thẻ ATM / QR ngân hàng',
              onTap: () => Navigator.pop(context, 'VNPAY'),
            ),
          if (enabled('MOMO'))
            _MethodTile(
              icon: LucideIcons.smartphone,
              title: 'MoMo',
              subtitle: 'Ví MoMo',
              onTap: () => Navigator.pop(context, 'MOMO'),
            ),
        ],
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.enabled = true,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        // Nền/viền đặt trên Material (không phải DecoratedBox) để ListTile vẽ
        // được hiệu ứng chạm — tránh assertion "ink splashes may be invisible".
        child: Material(
          color: opsSurface,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: opsBorder),
          ),
          child: ListTile(
            enabled: enabled,
            onTap: enabled ? onTap : null,
            leading: Icon(icon, color: opsPrimary),
            title: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: opsDark,
              ),
            ),
            subtitle: Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: opsMutedText),
            ),
            trailing: const Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: opsMutedText,
            ),
          ),
        ),
      ),
    );
  }
}
