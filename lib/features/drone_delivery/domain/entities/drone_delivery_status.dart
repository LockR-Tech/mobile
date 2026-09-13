import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_delivery_stage.dart';

/// Trạng thái một chuyến giao hàng bằng drone cho NGƯỜI NHẬN theo dõi.
///
/// Mirror `DispatchStatusEntity` của logistics_send: giữ `status` dạng chuỗi
/// thô từ backend, đồng thời expose [stage] đã parse để UI vẽ timeline.
class DroneDeliveryStatus {
  final String status;
  final String? deliveryId;
  final String? orderId;
  final String? orderCode;
  final String? droneCode;
  final int? etaMinutes;
  final DateTime? updatedAt;

  const DroneDeliveryStatus({
    required this.status,
    this.deliveryId,
    this.orderId,
    this.orderCode,
    this.droneCode,
    this.etaMinutes,
    this.updatedAt,
  });

  /// Mốc timeline suy ra từ `status` (không phân biệt hoa thường).
  DroneDeliveryStage get stage => DroneDeliveryStage.fromRaw(status);
}
