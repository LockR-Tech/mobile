import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_position_snapshot.dart';

/// Parse 1 frame STOMP `/topic/deliveries/{orderId}/position` → snapshot.
///
/// Contract payload: `{ orderId, status, lat, lng, heading, etaMinutes, speed?, battery?, ts }`.
/// Viết tay + bắt lỗi mềm (giống `NotificationModel.fromJson` của realtime
/// service) để 1 frame lỗi không làm sập cả stream.
class DronePositionResponse {
  const DronePositionResponse._();

  /// Trả `null` nếu thiếu toạ độ (frame không hợp lệ) để caller bỏ qua.
  static DronePositionSnapshot? fromJson(
    Map<String, dynamic> json,
    String fallbackOrderId,
  ) {
    final data = json['data'] as Map<String, dynamic>? ?? json;

    final lat = _toDouble(data['lat']);
    final lng = _toDouble(data['lng']);
    if (lat == null || lng == null) return null;

    return DronePositionSnapshot(
      orderId: data['orderId']?.toString() ?? fallbackOrderId,
      status: (data['status'] ?? 'dispatched').toString(),
      lat: lat,
      lng: lng,
      headingDeg: _toDouble(data['heading']) ?? 0,
      etaMinutes: _toInt(data['etaMinutes']),
      speedMps: _toDouble(data['speed']),
      batteryPercent: _toInt(data['battery']),
      timestamp: _toDateTime(data['ts']),
    );
  }

  static double? _toDouble(Object? v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static int? _toInt(Object? v) {
    if (v == null) return null;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  /// `ts` có thể là epoch millis (num) hoặc chuỗi ISO-8601. Thiếu/không parse
  /// được → thời điểm hiện tại (để watchdog mất tín hiệu vẫn tính đúng).
  static DateTime _toDateTime(Object? v) {
    if (v is num) {
      return DateTime.fromMillisecondsSinceEpoch(v.toInt()).toLocal();
    }
    if (v is String) {
      final parsed = DateTime.tryParse(v);
      if (parsed != null) return parsed.toLocal();
    }
    return DateTime.now();
  }
}
