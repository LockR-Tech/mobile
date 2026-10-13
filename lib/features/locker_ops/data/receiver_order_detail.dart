import 'package:smart_laundry_locker/core/utils/app_date_time.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/order_milestone.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/receiver_order.dart';

/// Một lần đổi chặng của đơn drone (`journey` trong chi tiết đơn phía người
/// nhận) — server chỉ trả chặng và thời điểm, không có người thao tác.
class DroneJourneyStep {
  const DroneJourneyStep({this.fromStage, required this.toStage, this.at});

  final String? fromStage;
  final String toStage;
  final DateTime? at;
}

/// Chi tiết một đơn phía người nhận / người lấy hộ —
/// `ReceiverOrderDetailResponse` của `GET /api/orders/incoming/{id}` và
/// `GET /api/orders/delegated-to-me/{id}`.
///
/// [order] giữ phần chung với thẻ trong danh sách (cùng tên trường), nên màn
/// chi tiết mở ngay bằng bản ghi của danh sách rồi bổ sung phần còn lại khi tải
/// xong ([loaded]).
class ReceiverOrderDetail {
  const ReceiverOrderDetail({
    required this.order,
    this.loaded = false,
    this.viewerRole,
    this.senderPhone,
    this.senderEmail,
    this.receiverEmail,
    this.boxSize,
    this.boxType,
    this.sourceLockerCode,
    this.sourceLockerName,
    this.sourceLockerAddress,
    this.routeDistanceMeters,
    this.intendedReceiveAt,
    this.rentalDurationHours,
    this.deliveryAddress,
    this.delegatePhone,
    this.customerNote,
    this.parcel,
    this.deliveryBlockReasonLabel,
    this.deliveryBlockedAt,
    this.failureReasonLabel,
    this.failedAt,
    this.parcelReturnedAt,
    this.etaMinutes,
    this.droneTrackingAvailable = false,
    this.journey = const [],
    this.paidAt,
    this.updatedAt,
    this.timeline = const [],
  });

  /// Chỉ có dữ liệu của danh sách (chưa tải chi tiết).
  factory ReceiverOrderDetail.fromOrder(ReceiverOrder order) =>
      ReceiverOrderDetail(order: order);

  final ReceiverOrder order;

  /// Đã có bản chi tiết từ server.
  final bool loaded;

  /// `RECEIVER` (đơn gửi tới tôi) | `DELEGATE` (đơn ủy quyền cho tôi lấy hộ).
  final String? viewerRole;
  final String? senderPhone;
  final String? senderEmail;
  final String? receiverEmail;

  /// Kích cỡ ô (SMALL/MEDIUM/LARGE) và loại ô (STANDARD/XL/DRONE).
  final String? boxSize;
  final String? boxType;

  /// Tủ gửi của đơn drone.
  final String? sourceLockerCode;
  final String? sourceLockerName;
  final String? sourceLockerAddress;
  final int? routeDistanceMeters;
  final DateTime? intendedReceiveAt;
  final int? rentalDurationHours;
  final String? deliveryAddress;
  final String? delegatePhone;

  /// Ghi chú người gửi nhập lúc tạo đơn.
  final String? customerNote;
  final OrderParcel? parcel;
  final String? deliveryBlockReasonLabel;
  final DateTime? deliveryBlockedAt;
  final String? failureReasonLabel;
  final DateTime? failedAt;
  final DateTime? parcelReturnedAt;

  /// Phút ước tính drone tới tủ nhận; `0` = đã tới.
  final int? etaMinutes;

  /// Người xem mở được màn theo dõi drone của đơn.
  final bool droneTrackingAvailable;

  /// Các lần đổi chặng của đơn drone, cũ → mới.
  final List<DroneJourneyStep> journey;
  final DateTime? paidAt;
  final DateTime? updatedAt;

  /// Các mốc đã xảy ra, cũ → mới.
  final List<OrderMilestone> timeline;

  bool get isDelegateView => viewerRole == 'DELEGATE';

  bool get isDrone => order.type == 'DRONE_DELIVERY';

  static ReceiverOrderDetail? tryParse(Map<String, dynamic> json) {
    final order = ReceiverOrder.tryParse(json);
    if (order == null) return null;
    final rawJourney = json['journey'];
    final journey = <DroneJourneyStep>[
      if (rawJourney is List)
        for (final e in rawJourney.whereType<Map>())
          if (_text(e['toStage']) != null)
            DroneJourneyStep(
              fromStage: _text(e['fromStage'])?.toUpperCase(),
              toStage: _text(e['toStage'])!.toUpperCase(),
              at: parseServerDateTime(e['occurredAt']),
            ),
    ];
    // Server trả mới nhất trước; màn hình đọc từ trên xuống theo thời gian.
    journey.sort((a, b) {
      final da = a.at;
      final db = b.at;
      if (da == null || db == null) return 0;
      return da.compareTo(db);
    });
    return ReceiverOrderDetail(
      order: order,
      loaded: true,
      viewerRole: _text(json['viewerRole'])?.toUpperCase(),
      senderPhone: _text(json['senderPhone']),
      senderEmail: _text(json['senderEmail']),
      receiverEmail: _text(json['receiverEmail']),
      boxSize: _text(json['boxSize'])?.toUpperCase(),
      boxType: _text(json['boxType'])?.toUpperCase(),
      sourceLockerCode: _text(json['sourceLockerCode']),
      sourceLockerName: _text(json['sourceLockerName']),
      sourceLockerAddress: _text(json['sourceLockerAddress']),
      routeDistanceMeters: _int(json['routeDistanceMeters']),
      intendedReceiveAt: parseServerDateTime(json['intendedReceiveAt']),
      rentalDurationHours: _int(json['rentalDurationHours']),
      deliveryAddress: _text(json['deliveryAddress']),
      delegatePhone: _text(json['delegatePhone']),
      customerNote: _text(json['customerNote']),
      parcel: OrderParcel.tryParse(json['parcel']),
      deliveryBlockReasonLabel: _text(json['deliveryBlockReasonLabel']),
      deliveryBlockedAt: parseServerDateTime(json['deliveryBlockedAt']),
      failureReasonLabel: _text(json['failureReasonLabel']),
      failedAt: parseServerDateTime(json['failedAt']),
      parcelReturnedAt: parseServerDateTime(json['parcelReturnedAt']),
      etaMinutes: _int(json['etaMinutes']),
      droneTrackingAvailable: json['droneTrackingAvailable'] == true,
      journey: List.unmodifiable(journey),
      paidAt: parseServerDateTime(json['paidAt']),
      updatedAt: parseServerDateTime(json['updatedAt']),
      timeline: OrderMilestone.listFrom(json['timeline']),
    );
  }

  static int? _int(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('${v ?? ''}');
  }

  static String? _text(dynamic v) {
    if (v == null) return null;
    final s = '$v'.trim();
    return s.isEmpty ? null : s;
  }
}
