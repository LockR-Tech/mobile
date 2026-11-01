import 'dart:async';

import 'package:flutter/material.dart';

import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/sepay_payment.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

export 'package:smart_laundry_locker/features/payment/domain/sepay_transfer.dart'
    show checkoutQrUrl;

enum OrderPaymentOutcome {
  /// Đơn đã được ghi nhận PAID.
  paid,

  /// Đã thanh toán nhưng server chưa ghi nhận xong trong thời gian chờ.
  pending,

  /// Khách đóng bảng thanh toán khi chưa có mã để trả (hoặc tạo mã lỗi).
  cancelled,

  /// Cổng thanh toán báo thất bại.
  failed,
}

/// Thanh toán một đơn bằng SePay VietQR (phương thức duy nhất — không còn bảng
/// chọn, không trả bằng ví) rồi chờ tới khi đơn thật sự PAID.
///
/// Dùng chung cho gia hạn thuê, phí quá hạn, đơn drone và nút "Thanh toán" ở
/// danh sách đơn. Mở bảng có mã VietQR ngay, mỗi lần gọi tạo ĐÚNG MỘT giao
/// dịch checkout; bảng tự hỏi trạng thái đơn ~3 s/lần và khi app quay lại
/// foreground, đủ tiền thì tự đóng với [OrderPaymentOutcome.paid]. Lỗi tạo giao
/// dịch hiện ngay trong bảng (có "Thử lại").
Future<OrderPaymentOutcome> payOrderAndAwaitPaid(
  BuildContext context, {
  required LockerOpsService service,
  required int orderId,
  required double total,
  String? orderCode,

  /// Lý do trả tiền, hiện lên chi tiết đơn để phân biệt nhiều lần trả trên cùng
  /// một đơn. Nơi gọi biết rõ mới truyền; không truyền thì server tự suy.
  String? description,
}) async {
  final controller = SepayPaymentController(
    service: service,
    orderId: orderId,
    orderCode: orderCode,
    amount: total,
    description: description,
  );
  unawaited(controller.start());
  try {
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) => _SepayPaymentSheet(controller: controller),
    );
    if (controller.paid) return OrderPaymentOutcome.paid;
    if (controller.gatewayFailed) return OrderPaymentOutcome.failed;
    // Chưa có mã để trả (đang tạo / lỗi) ⇒ coi như khách huỷ.
    if (controller.transfer == null) return OrderPaymentOutcome.cancelled;
    // Khách đóng mã trước khi tiền về: hỏi lại một lần. Chuyển khoản có thể đã
    // đi nhưng webhook chưa tới ⇒ "đang chờ", không phải thất bại.
    return await controller.checkNow()
        ? OrderPaymentOutcome.paid
        : OrderPaymentOutcome.pending;
  } finally {
    controller.dispose();
  }
}

/// Bảng thanh toán SePay: mã VietQR + "Thanh toán bằng app ngân hàng" + "Tôi đã
/// chuyển khoản — Kiểm tra ngay". Đơn PAID ⇒ hiện thành công rồi tự đóng.
class _SepayPaymentSheet extends StatefulWidget {
  const _SepayPaymentSheet({required this.controller});

  final SepayPaymentController controller;

  @override
  State<_SepayPaymentSheet> createState() => _SepayPaymentSheetState();
}

class _SepayPaymentSheetState extends State<_SepayPaymentSheet> {
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  Future<void> _onChanged() async {
    if (!widget.controller.paid || _closing) return;
    _closing = true;
    // Cho khách thấy "Thanh toán thành công" rồi tự đóng.
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 4,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.payTransferAmount(fmtPrice(widget.controller.amount)),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 17,
              color: opsDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            context.l10n.payScanAnyBank,
            style: TextStyle(fontSize: 13, color: opsMutedText),
          ),
          const SizedBox(height: 16),
          SepayQrSection(controller: widget.controller),
          const SizedBox(height: 12),
          SepayPaymentActions(controller: widget.controller),
        ],
      ),
    );
  }
}
