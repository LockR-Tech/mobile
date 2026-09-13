// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delegation_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DelegationModel _$DelegationModelFromJson(Map<String, dynamic> json) =>
    DelegationModel(
      id: _readId(json, 'id') as String? ?? '',
      orderId: json['orderId'] as String? ?? '',
      orderDetailId: json['orderDetailId'] as String? ?? '',
      delegateeId: json['delegateeId'] as String?,
      validFrom: _parseDateTime(json['validFrom']),
      validTo: _parseDateTime(json['validTo']),
      status: json['status'] as String? ?? '',
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
      accessCode: json['accessCode'] as String?,
      orderDetail: json['orderDetail'] == null
          ? null
          : OrderDetailModel.fromJson(
              json['orderDetail'] as Map<String, dynamic>,
            ),
      usedAt: _parseDateTimeNullable(json['usedAt']),
      expiredAt: _parseDateTimeNullable(json['expiredAt']),
    );

Map<String, dynamic> _$DelegationModelToJson(DelegationModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'orderId': instance.orderId,
      'orderDetailId': instance.orderDetailId,
      'delegateeId': instance.delegateeId,
      'validFrom': instance.validFrom.toIso8601String(),
      'validTo': instance.validTo.toIso8601String(),
      'status': instance.status,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'accessCode': instance.accessCode,
      'orderDetail': instance.orderDetail?.toJson(),
      'usedAt': instance.usedAt?.toIso8601String(),
      'expiredAt': instance.expiredAt?.toIso8601String(),
    };
