import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_delivery_stage.dart';

/// Một snapshot vị trí drone (đã downsample) mà backend đẩy xuống NGƯỜI NHẬN qua
/// STOMP để vẽ live map — Phase 2.
///
/// CỐ Ý gọn: view người nhận không cần full telemetry kiểu pilot (không altitude,
/// không attitude, không MAVLink). `speedMps`/`batteryPercent` nullable — chỉ
/// hiển thị nếu backend gửi. Giữ toạ độ ở primitive `double` để domain không phụ
/// thuộc `latlong2` (presentation tự bọc thành `LatLng`).
class DronePositionSnapshot {
  final String orderId;
  final String status;
  final double lat;
  final double lng;
  final double headingDeg;
  final int? etaMinutes;
  final double? speedMps;
  final int? batteryPercent;
  final DateTime timestamp;

  const DronePositionSnapshot({
    required this.orderId,
    required this.status,
    required this.lat,
    required this.lng,
    required this.headingDeg,
    required this.timestamp,
    this.etaMinutes,
    this.speedMps,
    this.batteryPercent,
  });

  /// Mốc giao hàng suy ra từ `status` (dùng chung enum với timeline Phase 1).
  DroneDeliveryStage get stage => DroneDeliveryStage.fromRaw(status);
}
