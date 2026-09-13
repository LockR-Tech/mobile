import 'package:smart_laundry_locker/features/orders/domain/entities/order.dart';
import 'package:json_annotation/json_annotation.dart';

part 'order_model.g.dart';

Object? _readId(Map<dynamic, dynamic> json, String key) =>
    json['id'] ?? json['_id'];

// Robust readers for bidirectional casing support (camelCase/snake_case)
Object? _readOrderCode(Map<dynamic, dynamic> json, String key) =>
    json['orderCode'] ?? json['order_code'];
Object? _readRentalCabinetId(Map<dynamic, dynamic> json, String key) =>
    json['rentalCabinetId'] ?? json['rental_cabinet_id'];
Object? _readOriginCabinetId(Map<dynamic, dynamic> json, String key) =>
    json['originCabinetId'] ?? json['origin_cabinet_id'];
Object? _readDestinationCabinetId(Map<dynamic, dynamic> json, String key) =>
    json['destinationCabinetId'] ?? json['destination_cabinet_id'];
Object? _readUserId(Map<dynamic, dynamic> json, String key) =>
    json['userId'] ?? json['user_id'];
Object? _readOrderType(Map<dynamic, dynamic> json, String key) =>
    json['orderType'] ?? json['order_type'];
Object? _readCurrentRate(Map<dynamic, dynamic> json, String key) =>
    json['currentRate'] ?? json['current_rate'];
Object? _readAccumulatedFee(Map<dynamic, dynamic> json, String key) =>
    json['accumulatedFee'] ?? json['accumulated_fee'];
Object? _readTotalCollected(Map<dynamic, dynamic> json, String key) =>
    json['totalCollected'] ?? json['total_collected'];
Object? _readLastBillingAt(Map<dynamic, dynamic> json, String key) =>
    json['lastBillingAt'] ?? json['last_billing_at'];
Object? _readPaymentStatus(Map<dynamic, dynamic> json, String key) =>
    json['paymentStatus'] ?? json['payment_status'];
Object? _readTransactionId(Map<dynamic, dynamic> json, String key) =>
    json['transactionId'] ?? json['transaction_id'];
Object? _readClosedAt(Map<dynamic, dynamic> json, String key) =>
    json['closedAt'] ?? json['closed_at'];
Object? _readPlannedEndTime(Map<dynamic, dynamic> json, String key) =>
    json['plannedEndTime'] ?? json['planned_end_time'];
Object? _readIsPrepaid(Map<dynamic, dynamic> json, String key) =>
    json['isPrepaid'] ?? json['is_prepaid'];
Object? _readUpdatedAt(Map<dynamic, dynamic> json, String key) =>
    json['updatedAt'] ?? json['updated_at'];
Object? _readDispatchId(Map<dynamic, dynamic> json, String key) =>
    json['dispatchId'] ?? json['dispatch_id'] ?? json['dispatch'];
Object? _readRentalUnitPrice(Map<dynamic, dynamic> json, String key) =>
    json['rentalUnitPrice'] ?? json['rental_unit_price'];
Object? _readShippingUnitPrice(Map<dynamic, dynamic> json, String key) =>
    json['shippingUnitPrice'] ?? json['shipping_unit_price'];
Object? _readLogisticsType(Map<dynamic, dynamic> json, String key) {
  final val = json['logisticsType'] ?? json['logistics_type'];
  if (val == 0) return 'LOCKER_TO_LOCKER';
  if (val == 1) return 'HOME_TO_LOCKER';
  return val;
}

Object? _readPickupAddress(Map<dynamic, dynamic> json, String key) =>
    json['pickupAddress'] ?? json['pickup_address'];

Object? _readPickupLatitude(Map<dynamic, dynamic> json, String key) =>
    json['pickupLatitude'] ?? json['pickup_latitude'];

Object? _readPickupLongitude(Map<dynamic, dynamic> json, String key) =>
    json['pickupLongitude'] ?? json['pickup_longitude'];

Object? _readTotalTimeRent(Map<dynamic, dynamic> json, String key) =>
    json['totalTimeRent'] ?? json['total_time_rent'];
Object? _readVoucherId(Map<dynamic, dynamic> json, String key) =>
    json['voucherId'] ?? json['voucher_id'];
Object? _readVoucherName(Map<dynamic, dynamic> json, String key) =>
    json['voucherName'] ?? json['voucher_name'];

double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

DateTime? _parseDateTimeNullable(dynamic value) {
  if (value == null) return null;
  if (value is String) return DateTime.tryParse(value)?.toLocal();
  return null;
}

DateTime _parseDateTime(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is String) {
    return DateTime.tryParse(value)?.toLocal() ?? DateTime.now();
  }
  return DateTime.now();
}

/// OrderModel - Infrastructure model cho Order entity
/// Matches API OrderResponse schema exactly.
@JsonSerializable()
class OrderModel {
  @JsonKey(readValue: _readId, defaultValue: '')
  final String id;

  @JsonKey(readValue: _readOrderCode, defaultValue: '')
  final String orderCode;

  @JsonKey(readValue: _readRentalCabinetId)
  final String? rentalCabinetId;

  @JsonKey(readValue: _readOriginCabinetId)
  final String? originCabinetId;

  @JsonKey(readValue: _readDestinationCabinetId)
  final String? destinationCabinetId;

  @JsonKey(readValue: _readUserId, defaultValue: '')
  final String userId;

  @JsonKey(readValue: _readOrderType, defaultValue: '')
  final String orderType;

  @JsonKey(readValue: _readCurrentRate, fromJson: _parseDouble)
  final double currentRate;

  @JsonKey(readValue: _readAccumulatedFee, fromJson: _parseDouble)
  final double accumulatedFee;

  @JsonKey(readValue: _readTotalCollected, fromJson: _parseDouble)
  final double totalCollected;

  @JsonKey(readValue: _readLastBillingAt, fromJson: _parseDateTimeNullable)
  final DateTime? lastBillingAt;

  @JsonKey(defaultValue: '')
  final String status;

  @JsonKey(readValue: _readPaymentStatus)
  final String? paymentStatus;

  @JsonKey(readValue: _readTransactionId)
  final String? transactionId;

  @JsonKey(readValue: _readClosedAt, fromJson: _parseDateTimeNullable)
  final DateTime? closedAt;

  @JsonKey(readValue: _readPlannedEndTime, fromJson: _parseDateTimeNullable)
  final DateTime? plannedEndTime;

  @JsonKey(readValue: _readIsPrepaid, defaultValue: false)
  final bool isPrepaid;

  @JsonKey(fromJson: _parseDateTime)
  final DateTime createdAt;

  @JsonKey(readValue: _readUpdatedAt, fromJson: _parseDateTimeNullable)
  final DateTime? updatedAt;

  @JsonKey(readValue: _readDispatchId)
  final String? dispatchId;

  @JsonKey(readValue: _readRentalUnitPrice, fromJson: _parseDouble)
  final double? rentalUnitPrice;

  @JsonKey(readValue: _readShippingUnitPrice, fromJson: _parseDouble)
  final double? shippingUnitPrice;

  @JsonKey(readValue: _readLogisticsType)
  final String? logisticsType;

  @JsonKey(readValue: _readPickupAddress)
  final String? pickupAddress;

  @JsonKey(readValue: _readPickupLatitude, fromJson: _parseDouble)
  final double? pickupLatitude;

  @JsonKey(readValue: _readPickupLongitude, fromJson: _parseDouble)
  final double? pickupLongitude;

  @JsonKey(readValue: _readTotalTimeRent, defaultValue: 0)
  final int totalTimeRent;
  @JsonKey(readValue: _readVoucherId)
  final String? voucherId;
  @JsonKey(readValue: _readVoucherName)
  final String? voucherName;

  const OrderModel({
    required this.id,
    required this.orderCode,
    this.rentalCabinetId,
    this.originCabinetId,
    this.destinationCabinetId,
    required this.userId,
    required this.orderType,
    required this.currentRate,
    required this.accumulatedFee,
    required this.totalCollected,
    this.lastBillingAt,
    required this.status,
    this.paymentStatus,
    this.transactionId,
    this.closedAt,
    this.plannedEndTime,
    required this.isPrepaid,
    required this.createdAt,
    this.updatedAt,
    this.dispatchId,
    this.rentalUnitPrice,
    this.shippingUnitPrice,
    this.logisticsType,
    this.pickupAddress,
    this.pickupLatitude,
    this.pickupLongitude,
    this.totalTimeRent = 0,
    this.voucherId,
    this.voucherName,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) =>
      _$OrderModelFromJson(json);

  Map<String, dynamic> toJson() => _$OrderModelToJson(this);

  /// Convert to domain entity
  Order toDomain() {
    return Order(
      id: id,
      orderCode: orderCode,
      rentalCabinetId: rentalCabinetId,
      originCabinetId: originCabinetId,
      destinationCabinetId: destinationCabinetId,
      userId: userId,
      orderType: orderType,
      currentRate: currentRate,
      accumulatedFee: accumulatedFee,
      totalCollected: totalCollected,
      lastBillingAt: lastBillingAt,
      status: status,
      paymentStatus: paymentStatus,
      transactionId: transactionId,
      closedAt: closedAt,
      plannedEndTime: plannedEndTime,
      isPrepaid: isPrepaid,
      createdAt: createdAt,
      updatedAt: updatedAt,
      dispatchId: dispatchId,
      rentalUnitPrice: rentalUnitPrice,
      shippingUnitPrice: shippingUnitPrice,
      logisticsType: logisticsType,
      pickupAddress: pickupAddress,
      pickupLatitude: pickupLatitude,
      pickupLongitude: pickupLongitude,
      totalTimeRent: totalTimeRent,
      voucherId: voucherId,
      voucherName: voucherName,
    );
  }
}
