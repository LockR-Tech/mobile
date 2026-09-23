import 'dart:async';

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

/// Chọn phương thức (ví, VNPay, MoMo, SePay — app khách không tự xác nhận tiền mặt),
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

  final returnUrl = method == 'SEPAY'
      ? '${EnvConfig.apiBaseUrl}/payments/sepay/callback'
      : '${EnvConfig.apiBaseUrl}/payments/vnpay/callback';

  final res = await service.checkout(
    orderId,
    method,
    returnUrl: returnUrl,
  );
  // Backend PaymentResponse dùng field "paymentUrl" (không phải "url")
  final url = (res['paymentUrl'] ?? res['url'] ?? res['deeplink']) as String?;
  final qrCodeUrl = (res['qrCodeUrl'] ?? res['qr']) as String?;

  if (method == 'SEPAY') {
    // SePay: hiển thị mã VietQR trực tiếp trong bottom sheet của app
    if (!context.mounted) return OrderPaymentOutcome.cancelled;
    final effectiveQrUrl = (qrCodeUrl != null && qrCodeUrl.isNotEmpty)
        ? qrCodeUrl
        : 'https://img.vietqr.io/image/970422-0000234917957-compact2.jpg?amount=${total.toInt()}&addInfo=PAY-$orderId&accountName=TRUONG%20NGUYEN%20THAI%20BINH';

    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) => _SepayVietQrSheet(
        service: service,
        orderId: orderId,
        amount: total,
        qrImageUrl: effectiveQrUrl,
      ),
    );
  } else if ((method == 'VNPAY' || method == 'MOMO') && url != null && url.isNotEmpty) {
    if (!context.mounted) return OrderPaymentOutcome.cancelled;
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => TopUpWebViewPage(paymentUrl: url)),
    );
  }

  // Tăng timeout lên 60s để webhook có thời gian xử lý
  final paid = await service.awaitOrderPaid(orderId,
      timeout: const Duration(seconds: 60));
  return paid ? OrderPaymentOutcome.paid : OrderPaymentOutcome.pending;
}

// ─────────────────────────────────────────────────────────────────────────────
// SePay VietQR inline bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _SepayVietQrSheet extends StatefulWidget {
  const _SepayVietQrSheet({
    required this.service,
    required this.orderId,
    required this.amount,
    required this.qrImageUrl,
  });

  final LockerOpsService service;
  final int orderId;
  final double amount;
  final String qrImageUrl;

  @override
  State<_SepayVietQrSheet> createState() => _SepayVietQrSheetState();
}

class _SepayVietQrSheetState extends State<_SepayVietQrSheet> {
  bool _checking = false;
  bool _paid = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Poll mỗi 3s kiểm tra trạng thái đơn
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _checkPaid());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkPaid() async {
    if (_paid || _checking) return;
    setState(() => _checking = true);
    try {
      final status = await widget.service.orderStatus(widget.orderId);
      if (status == true && mounted) {
        _timer?.cancel();
        setState(() {
          _paid = true;
          _checking = false;
        });
        // Tự đóng sheet sau 1.5s
        await Future<void>.delayed(const Duration(milliseconds: 1500));
        if (mounted) Navigator.of(context).pop();
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 4,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quét mã VietQR để thanh toán',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            color: opsDark)),
                    SizedBox(height: 2),
                    Text('Mở app ngân hàng bất kỳ, quét mã bên dưới',
                        style: TextStyle(fontSize: 13, color: opsMutedText)),
                  ],
                ),
              ),
              if (_checking)
                const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ),
          const SizedBox(height: 16),

          if (_paid)
            // Success state
            Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDCFCE7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Color(0xFF16A34A), size: 40),
                ),
                const SizedBox(height: 12),
                const Text('Thanh toán thành công!',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: Color(0xFF16A34A))),
              ],
            )
          else
            // QR image from VietQR.io
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                widget.qrImageUrl,
                width: 260,
                height: 300,
                fit: BoxFit.contain,
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return const SizedBox(
                    width: 260,
                    height: 300,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (_, __, ___) => const SizedBox(
                  width: 260,
                  height: 260,
                  child: Center(
                    child: Text('Không thể tải mã QR',
                        style: TextStyle(color: opsMutedText)),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 12),
          // Amount chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFBAE6FD)),
            ),
            child: Text(
              'Số tiền: ${fmtPrice(widget.amount)}',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: Color(0xFF0369A1),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tự động xác nhận sau khi chuyển khoản thành công',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: opsMutedText),
          ),
          const SizedBox(height: 16),
          // SePay branding
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Cung cấp bởi ',
                  style: TextStyle(fontSize: 12, color: opsMutedText)),
              Image.network(
                'https://sepay.vn/assets/images/sepay-logo.png',
                height: 20,
                errorBuilder: (_, __, ___) => const Text('SePay',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: opsPrimary)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PaymentMethodPicker
// ─────────────────────────────────────────────────────────────────────────────

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

  static const _selfServiceMethods = ['WALLET', 'VNPAY', 'MOMO', 'SEPAY'];

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
          if (enabled('SEPAY'))
            _MethodTile(
              icon: LucideIcons.qrCode,
              title: 'SePay (VietQR)',
              subtitle: 'Quét mã VietQR chuyển khoản nhanh 24/7',
              onTap: () => Navigator.pop(context, 'SEPAY'),
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
