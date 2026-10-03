import 'dart:math' as math;

import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_delivery_stage.dart';

/// Hình học lộ trình tủ gửi → tủ nhận cho bản đồ theo dõi. Thuần Dart (không phụ
/// thuộc `latlong2`) để domain và test không kéo theo thư viện bản đồ.

/// Khoảng cách đường chim bay giữa hai toạ độ, tính bằng km (công thức haversine).
double droneDistanceKm(double lat1, double lng1, double lat2, double lng2) {
  const earthRadiusKm = 6371.0;
  double rad(double deg) => deg * math.pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLng = rad(lng2 - lng1);
  final a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(rad(lat1)) *
          math.cos(rad(lat2)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  return earthRadiusKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

/// Phần quãng đường đã đi (0 = tại tủ gửi, 1 = tại tủ nhận) ước theo chặng — cùng
/// bảng với `DronePositionBroadcaster` ở order-service, lấy điểm giữa mỗi chặng vì
/// app không biết drone đã ở trong chặng bao lâu. null khi drone không ở trên không.
double? droneStageProgress(DroneDeliveryStage stage) => switch (stage) {
  DroneDeliveryStage.launching => 0.0,
  DroneDeliveryStage.departed => 0.125,
  DroneDeliveryStage.enRoute => 0.525,
  DroneDeliveryStage.approaching => 0.9,
  DroneDeliveryStage.arrived => 1.0,
  _ => null,
};

/// `850 m` dưới 1 km, `2,35 km` từ 1 km trở lên.
String droneKmLabel(double km) {
  if (km < 1) return '${(km * 1000).round()} m';
  return '${km.toStringAsFixed(2).replaceAll('.', ',')} km';
}

/// `10.776900, 106.700900` — đủ 6 chữ số thập phân (~0,1 m).
String droneCoordinateLabel(double lat, double lng) =>
    '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
