import 'package:json_annotation/json_annotation.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_delivery_status.dart';
import 'package:smart_laundry_locker/core/utils/app_date_time.dart';

part 'drone_delivery_response.g.dart';

/// Model đáp ứng của `GET /api/orders/{orderId}/drone-delivery`.
///
/// `fromJson` viết tay để chịu được biến thể key/nesting từ backend (giống
/// `DispatchStatusResponse`); `toJson` sinh bằng build_runner.
@JsonSerializable()
class DroneDeliveryResponse {
  final String status;
  final String? deliveryId;
  final String? orderId;
  final String? orderCode;
  final String? droneCode;
  final int? etaMinutes;
  final String? updatedAt;
  final Map<String, dynamic> raw;

  const DroneDeliveryResponse({
    required this.status,
    this.deliveryId,
    this.orderId,
    this.orderCode,
    this.droneCode,
    this.etaMinutes,
    this.updatedAt,
    this.raw = const {},
  });

  factory DroneDeliveryResponse.fromJson(Map<String, dynamic> json) {
    // ApiClient có thể lồng payload trong 'data'.
    final data = json['data'] as Map<String, dynamic>? ?? json;

    return DroneDeliveryResponse(
      status:
          (data['deliveryStage'] ?? data['status'] ?? data['Status'])
              ?.toString() ??
          'unknown',
      deliveryId: (data['missionId'] ?? data['deliveryId'])?.toString(),
      orderId: data['orderId']?.toString(),
      orderCode: data['orderCode']?.toString(),
      droneCode: data['droneCode']?.toString(),
      etaMinutes: (data['etaMinutes'] as num?)?.toInt(),
      updatedAt: data['updatedAt']?.toString(),
      raw: Map<String, dynamic>.from(data),
    );
  }

  Map<String, dynamic> toJson() => _$DroneDeliveryResponseToJson(this);

  /// Đơn đã kết thúc thì trạng thái đơn quyết định chặng hiển thị: backend giữ
  /// `deliveryStage = READY_FOR_PICKUP` sau khi khách lấy hàng, và đơn cũ bị
  /// khách huỷ vẫn mang `AWAITING_DISPATCH`.
  String get _effectiveStage {
    final orderStatus = raw['status']?.toString().toUpperCase();
    if (raw.containsKey('deliveryStage') &&
        const {'COMPLETED', 'CANCELED', 'EXPIRED'}.contains(orderStatus)) {
      return orderStatus!;
    }
    return status;
  }

  DroneDeliveryStatus toEntity() => DroneDeliveryStatus(
    status: _effectiveStage,
    deliveryId: deliveryId,
    orderId: orderId,
    orderCode: orderCode,
    droneCode: droneCode,
    droneUnitId: _asInt(raw['droneUnitId']),
    etaMinutes: etaMinutes,
    updatedAt: parseServerDateTime(updatedAt),
    orderStatus: raw['status']?.toString(),
    paymentStatus: raw['paymentStatus']?.toString(),
    missionStatus: raw['missionStatus']?.toString(),
    fulfillmentMode: raw['fulfillmentMode']?.toString(),
    liveTracking: raw['liveTracking'] as bool?,
    totalPrice: _asDouble(raw['totalPrice']),
    weightSurcharge: _asDouble(raw['weightSurcharge']),
    amountDue: _asDouble(raw['amountDue']),
    sourceLockerId: _asInt(raw['sourceLockerId']),
    destinationLockerId: _asInt(raw['destinationLockerId']),
    reservedBoxId: _asInt(raw['reservedBoxId']),
    reservedBoxNumber: _asInt(raw['reservedBoxNumber']),
    sourceBoxNumber: _asInt(raw['sourceBoxNumber']),
    description: _text(raw['description']),
    expectedWeightGrams: _asInt(raw['parcelWeightGrams']),
    payloadWeightGrams: _asInt(raw['payloadWeightGrams']),
    sealCode: _text(raw['sealCode']),
    loadingNote: _text(raw['loadingNote']),
    parcelMatched: raw['parcelMatched'] as bool?,
    payloadSecured: raw['payloadSecured'] as bool?,
    compartmentLocked: raw['compartmentLocked'] as bool?,
    customerName: _text(raw['customerName']),
    customerPhone: _text(raw['customerPhone']),
    receiverName: _text(raw['receiverName']),
    receiverPhone: _text(raw['receiverPhone']),
    assignedByUserId: _asInt(raw['assignedByUserId']),
    assignedByName: _text(raw['assignedByName']),
    loadedByUserId: _asInt(raw['loadedByUserId']),
    loadedByName: _text(raw['loadedByName']),
    cancelReason: _asInt(raw['cancelReason']),
    cancelNote: _text(raw['cancelNote']),
    createdAt: parseServerDateTime(raw['createdAt']),
    paidAt: parseServerDateTime(raw['paidAt']),
    paymentMethod: _text(raw['paymentMethod']),
    paymentReference: _text(raw['paymentReference']),
    paymentTransactionId: _text(raw['paymentTransactionId']),
    acceptedAt: parseServerDateTime(raw['missionCreatedAt']),
    loadedAt: parseServerDateTime(raw['loadedAt']),
    readyToLaunchAt: parseServerDateTime(raw['readyToLaunchAt']),
    launchingAt: parseServerDateTime(raw['launchingAt']),
    pickupDeadline: parseServerDateTime(raw['pickupDeadline']),
    completedAt: parseServerDateTime(raw['completedAt']),
    sourceLocker: _locker(raw['sourceLocker'], raw['sourceLockerId']),
    destinationLocker: _locker(
      raw['destinationLocker'],
      raw['destinationLockerId'],
    ),
    journeyEvents: _events(raw['journeyEvents']),
  );

  /// Chuỗi đã cắt khoảng trắng; rỗng/null ⇒ null để UI hiện dấu `—`.
  static String? _text(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  static int? _asInt(dynamic value) =>
      value is num ? value.toInt() : int.tryParse('$value');

  static double? _asDouble(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value');

  static DroneLockerPoint? _locker(dynamic value, dynamic fallbackId) {
    final map = value is Map ? Map<String, dynamic>.from(value) : null;
    final id = _asInt(map?['lockerId'] ?? fallbackId);
    if (id == null) return null;
    return DroneLockerPoint(
      id: id,
      code: map?['code']?.toString(),
      name: map?['name']?.toString(),
      address: map?['address']?.toString(),
      latitude: _asDouble(map?['latitude']),
      longitude: _asDouble(map?['longitude']),
    );
  }

  static List<DroneJourneyEvent> _events(dynamic value) {
    if (value is! List) return const [];
    final events = value.whereType<Map>().map((raw) {
      final map = Map<String, dynamic>.from(raw);
      return DroneJourneyEvent(
        id: _asInt(map['id']),
        fromStage: map['fromStage']?.toString(),
        toStage: map['toStage']?.toString() ?? 'UNKNOWN',
        actorUserId: _asInt(map['actorUserId']),
        actorName: _text(map['actorName']),
        note: map['note']?.toString(),
        occurredAt: parseServerDateTime(map['occurredAt']),
      );
    }).toList();
    events.sort((a, b) {
      final aa = a.occurredAt;
      final bb = b.occurredAt;
      if (aa == null && bb == null) return 0;
      if (aa == null) return 1;
      if (bb == null) return -1;
      return bb.compareTo(aa);
    });
    return events;
  }
}
