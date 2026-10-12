import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_delivery_stage.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_delivery_status.dart';

/// Ai đang xem màn theo dõi đơn drone. Server kiểm quyền mọi thao tác
/// (`ORDER_FORBIDDEN`); app chỉ ẩn nút không dành cho người đang xem.
enum DroneViewerRole {
  /// Người đặt đơn (`userId`).
  booker,

  /// Người nhận có tài khoản Lock.R (`receiverUserId`), không phải người đặt.
  receiver,

  /// Không khớp ai (vd. được chia sẻ link) — chỉ xem.
  other,
}

/// Xác định vai trò của [currentUserId] với đơn. Server cũ chưa trả `userId`
/// thì không phân biệt được ⇒ coi như người đặt (hành vi cũ; server vẫn chặn).
DroneViewerRole droneViewerRole(DroneDeliveryStatus status, int? currentUserId) {
  final booker = status.userId;
  if (booker == null) return DroneViewerRole.booker;
  if (currentUserId == null) return DroneViewerRole.other;
  if (booker == currentUserId) return DroneViewerRole.booker;
  if (status.receiverUserId == currentUserId) return DroneViewerRole.receiver;
  return DroneViewerRole.other;
}

/// Người đặt cũng là người nhận: không ghi người nhận khác, hoặc người nhận
/// chính là tài khoản người đặt.
bool droneBookerReceivesSelf(DroneDeliveryStatus status) {
  final receiver = status.receiverUserId;
  if (receiver != null) return receiver == status.userId;
  final phone = (status.receiverPhone ?? '').trim();
  return phone.isEmpty || phone == (status.customerPhone ?? '').trim();
}

/// Nút "Nhận hàng" ở chặng sẵn sàng nhận dẫn tới đâu.
enum DronePickupAction {
  /// Không có nút.
  none,

  /// Người đặt tự nhận: mở chi tiết đơn (mã PIN, mở ô) trong "Đơn hàng".
  bookerOrder,

  /// Người đặt gửi cho người khác: xem chi tiết đơn (mã đã gửi cho người nhận).
  bookerOrderForOther,

  /// Người nhận: lấy mã PIN từ `GET /api/orders/incoming`.
  receiverPin,
}

/// Thao tác khách được thấy trên màn theo dõi, theo vai trò và trạng thái đơn.
class DroneCustomerActions {
  const DroneCustomerActions({
    required this.canPay,
    required this.canDeclineSurcharge,
    required this.canConfirmDrop,
    required this.canCancel,
    required this.pickup,
  });

  factory DroneCustomerActions.of(
    DroneDeliveryStatus status,
    DroneViewerRole role,
  ) {
    final booker = role == DroneViewerRole.booker;
    final ready = status.stage == DroneDeliveryStage.readyForPickup;
    final DronePickupAction pickup;
    if (!ready) {
      pickup = DronePickupAction.none;
    } else if (booker) {
      pickup = droneBookerReceivesSelf(status)
          ? DronePickupAction.bookerOrder
          : DronePickupAction.bookerOrderForOther;
    } else if (role == DroneViewerRole.receiver) {
      pickup = DronePickupAction.receiverPin;
    } else {
      pickup = DronePickupAction.none;
    }
    return DroneCustomerActions(
      canPay:
          booker &&
          (status.needsPaymentBeforeDispatch || status.needsSurchargePayment),
      canDeclineSurcharge: booker && status.needsSurchargePayment,
      canConfirmDrop: booker && status.needsParcelDrop,
      canCancel: booker && status.canCustomerCancel,
      pickup: pickup,
    );
  }

  final bool canPay;
  final bool canDeclineSurcharge;
  final bool canConfirmDrop;
  final bool canCancel;
  final DronePickupAction pickup;
}
