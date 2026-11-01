import 'package:flutter/material.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

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
        return L10n.current.dnTitleEnRoute;
      case DeliveryStatus.approaching:
        return L10n.current.dnTitleApproaching;
      case DeliveryStatus.arrived:
        return L10n.current.dnTitleArrived;
      case DeliveryStatus.delivered:
        return L10n.current.dnTitleDelivered;
      case DeliveryStatus.delayed:
        return L10n.current.dnTitleDelayed;
      case DeliveryStatus.failed:
        return L10n.current.dnTitleFailed;
      case DeliveryStatus.unknown:
        return L10n.current.dnTitleUpdate;
    }
  }

  /// Nội dung gợi ý (tiếng Việt) theo bộ mốc trong contract, dùng khi payload
  /// không gửi kèm `message`. [eta] chỉ chèn vào mốc `delayed`.
  String defaultBody(String? eta) {
    switch (this) {
      case DeliveryStatus.dispatched:
        return L10n.current.dnBodyEnRoute;
      case DeliveryStatus.approaching:
        return L10n.current.dnBodyApproaching;
      case DeliveryStatus.arrived:
        return L10n.current.dnBodyArrived;
      case DeliveryStatus.delivered:
        return L10n.current.dnBodyDelivered;
      case DeliveryStatus.delayed:
        return (eta != null && eta.isNotEmpty)
            ? L10n.current.dnBodyDelayedEta(eta)
            : L10n.current.dnBodyDelayed;
      case DeliveryStatus.failed:
        return L10n.current.dnBodyFailed;
      case DeliveryStatus.unknown:
        return L10n.current.dnBodyUpdate;
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
