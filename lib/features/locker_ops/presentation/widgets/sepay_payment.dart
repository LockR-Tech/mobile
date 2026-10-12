import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/core/constants/payment_methods.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';
import 'package:smart_laundry_locker/features/payment/domain/sepay_transfer.dart';
import 'package:smart_laundry_locker/features/payment/presentation/widgets/bank_app_picker_sheet.dart';
import 'package:smart_laundry_locker/shared/shared.dart';

/// Một lần thanh toán SePay (VietQR) cho một đơn — dùng chung cho thuê tủ, gửi
/// hàng, gia hạn, phí quá hạn, đơn drone.
///
/// - [start] tạo checkout `POST /api/payments/checkout {orderId, method: SEPAY}`
///   ĐÚNG MỘT LẦN (gọi lại / dựng lại widget không tạo giao dịch mới); lỗi thì
///   chỉ [retry] mới tạo lại.
/// - Hỏi trạng thái đơn mỗi [pollInterval] (~3 s) và mỗi khi app quay lại
///   foreground (khách vừa chuyển khoản trong app ngân hàng) cho tới khi PAID.
class SepayPaymentController extends ChangeNotifier
    with WidgetsBindingObserver {
  SepayPaymentController({
    required this.service,
    required this.orderId,
    required this.amount,
    this.description,
    this.pollInterval = const Duration(seconds: 3),
  });

  final LockerOpsService service;
  final int orderId;

  /// Số tiền dự kiến — chỉ dùng khi server không trả số tiền của giao dịch.
  final num amount;

  /// Lý do trả tiền ("Phí quá hạn"…), chuyển nguyên cho checkout.
  final String? description;
  final Duration pollInterval;

  SepayTransfer? _transfer;
  String? _error;
  bool _creating = false;
  bool _gatewayFailed = false;
  bool _paid = false;
  bool _checking = false;
  bool _started = false;
  bool _disposed = false;
  int _checkoutCalls = 0;
  Timer? _poll;
  Future<bool>? _statusInFlight;

  /// Thông tin chuyển khoản của giao dịch (null khi đang tạo / lỗi).
  SepayTransfer? get transfer => _transfer;
  String? get error => _error;
  bool get creating => _creating;
  bool get paid => _paid;

  /// Đang kiểm tra theo yêu cầu của khách ("Kiểm tra ngay").
  bool get checking => _checking;

  /// Cổng báo giao dịch thất bại / bị huỷ ngay khi tạo.
  bool get gatewayFailed => _gatewayFailed;

  /// Số lần đã gọi checkout (để test "chỉ tạo một lần").
  @visibleForTesting
  int get checkoutCalls => _checkoutCalls;

  Future<void> start() async {
    if (_started || _disposed) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _poll = Timer.periodic(pollInterval, (_) => _checkPaid());
    await _createCheckout();
  }

  /// Tạo lại checkout sau khi lần trước lỗi (không tạo khi đã có mã).
  Future<void> retry() async {
    if (!_started || _disposed || _creating || _transfer != null || _paid) {
      return;
    }
    await _createCheckout();
  }

  Future<void> _createCheckout() async {
    _creating = true;
    _error = null;
    _gatewayFailed = false;
    _notify();
    try {
      _checkoutCalls++;
      final res = await service.checkout(
        orderId,
        PaymentMethods.orderPayment,
        description: description,
      );
      if (_disposed) return;
      final status = '${res['status'] ?? ''}'.toUpperCase();
      if (status == 'FAILED' || status == 'CANCELED' || status == 'CANCELLED') {
        _gatewayFailed = true;
        _error = 'Không tạo được giao dịch thanh toán. Vui lòng thử lại.';
        return;
      }
      if (status == 'COMPLETED' || status == 'PAID' || status == 'SUCCESS') {
        // Đơn 0đ / đã trả trước đó: hỏi lại trạng thái đơn cho chắc.
        unawaited(_checkPaid());
      }
      final transfer = SepayTransfer.fromCheckout(res, fallbackAmount: amount);
      if (!transfer.isUsable) {
        _error =
            'Máy chủ chưa trả mã VietQR cho giao dịch này. Vui lòng thử lại sau.';
        return;
      }
      _transfer = transfer;
    } catch (e) {
      if (_disposed) return;
      _error = LockerOpsService.errorMessage(e);
    } finally {
      _creating = false;
      _notify();
    }
  }

  /// Khách bấm "Tôi đã chuyển khoản — Kiểm tra ngay". Trả `true` khi đơn PAID.
  Future<bool> checkNow() async {
    if (_paid) return true;
    _checking = true;
    _notify();
    final paid = await _checkPaid();
    _checking = false;
    _notify();
    return paid;
  }

  Future<bool> _checkPaid() {
    if (_paid) return Future.value(true);
    if (_disposed) return Future.value(false);
    return _statusInFlight ??= _fetchPaid().whenComplete(
      () => _statusInFlight = null,
    );
  }

  Future<bool> _fetchPaid() async {
    try {
      final paid = await service.orderStatus(orderId);
      if (paid && !_disposed && !_paid) {
        _paid = true;
        _poll?.cancel();
        _notify();
      }
      return paid;
    } catch (_) {
      // Lỗi mạng tạm thời — lần hỏi sau thử lại.
      return false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkPaid();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _poll?.cancel();
    if (_started) WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

/// Khung mã VietQR: đang tạo / lỗi (có "Thử lại") / mã QR + số tiền + nội dung.
class SepayQrSection extends StatelessWidget {
  const SepayQrSection({super.key, required this.controller});

  final SepayPaymentController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final transfer = controller.transfer;
        if (controller.paid) {
          return AppPaymentStatusView(
            type: PaymentStatusType.success,
            title: 'Thanh toán thành công!',
            amountText: fmtPrice(transfer?.amount ?? controller.amount),
            message: 'Hệ thống đã nhận được tiền, đơn hàng đang được cập nhật...',
            iconSize: 100,
          );
        }
        if (transfer != null) return InlineVietQrCard(transfer: transfer);
        if (controller.error != null) {
          return _SepayErrorBox(
            message: controller.error!,
            retrying: controller.creating,
            onRetry: controller.retry,
          );
        }
        return const _SepayCreatingBox();
      },
    );
  }
}

/// Mã VietQR SePay ngay trên trang (bố cục như màn thuê tủ cũ): tiêu đề, ảnh QR
/// của server, "Số tiền cần chuyển", "Nội dung chuyển khoản" + "Sao chép", dòng
/// chờ xác nhận. Mọi số liệu lấy từ giao dịch thật — không có tài khoản viết sẵn.
class InlineVietQrCard extends StatelessWidget {
  const InlineVietQrCard({super.key, required this.transfer});

  final SepayTransfer transfer;

  @override
  Widget build(BuildContext context) {
    final qr = transfer.qrImageUrl;
    final content = transfer.transferContent;
    final amount = transfer.amount;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: const Row(
              children: [
                Icon(LucideIcons.qrCode, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Quét mã VietQR để thanh toán',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (qr != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  qr,
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : const SizedBox(
                          height: 200,
                          child: Center(child: AppLoadingIndicator(size: 64)),
                        ),
                  errorBuilder: (_, __, ___) => const SizedBox(
                    height: 160,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.imageOff,
                            size: 36,
                            color: opsMutedText,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Không tải được mã QR',
                            style: TextStyle(color: opsMutedText),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
            const _NoQrHint(),
          if (transfer.accountNo != null)
            _InfoLine(
              label: 'Số tài khoản:',
              value: [
                transfer.accountNo!,
                if (transfer.accountName != null) transfer.accountName!,
              ].join(' · '),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Flexible(
                  child: Text(
                    'Số tiền cần chuyển:',
                    style: TextStyle(color: opsMutedText, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  amount == null ? '—' : fmtPrice(amount),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: opsDark,
                  ),
                ),
              ],
            ),
          ),
          if (content != null) ...[
            const Divider(height: 1, indent: 20, endIndent: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nội dung chuyển khoản:',
                          style: TextStyle(color: opsMutedText, fontSize: 12),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          content,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: opsDark,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: content));
                      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                        const SnackBar(
                          content: Text('Đã sao chép nội dung chuyển khoản'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(LucideIcons.copy, size: 14),
                    label: const Text('Sao chép'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF3B82F6),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 44,
                  height: 44,
                  child: AppLoadingIndicator(size: 44),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đang chờ xác nhận thanh toán…',
                        style: TextStyle(
                          color: opsDark,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Tự động cập nhật ngay sau khi nhận được tiền.',
                        style: TextStyle(
                          color: opsMutedText,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Thanh toán bằng app ngân hàng" + "Tôi đã chuyển khoản — Kiểm tra ngay".
class SepayPaymentActions extends StatefulWidget {
  const SepayPaymentActions({
    super.key,
    required this.controller,
    this.openBankApp = showBankAppPicker,
  });

  final SepayPaymentController controller;

  /// Mở bảng chọn app ngân hàng (test thay được).
  final Future<bool> Function(
    BuildContext context, {
    required SepayTransfer transfer,
  })
  openBankApp;

  @override
  State<SepayPaymentActions> createState() => _SepayPaymentActionsState();
}

class _SepayPaymentActionsState extends State<SepayPaymentActions> {
  /// Kết quả lần "Kiểm tra ngay" gần nhất khi chưa thấy tiền.
  String? _hint;

  Future<void> _checkNow() async {
    setState(() => _hint = null);
    final paid = await widget.controller.checkNow();
    if (!mounted || paid) return;
    setState(
      () => _hint =
          'Chưa ghi nhận thanh toán. Nếu bạn vừa chuyển khoản, vui lòng đợi giây lát rồi kiểm tra lại.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;
        final transfer = controller.transfer;
        if (controller.paid || transfer == null) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Web không mở được app ngân hàng trên điện thoại ⇒ chỉ quét mã.
            if (!kIsWeb && transfer.canOpenBankApp) ...[
              OutlinedButton.icon(
                onPressed: () => widget.openBankApp(context, transfer: transfer),
                icon: const Icon(LucideIcons.landmark, size: 18),
                label: const Text('Thanh toán bằng app ngân hàng'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  foregroundColor: const Color(0xFF1E40AF),
                  side: const BorderSide(color: Color(0xFF3B82F6), width: 1.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            OpsPrimaryButton(
              label: 'Tôi đã chuyển khoản — Kiểm tra ngay',
              icon: LucideIcons.circleCheck,
              loading: controller.checking,
              onPressed: _checkNow,
            ),
            if (_hint != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _hint!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: opsMutedText),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: opsMutedText, fontSize: 13)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: opsDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoQrHint extends StatelessWidget {
  const _NoQrHint();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Text(
        'Chuyển khoản đúng số tài khoản, số tiền và nội dung bên dưới.',
        style: TextStyle(color: opsMutedText, fontSize: 13),
      ),
    );
  }
}

class _SepayCreatingBox extends StatelessWidget {
  const _SepayCreatingBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          SizedBox(height: 12),
          Text(
            'Đang tạo mã thanh toán…',
            style: TextStyle(color: opsMutedText, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _SepayErrorBox extends StatelessWidget {
  const _SepayErrorBox({
    required this.message,
    required this.retrying,
    required this.onRetry,
  });

  final String message;
  final bool retrying;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OpsBanner(
          tone: OpsBannerTone.warning,
          icon: LucideIcons.badgeAlert,
          text: message,
        ),
        const SizedBox(height: 10),
        OpsPrimaryButton(
          label: 'Thử lại',
          icon: LucideIcons.refreshCw,
          loading: retrying,
          onPressed: onRetry,
        ),
      ],
    );
  }
}
