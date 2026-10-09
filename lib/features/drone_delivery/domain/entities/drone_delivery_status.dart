import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_delivery_stage.dart';

/// Trạng thái một chuyến giao hàng bằng drone — read model chung cho khách,
/// điều phối viên và admin (`DroneDeliveryOrderResponse` của order-service).
///
/// Mirror `DispatchStatusEntity` của logistics_send: giữ `status` dạng chuỗi
/// thô từ backend, đồng thời expose [stage] đã parse để UI vẽ timeline.
class DroneDeliveryStatus {
  /// Chặng hiệu lực: `deliveryStage`, hoặc trạng thái đơn khi đơn đã kết thúc
  /// (COMPLETED / CANCELED / EXPIRED) — xem `DroneDeliveryResponse.toEntity`.
  final String status;
  final String? deliveryId;
  final String? orderId;
  final String? orderCode;
  final String? droneCode;
  final int? droneUnitId;
  final int? etaMinutes;
  final DateTime? updatedAt;
  final String? orderStatus;
  final String? paymentStatus;
  final String? missionStatus;
  final String? fulfillmentMode;

  /// Backend đang có nguồn vị trí trực tiếp cho đơn này (đơn DEMO đang bay, hoặc drone
  /// thật còn gửi telemetry); null với server cũ chưa trả field này.
  final bool? liveTracking;
  final double? totalPrice;

  /// Phí thu thêm vì đội bay cân kiện nặng hơn khối lượng khai báo; null khi không lệch.
  final double? weightSurcharge;

  /// Phần còn phải trả (tổng hiện tại trừ phần đã trả); null với server cũ.
  final double? amountDue;
  final int? sourceLockerId;
  final int? destinationLockerId;
  final int? reservedBoxId;

  /// Số ô in trên tủ nhận. Người dùng chỉ thấy số này, không thấy id nội bộ.
  final int? reservedBoxNumber;

  /// Số ô drone ở tủ gửi đang giữ cho kiện này; null sau khi đã nạp lên drone.
  final int? sourceBoxNumber;
  final String? description;
  final int? expectedWeightGrams;
  final int? payloadWeightGrams;
  final String? sealCode;
  final String? loadingNote;

  /// Ba mục checklist nạp hàng; null khi chưa xác nhận nạp.
  final bool? parcelMatched;
  final bool? payloadSecured;
  final bool? compartmentLocked;
  final String? customerName;
  final String? customerPhone;
  final String? receiverName;
  final String? receiverPhone;
  final int? assignedByUserId;
  final String? assignedByName;
  final int? loadedByUserId;
  final String? loadedByName;
  final int? cancelReason;
  final String? cancelNote;
  final DateTime? createdAt;
  final DateTime? paidAt;

  /// Lần thanh toán thành công gần nhất: phương thức, mã tham chiếu Lock.R và mã
  /// giao dịch phía cổng/ngân hàng (null với ví Lock.R, tiền mặt).
  final String? paymentMethod;
  final String? paymentReference;
  final String? paymentTransactionId;

  /// Thời điểm điều phối viên tiếp nhận (= lúc tạo mission).
  final DateTime? acceptedAt;
  final DateTime? loadedAt;
  final DateTime? readyToLaunchAt;
  final DateTime? launchingAt;
  final DateTime? pickupDeadline;
  final DateTime? completedAt;
  final DroneLockerPoint? sourceLocker;
  final DroneLockerPoint? destinationLocker;

  /// Khai báo kiện lúc đặt đơn; kích thước và giá trị khai báo có thể null.
  final String? parcelCategory;
  final int? parcelLengthCm;
  final int? parcelWidthCm;
  final int? parcelHeightCm;
  final double? declaredValue;
  final bool? fragile;

  /// Khoảng cách đường chim bay tủ gửi → tủ nhận (mét).
  final int? routeDistanceMeters;

  /// Người gửi xác nhận đã bỏ kiện vào ô gửi; null ⇒ đội bay chưa tiếp nhận được.
  final DateTime? parcelDroppedAt;

  /// Đơn đã đóng mà kiện chưa được trả cho người gửi. Null với server cũ chưa
  /// theo dõi việc bàn giao kiện.
  final bool? parcelReturnPending;

  /// `SOURCE_BOX` | `FLIGHT_TEAM` khi kiện đang chờ trả.
  final String? parcelHeldAt;
  final DateTime? parcelReturnedAt;
  final String? parcelReturnNote;

  /// Mốc hành trình, mới nhất trước.
  final List<DroneJourneyEvent> journeyEvents;

  const DroneDeliveryStatus({
    required this.status,
    this.deliveryId,
    this.orderId,
    this.orderCode,
    this.droneCode,
    this.droneUnitId,
    this.etaMinutes,
    this.updatedAt,
    this.orderStatus,
    this.paymentStatus,
    this.missionStatus,
    this.fulfillmentMode,
    this.liveTracking,
    this.totalPrice,
    this.weightSurcharge,
    this.amountDue,
    this.sourceLockerId,
    this.destinationLockerId,
    this.reservedBoxId,
    this.reservedBoxNumber,
    this.sourceBoxNumber,
    this.description,
    this.expectedWeightGrams,
    this.payloadWeightGrams,
    this.sealCode,
    this.loadingNote,
    this.parcelMatched,
    this.payloadSecured,
    this.compartmentLocked,
    this.customerName,
    this.customerPhone,
    this.receiverName,
    this.receiverPhone,
    this.assignedByUserId,
    this.assignedByName,
    this.loadedByUserId,
    this.loadedByName,
    this.cancelReason,
    this.cancelNote,
    this.createdAt,
    this.paidAt,
    this.paymentMethod,
    this.paymentReference,
    this.paymentTransactionId,
    this.acceptedAt,
    this.loadedAt,
    this.readyToLaunchAt,
    this.launchingAt,
    this.pickupDeadline,
    this.completedAt,
    this.sourceLocker,
    this.destinationLocker,
    this.parcelCategory,
    this.parcelLengthCm,
    this.parcelWidthCm,
    this.parcelHeightCm,
    this.declaredValue,
    this.fragile,
    this.routeDistanceMeters,
    this.parcelDroppedAt,
    this.parcelReturnPending,
    this.parcelHeldAt,
    this.parcelReturnedAt,
    this.parcelReturnNote,
    this.journeyEvents = const [],
  });

  /// Mốc timeline suy ra từ `status` (không phân biệt hoa thường).
  DroneDeliveryStage get stage => DroneDeliveryStage.fromRaw(status);

  /// Mốc mới nhất trong nhật ký — thời điểm chặng hiện tại bắt đầu.
  bool get isPaid => (paymentStatus ?? '').toUpperCase() == 'PAID';

  /// Đơn còn chờ đội bay nhưng chưa trả tiền — đội bay không tiếp nhận được.
  bool get needsPaymentBeforeDispatch =>
      stage == DroneDeliveryStage.awaitingDispatch && !isPaid;

  /// Đội bay đã nạp hàng nhưng kiện nặng hơn khai báo: khách phải trả phần chênh thì
  /// drone mới được phóng (`DRONE_SURCHARGE_UNPAID`).
  bool get needsSurchargePayment =>
      stage == DroneDeliveryStage.accepted &&
      !isPaid &&
      (weightSurcharge ?? 0) > 0;

  /// Đơn đã trả tiền nhưng người gửi chưa xác nhận bỏ kiện vào ô gửi — đội bay
  /// chưa tiếp nhận được (`DRONE_PARCEL_NOT_DROPPED`). Server cũ không theo dõi
  /// mốc này ([parcelReturnPending] null) thì không nhắc.
  bool get needsParcelDrop =>
      parcelReturnPending != null &&
      stage == DroneDeliveryStage.awaitingDispatch &&
      isPaid &&
      parcelDroppedAt == null;

  /// Số tiền khách cần trả lúc này.
  double? get payableAmount =>
      (amountDue ?? 0) > 0 ? amountDue : (needsSurchargePayment ? weightSurcharge : totalPrice);

  /// Người đặt chỉ huỷ được khi đội bay chưa tiếp nhận (khớp
  /// `OrderService.assertDroneCancelable`); sau đó chỉ đội bay huỷ được.
  bool get canCustomerCancel => stage == DroneDeliveryStage.awaitingDispatch;

  DateTime? get stageChangedAt =>
      journeyEvents.isEmpty ? updatedAt : journeyEvents.first.occurredAt;

  /// Lần ĐẦU nhật ký đạt chặng [rawStage] (nhật ký xếp mới nhất trước).
  DateTime? firstReachedAt(String rawStage) {
    final wanted = rawStage.toUpperCase();
    for (final event in journeyEvents.reversed) {
      if (event.toStage.toUpperCase() == wanted && !event.isPickupCodeSent) {
        return event.occurredAt;
      }
    }
    return null;
  }

  /// Gửi hàng: lúc drone rời trạm, chưa có thì lúc khởi phóng.
  DateTime? get sentAt => firstReachedAt('DEPARTED') ?? launchingAt;

  /// Hàng vào ô tủ nhận.
  DateTime? get depositedAt => firstReachedAt('READY_FOR_PICKUP');

  /// Dòng nhật ký hệ thống ghi đã gửi (hoặc chưa gửi được) mã nhận hàng.
  DroneJourneyEvent? get pickupCodeEvent {
    for (final event in journeyEvents) {
      if (event.isPickupCodeSent) return event;
    }
    return null;
  }
}

class DroneLockerPoint {
  const DroneLockerPoint({
    required this.id,
    this.code,
    this.name,
    this.address,
    this.latitude,
    this.longitude,
  });

  final int id;
  final String? code;
  final String? name;
  final String? address;
  final double? latitude;
  final double? longitude;

  /// Tên hiển thị: tên tủ, kèm mã tủ nếu có; không có gì thì rơi về `Tủ #id`.
  String get displayName {
    final n = (name ?? '').trim();
    final c = (code ?? '').trim();
    if (n.isNotEmpty && c.isNotEmpty) return '$n ($c)';
    if (n.isNotEmpty) return n;
    if (c.isNotEmpty) return c;
    return 'Tủ #$id';
  }

  bool get hasCoordinates => latitude != null && longitude != null;

  /// Có đủ thông tin để mở chỉ đường (toạ độ hoặc địa chỉ).
  bool get canNavigate => hasCoordinates || (address ?? '').trim().isNotEmpty;
}

class DroneJourneyEvent {
  const DroneJourneyEvent({
    this.id,
    this.fromStage,
    required this.toStage,
    this.actorUserId,
    this.actorName,
    this.note,
    this.occurredAt,
  });

  final int? id;
  final String? fromStage;
  final String toStage;
  final int? actorUserId;
  final String? actorName;
  final String? note;
  final DateTime? occurredAt;

  /// Backend ghi việc gửi mã nhận hàng thành dòng READY_FOR_PICKUP → READY_FOR_PICKUP.
  bool get isPickupCodeSent =>
      (fromStage ?? '').toUpperCase() == 'READY_FOR_PICKUP' &&
      toStage.toUpperCase() == 'READY_FOR_PICKUP';
}
