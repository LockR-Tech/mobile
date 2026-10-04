import 'package:flutter/material.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';

/// Câu nói rõ tiền đi đâu khi khách huỷ đơn ở chặng chờ đội bay tiếp nhận.
String droneCancelRefundNote({required bool isPaid, num? totalPrice}) => isPaid
    ? 'Đơn đã thanh toán: '
          '${totalPrice == null ? 'phí giao drone' : fmtPrice(totalPrice)} '
          'sẽ được hoàn về ví Lock.R của bạn.'
    : 'Đơn chưa thanh toán nên không phát sinh phí.';

/// Người đặt huỷ đơn drone khi đội bay chưa tiếp nhận: hỏi xác nhận, gọi huỷ (server
/// nhả ô ở hai tủ và hoàn tiền về ví nếu đơn đã thanh toán) rồi trả câu báo kết quả.
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
      title: const Text('Huỷ đơn giao drone?'),
      content: Text(
        'Đơn ${orderCode ?? ''} sẽ bị huỷ và ô drone ở hai tủ được nhả. '
        '${droneCancelRefundNote(isPaid: isPaid, totalPrice: totalPrice)}',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Giữ đơn'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFDC2626),
          ),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Huỷ đơn'),
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
      'REFUNDED' => 'Đã huỷ đơn. Tiền đã được hoàn về ví Lock.R của bạn.',
      'PAID' =>
        'Đã huỷ đơn. Tiền chưa được hoàn tự động, vui lòng liên hệ hỗ trợ.',
      _ => 'Đã huỷ đơn.',
    };
  } catch (error) {
    return switch (LockerOpsService.errorCode(error)) {
      'DRONE_ORDER_STATUS_INVALID' || 'ORDER_STATUS_INVALID' =>
        'Đội bay đã tiếp nhận nên đơn không còn huỷ được trong ứng dụng.',
      'ORDER_FORBIDDEN' => 'Chỉ người đặt đơn mới huỷ được đơn này.',
      _ => LockerOpsService.errorMessage(error),
    };
  }
}
