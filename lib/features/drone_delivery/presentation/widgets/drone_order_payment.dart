import 'package:flutter/material.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/order_payment_sheet.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

typedef DroneOrderPayer =
    Future<OrderPaymentOutcome> Function(
      BuildContext context, {
      required int orderId,
      required double total,
    });

/// Quy tắc F1.02: đội bay chỉ tiếp nhận đơn đã thanh toán, nên đơn drone thu tiền
/// ngay tại chỗ (lúc vừa đặt, hoặc từ màn theo dõi) thay vì bắt khách sang danh
/// sách đơn. Dùng chung bảng thanh toán SePay VietQR với đơn tủ (phương thức
/// duy nhất). Lỗi tạo mã hiện ngay trong bảng.
Future<OrderPaymentOutcome> payDroneOrder(
  BuildContext context, {
  required int orderId,
  required double total,
}) {
  return payOrderAndAwaitPaid(
    context,
    service: LockerOpsService(),
    orderId: orderId,
    total: total,
  );
}

/// Câu báo cho khách sau một lần thanh toán đơn drone.
String droneOrderPaymentMessage(OrderPaymentOutcome outcome) =>
    switch (outcome) {
      OrderPaymentOutcome.paid =>
        L10n.current.opPaid,
      OrderPaymentOutcome.pending =>
        L10n.current.opPending,
      OrderPaymentOutcome.failed =>
        L10n.current.opFailed,
      OrderPaymentOutcome.cancelled =>
        L10n.current.opUnpaid,
    };
