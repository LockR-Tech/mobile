import 'package:flutter/material.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

/// Câu nói rõ tiền đi đâu khi khách huỷ đơn ở chặng chờ đội bay tiếp nhận.
String droneCancelRefundNote({required bool isPaid, num? totalPrice}) => isPaid
    ? L10n.current.ocPaidRefund(
        totalPrice == null ? L10n.current.ocDroneFee : fmtPrice(totalPrice),
      )
    : L10n.current.ocUnpaidNoFee;

/// Người đặt huỷ đơn drone khi đội bay chưa tiếp nhận: hỏi xác nhận, gọi huỷ (server
/// nhả ô ở hai tủ và ghi yêu cầu hoàn tiền nếu đơn đã thanh toán) rồi trả câu báo kết quả.
/// Trả `null` khi khách không xác nhận. Dùng chung cho màn theo dõi và danh sách đơn.
Future<String?> confirmAndCancelDroneOrder(
  BuildContext context, {
  required int orderId,
  String? orderCode,
  required bool isPaid,
  num? totalPrice,
  Future<Map<String, dynamic>> Function(int orderId)? cancelOrder,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(context.l10n.ocTitle),
      content: Text(
        context.l10n.ocBody(
          orderCode ?? '',
          droneCancelRefundNote(isPaid: isPaid, totalPrice: totalPrice),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(context.l10n.ordKeepOrder),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFDC2626),
          ),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(context.l10n.ddCancelOrder),
        ),
      ],
    ),
  );
  if (confirmed != true) return null;

  try {
    final canceled = await (cancelOrder ?? LockerOpsService().cancelOrder)(
      orderId,
    );
    return switch ('${canceled['paymentStatus']}'.toUpperCase()) {
      'REFUND_PENDING' =>
        L10n.current.ocRefundPending,
      'REFUNDED' => L10n.current.ocRefunded,
      'PAID' =>
        L10n.current.ocPaidNoRefund,
      _ => L10n.current.ocCancelled,
    };
  } catch (error) {
    return switch (LockerOpsService.errorCode(error)) {
      'DRONE_ORDER_STATUS_INVALID' || 'ORDER_STATUS_INVALID' =>
        L10n.current.ocAlreadyAccepted,
      'ORDER_FORBIDDEN' => L10n.current.ocOwnerOnly,
      _ => LockerOpsService.errorMessage(error),
    };
  }
}
