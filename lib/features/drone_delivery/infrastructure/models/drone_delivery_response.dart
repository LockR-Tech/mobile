import 'package:json_annotation/json_annotation.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_delivery_status.dart';

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

  const DroneDeliveryResponse({
    required this.status,
    this.deliveryId,
    this.orderId,
    this.orderCode,
    this.droneCode,
    this.etaMinutes,
    this.updatedAt,
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
    );
  }

  Map<String, dynamic> toJson() => _$DroneDeliveryResponseToJson(this);

  DroneDeliveryStatus toEntity() => DroneDeliveryStatus(
    status: status,
    deliveryId: deliveryId,
    orderId: orderId,
    orderCode: orderCode,
    droneCode: droneCode,
    etaMinutes: etaMinutes,
    updatedAt: updatedAt == null ? null : DateTime.tryParse(updatedAt!)?.toLocal(),
  );
}
