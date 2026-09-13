// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drone_delivery_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DroneDeliveryResponse _$DroneDeliveryResponseFromJson(
  Map<String, dynamic> json,
) => DroneDeliveryResponse(
  status: json['status'] as String,
  deliveryId: json['deliveryId'] as String?,
  orderId: json['orderId'] as String?,
  orderCode: json['orderCode'] as String?,
  droneCode: json['droneCode'] as String?,
  etaMinutes: (json['etaMinutes'] as num?)?.toInt(),
  updatedAt: json['updatedAt'] as String?,
);

Map<String, dynamic> _$DroneDeliveryResponseToJson(
  DroneDeliveryResponse instance,
) => <String, dynamic>{
  'status': instance.status,
  'deliveryId': instance.deliveryId,
  'orderId': instance.orderId,
  'orderCode': instance.orderCode,
  'droneCode': instance.droneCode,
  'etaMinutes': instance.etaMinutes,
  'updatedAt': instance.updatedAt,
};
