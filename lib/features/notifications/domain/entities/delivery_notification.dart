import 'package:flutter/material.dart';

/// 6 mốc trạng thái của một chuyến giao hàng (drone) mà backend sẽ bắn xuống
/// qua FCM. `unknown` để phòng khi nhận status lạ (không làm vỡ app).
enum DeliveryStatus {
  dispatched,
  approaching,
  arrived,
  delivered,
  delayed,
  failed,
  unknown;

  /// Chuyển chuỗi `status` trong payload FCM thành enum (không phân biệt hoa
  /// thường). Status lạ → [unknown].
  static DeliveryStatus fromRaw(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'dispatched':
        return DeliveryStatus.dispatched;
      case 'approaching':
        return DeliveryStatus.approaching;
      case 'arrived':
        return DeliveryStatus.arrived;
      case 'delivered':
        return DeliveryStatus.delivered;
      case 'delayed':
        return DeliveryStatus.delayed;
      case 'failed':
        return DeliveryStatus.failed;
      default:
        return DeliveryStatus.unknown;
    }
  }

  /// Tiêu đề mặc định (tiếng Việt) khi payload không gửi kèm title.
  String get defaultTitle {
    switch (this) {
      case DeliveryStatus.dispatched:
        return 'Drone đang giao hàng';
      case DeliveryStatus.approaching:
        return 'Drone sắp đến';
      case DeliveryStatus.arrived:
        return 'Drone đã đến nơi';
      case DeliveryStatus.delivered:
        return 'Giao hàng thành công';
      case DeliveryStatus.delayed:
        return 'Đơn hàng bị chậm';
      case DeliveryStatus.failed:
        return 'Giao hàng không thành công';
      case DeliveryStatus.unknown:
        return 'Cập nhật đơn hàng';
    }
  }

  /// Nội dung gợi ý (tiếng Việt) theo bộ mốc trong contract, dùng khi payload
  /// không gửi kèm `message`. [eta] chỉ chèn vào mốc `delayed`.
  String defaultBody(String? eta) {
    switch (this) {
      case DeliveryStatus.dispatched:
        return 'Drone đang trên đường giao hàng của bạn';
      case DeliveryStatus.approaching:
        return 'Drone sắp đến nơi, vui lòng chuẩn bị ra nhận';
      case DeliveryStatus.arrived:
        return 'Drone đã đến nơi, vui lòng ra nhận hàng';
      case DeliveryStatus.delivered:
        return 'Đã giao hàng thành công. Cảm ơn bạn!';
      case DeliveryStatus.delayed:
        return (eta != null && eta.isNotEmpty)
            ? 'Đơn của bạn đang bị chậm, dự kiến tới $eta'
            : 'Đơn của bạn đang bị chậm so với dự kiến';
      case DeliveryStatus.failed:
        return 'Giao không thành công, drone đang quay về';
      case DeliveryStatus.unknown:
        return 'Đơn hàng của bạn có cập nhật mới';
    }
  }

  /// Icon hiển thị trong app (lịch sử / banner). Dùng Material icon để chắc
  /// chắn có sẵn, không phụ thuộc bộ icon ngoài.
  IconData get icon {
    switch (this) {
      case DeliveryStatus.dispatched:
        return Icons.flight_takeoff;
      case DeliveryStatus.approaching:
        return Icons.near_me;
      case DeliveryStatus.arrived:
        return Icons.location_on;
      case DeliveryStatus.delivered:
        return Icons.check_circle;
      case DeliveryStatus.delayed:
        return Icons.schedule;
      case DeliveryStatus.failed:
        return Icons.error_outline;
      case DeliveryStatus.unknown:
        return Icons.local_shipping_outlined;
    }
  }

  /// Màu theo trạng thái (cho icon/badge trong UI).
  Color get color {
    switch (this) {
      case DeliveryStatus.dispatched:
        return const Color(0xFF1E5A8A); // xanh navy
      case DeliveryStatus.approaching:
        return const Color(0xFFD97706); // hổ phách
      case DeliveryStatus.arrived:
        return const Color(0xFF4F46E5); // chàm
      case DeliveryStatus.delivered:
        return const Color(0xFF16A34A); // xanh lá
      case DeliveryStatus.delayed:
        return const Color(0xFFF59E0B); // cam
      case DeliveryStatus.failed:
        return const Color(0xFFDC2626); // đỏ
      case DeliveryStatus.unknown:
        return const Color(0xFF64748B); // xám
    }
  }
}

/// Một thông báo giao hàng đã được bóc tách từ phần `data` của message FCM.
///
/// Payload contract (phần data): `{ orderId, status, eta, message }`.
/// `orderId` dùng để deep-link sang chi tiết đơn; `status` để chọn icon/màu/title.
class DeliveryNotification {
  const DeliveryNotification({
    required this.orderId,
    required this.status,
    required this.message,
    this.eta,
  });

  final String orderId;
  final DeliveryStatus status;
  final String message;
  final String? eta;

  /// Bóc tách từ `message.data`. Trả `null` nếu không phải noti giao hàng
  /// (thiếu `orderId` hoặc `status`) để caller bỏ qua, không xử lý nhầm.
  static DeliveryNotification? fromData(Map<String, dynamic> data) {
    final orderId = data['orderId']?.toString();
    final statusRaw = data['status']?.toString();
    if (orderId == null || orderId.isEmpty) return null;
    if (statusRaw == null || statusRaw.isEmpty) return null;

    return DeliveryNotification(
      orderId: orderId,
      status: DeliveryStatus.fromRaw(statusRaw),
      eta: data['eta']?.toString(),
      message: (data['message'] ?? '').toString(),
    );
  }

  /// Tiêu đề hiển thị: ưu tiên message backend gửi kèm title, nếu không có thì
  /// dùng tiêu đề mặc định theo status.
  String get displayTitle => status.defaultTitle;

  /// Nội dung hiển thị: ưu tiên `message` từ payload, fallback theo status.
  String get displayBody =>
      message.isNotEmpty ? message : status.defaultBody(eta);
}
