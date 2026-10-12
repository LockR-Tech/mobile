import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';
import 'package:smart_laundry_locker/shared/widgets/controller_disposer.dart';

String refundStatusLabel(String? status) =>
    switch ((status ?? '').toUpperCase()) {
      'PENDING' => 'Chờ duyệt',
      'APPROVED' || 'PROCESSING' => 'Đang chuyển khoản',
      'COMPLETED' || 'SUCCESS' => 'Đã hoàn tiền',
      'REJECTED' => 'Bị từ chối',
      'FAILED' => 'Hoàn tiền lỗi',
      final other when other.isNotEmpty => other,
      _ => 'Không rõ',
    };

Color refundStatusColor(String? status) =>
    switch ((status ?? '').toUpperCase()) {
      'COMPLETED' || 'SUCCESS' => const Color(0xFF15803D),
      'REJECTED' || 'FAILED' => const Color(0xFFDC2626),
      _ => const Color(0xFFD97706),
    };

/// `••••1234` — không hiện đủ số tài khoản trên màn hình.
String maskAccountNumber(String? number) {
  final digits = (number ?? '').trim();
  if (digits.isEmpty) return '';
  if (digits.length <= 4) return digits;
  return '••••${digits.substring(digits.length - 4)}';
}

/// Có yêu cầu hoàn tiền đang chờ hoặc đã hoàn ⇒ không gửi thêm (server cũng chặn
/// bằng `REFUND_ALREADY_REQUESTED`).
bool hasActiveRefund(List<Map<String, dynamic>> refunds) => refunds.any((r) {
  final s = '${r['status'] ?? ''}'.toUpperCase();
  return s == 'PENDING' ||
      s == 'APPROVED' ||
      s == 'PROCESSING' ||
      s == 'COMPLETED';
});

/// Trạng thái hoàn tiền của đơn (`GET /api/payments/order/{id}/refunds`) và nút
/// gửi yêu cầu (`POST /api/payments/refund-request`) cho đơn đã thanh toán mà đã
/// huỷ / hoàn tất. Tiền hoàn về tài khoản ngân hàng khách đã lưu.
class OrderRefundSection extends StatefulWidget {
  const OrderRefundSection({
    super.key,
    required this.orderId,
    required this.status,
    required this.paymentStatus,
    this.service,
    this.onChanged,
  });

  final int orderId;
  final String status;
  final String paymentStatus;
  final LockerOpsService? service;

  /// Gọi sau khi gửi yêu cầu thành công (danh sách đơn tải lại `paymentStatus`).
  final Future<void> Function()? onChanged;

  static bool appliesTo({required String paymentStatus}) {
    final p = paymentStatus.toUpperCase();
    return p == 'PAID' || p == 'REFUND_PENDING' || p == 'REFUNDED';
  }

  @override
  State<OrderRefundSection> createState() => _OrderRefundSectionState();
}

class _OrderRefundSectionState extends State<OrderRefundSection> {
  late final LockerOpsService _service = widget.service ?? LockerOpsService();
  List<Map<String, dynamic>> _refunds = const [];
  bool _loading = true;
  bool _unavailable = false;
  String? _error;

  bool get _orderClosed {
    final s = widget.status.toUpperCase();
    return s == 'CANCELED' || s == 'COMPLETED';
  }

  bool get _canRequest =>
      !_unavailable &&
      _orderClosed &&
      widget.paymentStatus.toUpperCase() == 'PAID' &&
      !hasActiveRefund(_refunds);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final refunds = await _service.orderRefunds(widget.orderId);
      if (!mounted) return;
      setState(() {
        _refunds = refunds;
        _unavailable = false;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _unavailable = LockerOpsService.isEndpointUnavailable(e);
        _error = _unavailable ? null : LockerOpsService.errorMessage(e);
        _loading = false;
      });
    }
  }

  Future<void> _request() async {
    final reasonCtrl = TextEditingController();
    var sending = false;
    String? error;
    var needsBankAccount = false;
    final router = GoRouter.maybeOf(context);
    final done = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ControllerDisposer(
        controllers: [reasonCtrl],
        child: StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: const Text('Yêu cầu hoàn tiền'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: reasonCtrl,
                    enabled: !sending,
                    maxLines: 3,
                    maxLength: 500,
                    decoration: const InputDecoration(
                      hintText: 'Lý do hoàn tiền (vd. đơn huỷ do ô hỏng)',
                    ),
                  ),
                  const Text(
                    'Tiền được hoàn về tài khoản ngân hàng bạn đã lưu trong '
                    'Hồ sơ → Tài khoản nhận hoàn tiền, sau khi quản trị viên duyệt.',
                    style: TextStyle(
                      fontSize: 12,
                      color: opsMutedText,
                      height: 1.4,
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      error!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ],
                  if (needsBankAccount && router != null)
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx, false);
                        router.push(AppRouter.refundBankAccount);
                      },
                      icon: const Icon(LucideIcons.landmark, size: 16),
                      label: const Text('Thêm tài khoản nhận tiền'),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: sending ? null : () => Navigator.pop(ctx, false),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: sending
                    ? null
                    : () async {
                        if (reasonCtrl.text.trim().isEmpty) {
                          setLocal(
                            () => error = 'Vui lòng nhập lý do hoàn tiền.',
                          );
                          return;
                        }
                        setLocal(() {
                          sending = true;
                          error = null;
                          needsBankAccount = false;
                        });
                        try {
                          await _service.requestRefund(
                            widget.orderId,
                            reason: reasonCtrl.text,
                          );
                          if (ctx.mounted) Navigator.pop(ctx, true);
                        } catch (e) {
                          setLocal(() {
                            sending = false;
                            needsBankAccount =
                                LockerOpsService.errorCode(e) ==
                                'BANK_ACCOUNT_REQUIRED';
                            error = LockerOpsService.isEndpointUnavailable(e)
                                ? 'Máy chủ chưa hỗ trợ yêu cầu hoàn tiền.'
                                : LockerOpsService.errorMessage(e);
                          });
                        }
                      },
                child: Text(sending ? 'Đang gửi...' : 'Gửi yêu cầu'),
              ),
            ],
          ),
        ),
      ),
    );
    if (done == true && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Đã gửi yêu cầu hoàn tiền — chờ quản trị viên duyệt.',
            ),
          ),
        );
      await _load();
      await widget.onChanged?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Đơn đang dùng: chỉ hiện khi đã có yêu cầu hoàn tiền (không hiện vòng tải
    // hay lỗi cho mục khách chưa dùng tới).
    if (!_orderClosed && _refunds.isEmpty) return const SizedBox.shrink();
    if (!_loading &&
        !_unavailable &&
        _error == null &&
        _refunds.isEmpty &&
        !_canRequest) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 1, color: opsBorder),
        const SizedBox(height: 12),
        const OpsSectionLabel('Hoàn tiền', icon: LucideIcons.undo2),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else ...[
          for (final r in _refunds) _RefundTile(refund: r),
          if (_canRequest)
            OpsSheetAction(
              label: 'Yêu cầu hoàn tiền',
              icon: LucideIcons.undo2,
              onTap: _request,
            ),
          if (_unavailable)
            const Text(
              'Máy chủ chưa hỗ trợ xem hoàn tiền. Vui lòng thử lại sau.',
              style: TextStyle(fontSize: 12, color: opsMutedText),
            )
          else if (_error != null)
            Row(
              children: [
                Expanded(
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                ),
                TextButton(onPressed: _load, child: const Text('Thử lại')),
              ],
            ),
        ],
      ],
    );
  }
}

class _RefundTile extends StatelessWidget {
  const _RefundTile({required this.refund});

  final Map<String, dynamic> refund;

  @override
  Widget build(BuildContext context) {
    final status = refund['status']?.toString();
    final color = refundStatusColor(status);
    final bank = [
      refund['bankName']?.toString().trim() ?? '',
      maskAccountNumber(refund['accountNumber']?.toString()),
    ].where((s) => s.isNotEmpty).join(' ');
    final rejection = refund['rejectionReason']?.toString().trim();
    final transferRef = refund['bankTransferRef']?.toString().trim();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: opsSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: opsBorder),
      ),
      child: Column(
        children: [
          OpsInfoRow(
            icon: LucideIcons.badgeInfo,
            label: 'Trạng thái',
            value: refundStatusLabel(status),
            valueColor: color,
          ),
          if (refund['amount'] != null)
            OpsInfoRow(
              icon: LucideIcons.banknote,
              label: 'Số tiền',
              value: fmtPrice(refund['amount']),
            ),
          if (refund['requestedAt'] != null)
            OpsInfoRow(
              icon: LucideIcons.calendar,
              label: 'Yêu cầu lúc',
              value: fmtDateTime(refund['requestedAt']),
            ),
          if (refund['processedAt'] != null)
            OpsInfoRow(
              icon: LucideIcons.calendarCheck,
              label: 'Xử lý lúc',
              value: fmtDateTime(refund['processedAt']),
            ),
          if (bank.isNotEmpty)
            OpsInfoRow(
              icon: LucideIcons.landmark,
              label: 'Nhận về',
              value: bank,
            ),
          if (transferRef != null && transferRef.isNotEmpty)
            OpsInfoRow(
              icon: LucideIcons.hash,
              label: 'Mã chuyển khoản',
              value: transferRef,
            ),
          if (rejection != null && rejection.isNotEmpty)
            OpsInfoRow(
              icon: LucideIcons.circleX,
              label: 'Lý do từ chối',
              value: rejection,
              valueColor: const Color(0xFFDC2626),
            ),
        ],
      ),
    );
  }
}
