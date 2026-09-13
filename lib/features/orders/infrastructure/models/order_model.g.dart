// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderModel _$OrderModelFromJson(Map<String, dynamic> json) => OrderModel(
  id: _readId(json, 'id') as String? ?? '',
  orderCode: _readOrderCode(json, 'orderCode') as String? ?? '',
  rentalCabinetId: _readRentalCabinetId(json, 'rentalCabinetId') as String?,
  originCabinetId: _readOriginCabinetId(json, 'originCabinetId') as String?,
  destinationCabinetId:
      _readDestinationCabinetId(json, 'destinationCabinetId') as String?,
  userId: _readUserId(json, 'userId') as String? ?? '',
  orderType: _readOrderType(json, 'orderType') as String? ?? '',
  currentRate: _parseDouble(_readCurrentRate(json, 'currentRate')),
  accumulatedFee: _parseDouble(_readAccumulatedFee(json, 'accumulatedFee')),
  totalCollected: _parseDouble(_readTotalCollected(json, 'totalCollected')),
  lastBillingAt: _parseDateTimeNullable(
    _readLastBillingAt(json, 'lastBillingAt'),
  ),
  status: json['status'] as String? ?? '',
  paymentStatus: _readPaymentStatus(json, 'paymentStatus') as String?,
  transactionId: _readTransactionId(json, 'transactionId') as String?,
  closedAt: _parseDateTimeNullable(_readClosedAt(json, 'closedAt')),
  plannedEndTime: _parseDateTimeNullable(
    _readPlannedEndTime(json, 'plannedEndTime'),
  ),
  isPrepaid: _readIsPrepaid(json, 'isPrepaid') as bool? ?? false,
  createdAt: _parseDateTime(json['createdAt']),
  updatedAt: _parseDateTimeNullable(_readUpdatedAt(json, 'updatedAt')),
  dispatchId: _readDispatchId(json, 'dispatchId') as String?,
  rentalUnitPrice: _parseDouble(_readRentalUnitPrice(json, 'rentalUnitPrice')),
  shippingUnitPrice: _parseDouble(
    _readShippingUnitPrice(json, 'shippingUnitPrice'),
  ),
  logisticsType: _readLogisticsType(json, 'logisticsType') as String?,
  pickupAddress: _readPickupAddress(json, 'pickupAddress') as String?,
  pickupLatitude: _parseDouble(_readPickupLatitude(json, 'pickupLatitude')),
  pickupLongitude: _parseDouble(_readPickupLongitude(json, 'pickupLongitude')),
  totalTimeRent:
      (_readTotalTimeRent(json, 'totalTimeRent') as num?)?.toInt() ?? 0,
  voucherId: _readVoucherId(json, 'voucherId') as String?,
  voucherName: _readVoucherName(json, 'voucherName') as String?,
);

Map<String, dynamic> _$OrderModelToJson(OrderModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'orderCode': instance.orderCode,
      'rentalCabinetId': instance.rentalCabinetId,
      'originCabinetId': instance.originCabinetId,
      'destinationCabinetId': instance.destinationCabinetId,
      'userId': instance.userId,
      'orderType': instance.orderType,
      'currentRate': instance.currentRate,
      'accumulatedFee': instance.accumulatedFee,
      'totalCollected': instance.totalCollected,
      'lastBillingAt': instance.lastBillingAt?.toIso8601String(),
      'status': instance.status,
      'paymentStatus': instance.paymentStatus,
      'transactionId': instance.transactionId,
      'closedAt': instance.closedAt?.toIso8601String(),
      'plannedEndTime': instance.plannedEndTime?.toIso8601String(),
      'isPrepaid': instance.isPrepaid,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'dispatchId': instance.dispatchId,
      'rentalUnitPrice': instance.rentalUnitPrice,
      'shippingUnitPrice': instance.shippingUnitPrice,
      'logisticsType': instance.logisticsType,
      'pickupAddress': instance.pickupAddress,
      'pickupLatitude': instance.pickupLatitude,
      'pickupLongitude': instance.pickupLongitude,
      'totalTimeRent': instance.totalTimeRent,
      'voucherId': instance.voucherId,
      'voucherName': instance.voucherName,
    };
