import 'package:flutter/material.dart';
import 'package:smart_laundry_locker/core/config/business_config_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/order_payment_sheet.dart';

typedef DroneOrderPayer =
    Future<OrderPaymentOutcome> Function(
      BuildContext context, {
      required int orderId,
      required double total,
    });

/// Quy tắc F1.02: đội bay chỉ tiếp nhận đơn đã thanh toán, nên đơn drone thu tiền
/// ngay tại chỗ (lúc vừa đặt, hoặc từ màn theo dõi) thay vì bắt khách sang danh
/// sách đơn. Dùng chung bảng thanh toán với đơn tủ để theo đúng các phương thức
/// admin đang bật. Lỗi gọi API được ném ra cho nơi gọi tự báo.
Future<OrderPaymentOutcome> payDroneOrder(
  BuildContext context, {
  required int orderId,
  required double total,
}) {
  final config = BusinessConfigService.instance;
  // Làm mới nền danh sách phương thức admin bật (trong TTL thì không gọi mạng).
  config.refresh();
  return payOrderAndAwaitPaid(
    context,
    service: LockerOpsService(),
    orderId: orderId,
    total: total,
    enabledMethods: config.current.enabledPaymentMethods,
  );
}

/// Câu báo cho khách sau một lần thanh toán đơn drone.
String droneOrderPaymentMessage(OrderPaymentOutcome outcome) =>
    switch (outcome) {
      OrderPaymentOutcome.paid =>
        'Đã thanh toán. Đội bay sẽ tiếp nhận đơn của bạn.',
      OrderPaymentOutcome.pending =>
        'Đang chờ xác nhận thanh toán, trạng thái sẽ tự cập nhật.',
      OrderPaymentOutcome.failed =>
        'Thanh toán chưa thành công. Đơn vẫn được giữ, bạn có thể thanh toán lại.',
      OrderPaymentOutcome.cancelled =>
        'Đơn drone chưa thanh toán. Thanh toán để đội bay tiếp nhận.',
    };
