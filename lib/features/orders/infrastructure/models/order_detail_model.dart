import 'package:smart_laundry_locker/features/orders/domain/entities/order_detail.dart';
import 'package:json_annotation/json_annotation.dart';

part 'order_detail_model.g.dart';

Object? _readId(Map json, String key) => json['id'] ?? json['_id'];

// Robust readers for bidirectional casing support (camelCase/snake_case)
Object? _readOrderId(Map<dynamic, dynamic> json, String key) =>
    json['orderId'] ?? json['order_id'];
Object? _readLockerId(Map<dynamic, dynamic> json, String key) =>
    json['lockerId'] ?? json['locker_id'];
Object? _readLockerLabel(Map<dynamic, dynamic> json, String key) =>
    json['lockerLabel'] ?? json['locker_label'];
Object? _readRenterId(Map<dynamic, dynamic> json, String key) =>
    json['renterId'] ?? json['renter_id'];
Object? _readSenderId(Map<dynamic, dynamic> json, String key) =>
    json['senderId'] ?? json['sender_id'];
Object? _readDelegateeId(Map<dynamic, dynamic> json, String key) =>
    json['delegateeId'] ?? json['delegatee_id'];
Object? _readOverdueFee(Map<dynamic, dynamic> json, String key) =>
    json['overdueFee'] ?? json['overdue_fee'];
Object? _readReceiverName(Map<dynamic, dynamic> json, String key) =>
    json['receiverName'] ?? json['receiver_name'];
Object? _readReceiverEmail(Map<dynamic, dynamic> json, String key) =>
    json['receiverEmail'] ?? json['receiver_email'];
Object? _readReceiverPhone(Map<dynamic, dynamic> json, String key) =>
    json['receiverPhone'] ?? json['receiver_phone'];
Object? _readReceiverAddress(Map<dynamic, dynamic> json, String key) =>
    json['receiverAddress'] ?? json['receiver_address'];
Object? _readReceiverLatitude(Map<dynamic, dynamic> json, String key) =>
    json['receiverLatitude'] ?? json['receiver_latitude'];
Object? _readReceiverLongitude(Map<dynamic, dynamic> json, String key) =>
    json['receiverLongitude'] ?? json['receiver_longitude'];
Object? _readAccessCode(Map<dynamic, dynamic> json, String key) =>
    json['accessCode'] ?? json['access_code'];
Object? _readCabinetName(Map<dynamic, dynamic> json, String key) =>
    json['cabinetName'] ?? json['cabinet_name'];
Object? _readCabinetAddress(Map<dynamic, dynamic> json, String key) =>
    json['cabinetAddress'] ?? json['cabinet_address'];
Object? _readItemType(Map<dynamic, dynamic> json, String key) =>
    json['itemType'] ?? json['item_type'];
Object? _readRentMonths(Map<dynamic, dynamic> json, String key) =>
    json['rentMonths'] ?? json['rent_months'];
Object? _readRentStartDate(Map<dynamic, dynamic> json, String key) =>
    json['rentStartDate'] ?? json['rent_start_date'];
Object? _readRentEndDate(Map<dynamic, dynamic> json, String key) =>
    json['rentEndDate'] ?? json['rent_end_date'];
Object? _readIsFixed(Map<dynamic, dynamic> json, String key) =>
    json['isFixed'] ?? json['is_fixed'];
Object? _readCreatedAt(Map<dynamic, dynamic> json, String key) =>
    json['createdAt'] ?? json['created_at'];
Object? _readUpdatedAt(Map<dynamic, dynamic> json, String key) =>
    json['updatedAt'] ?? json['updated_at'];
Object? _readCourierId(Map<dynamic, dynamic> json, String key) =>
    json['courierId'] ?? json['courier_id'];
Object? _readPickedUpAt(Map<dynamic, dynamic> json, String key) =>
    json['pickedUpAt'] ?? json['picked_up_at'];
Object? _readReceiverId(Map<dynamic, dynamic> json, String key) =>
    json['receiverId'] ?? json['receiver_id'];
Object? _readRow(Map<dynamic, dynamic> json, String key) =>
    json['row'] ?? json['row'];
Object? _readColumn(Map<dynamic, dynamic> json, String key) =>
    json['column'] ?? json['column'];
Object? _readPickupAddress(Map<dynamic, dynamic> json, String key) =>
    json['pickupAddress'] ?? json['pickup_address'];
Object? _readPickupLatitude(Map<dynamic, dynamic> json, String key) =>
    json['pickupLatitude'] ?? json['pickup_latitude'];
Object? _readPickupLongitude(Map<dynamic, dynamic> json, String key) =>
    json['pickupLongitude'] ?? json['pickup_longitude'];
Object? _readLogisticsType(Map<dynamic, dynamic> json, String key) =>
    json['logisticsType'] ?? json['logistics_type'];
Object? _readLocationSendId(Map<dynamic, dynamic> json, String key) =>
    json['locationSendId'] ?? json['location_send_id'];
Object? _readLocationSendName(Map<dynamic, dynamic> json, String key) =>
    json['locationSendName'] ?? json['location_send_name'];
Object? _readLocationSendLatitude(Map<dynamic, dynamic> json, String key) =>
    json['locationSendLatitude'] ?? json['location_send_latitude'];
Object? _readLocationSendLongitude(Map<dynamic, dynamic> json, String key) =>
    json['locationSendLongitude'] ?? json['location_send_longitude'];
Object? _readImageUrls(Map<dynamic, dynamic> json, String key) =>
    json['imageUrls'] ?? json['image_urls'];

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

/// OrderDetailModel - Infrastructure model cho OrderDetail entity
/// Matches API OrderDetailResponse schema exactly.
@JsonSerializable()
class OrderDetailModel {
  @JsonKey(readValue: _readId, defaultValue: '')
  final String id;

  @JsonKey(defaultValue: '')
  final String code;

  @JsonKey(readValue: _readOrderId, defaultValue: '')
  final String orderId;

  @JsonKey(readValue: _readLockerId)
  final String? lockerId;

  @JsonKey(readValue: _readLockerLabel)
  final String? lockerLabel;

  @JsonKey(readValue: _readRenterId)
  final String? renterId;

  @JsonKey(readValue: _readSenderId)
  final String? senderId;

  @JsonKey(readValue: _readDelegateeId)
  final String? delegateeId;

  final String? hwStatus;

  @JsonKey(readValue: _readOverdueFee, fromJson: _parseDouble)
  final double overdueFee;

  @JsonKey(defaultValue: '')
  final String status;

  @JsonKey(readValue: _readReceiverName)
  final String? receiverName;

  @JsonKey(readValue: _readReceiverEmail)
  final String? receiverEmail;

  @JsonKey(readValue: _readReceiverPhone)
  final String? receiverPhone;

  @JsonKey(readValue: _readReceiverAddress)
  final String? receiverAddress;

  @JsonKey(readValue: _readReceiverLatitude, fromJson: _parseDouble)
  final double? receiverLatitude;

  @JsonKey(readValue: _readReceiverLongitude, fromJson: _parseDouble)
  final double? receiverLongitude;

  @JsonKey(readValue: _readAccessCode)
  final dynamic accessCode;

  @JsonKey(readValue: _readCabinetName)
  final String? cabinetName;

  @JsonKey(readValue: _readCabinetAddress)
  final String? cabinetAddress;

  final String? note;

  @JsonKey(readValue: _readItemType)
  final String? itemType;

  @JsonKey(readValue: _readRentMonths)
  final int? rentMonths;

  @JsonKey(readValue: _readRentStartDate, fromJson: _parseDateTimeNullable)
  final DateTime? rentStartDate;

  @JsonKey(readValue: _readRentEndDate, fromJson: _parseDateTimeNullable)
  final DateTime? rentEndDate;

  @JsonKey(readValue: _readIsFixed, defaultValue: false)
  final bool isFixed;

  @JsonKey(readValue: _readCreatedAt, fromJson: _parseDateTime)
  final DateTime createdAt;

  @JsonKey(readValue: _readUpdatedAt, fromJson: _parseDateTimeNullable)
  final DateTime? updatedAt;

  @JsonKey(readValue: _readCourierId)
  final String? courierId;

  @JsonKey(readValue: _readPickedUpAt, fromJson: _parseDateTimeNullable)
  final DateTime? pickedUpAt;

  @JsonKey(readValue: _readReceiverId)
  final String? receiverId;

  @JsonKey(readValue: _readRow)
  final int? row;

  @JsonKey(readValue: _readColumn)
  final int? column;

  @JsonKey(readValue: _readPickupAddress)
  final String? pickupAddress;

  @JsonKey(readValue: _readPickupLatitude, fromJson: _parseDouble)
  final double? pickupLatitude;

  @JsonKey(readValue: _readPickupLongitude, fromJson: _parseDouble)
  final double? pickupLongitude;

  @JsonKey(readValue: _readLogisticsType)
  final String? logisticsType;

  @JsonKey(readValue: _readLocationSendId)
  final String? locationSendId;

  @JsonKey(readValue: _readLocationSendName)
  final String? locationSendName;

  @JsonKey(readValue: _readLocationSendLatitude, fromJson: _parseDouble)
  final double? locationSendLatitude;

  @JsonKey(readValue: _readLocationSendLongitude, fromJson: _parseDouble)
  final double? locationSendLongitude;

  @JsonKey(readValue: _readImageUrls, defaultValue: [])
  final List<String> imageUrls;

  const OrderDetailModel({
    required this.id,
    required this.code,
    required this.orderId,
    this.lockerId,
    this.lockerLabel,
    this.renterId,
    this.senderId,
    this.delegateeId,
    this.hwStatus,
    required this.overdueFee,
    required this.status,
    this.receiverName,
    this.receiverEmail,
    this.receiverPhone,
    this.receiverAddress,
    this.receiverLatitude,
    this.receiverLongitude,
    this.accessCode,
    this.cabinetName,
    this.cabinetAddress,
    this.note,
    this.itemType,
    this.rentMonths,
    this.rentStartDate,
    this.rentEndDate,
    required this.isFixed,
    required this.createdAt,
    this.updatedAt,
    this.courierId,
    this.receiverId,
    this.pickedUpAt,
    this.row,
    this.column,
    this.pickupAddress,
    this.pickupLatitude,
    this.pickupLongitude,
    this.logisticsType,
    this.locationSendId,
    this.locationSendName,
    this.locationSendLatitude,
    this.locationSendLongitude,
    this.imageUrls = const [],
  });

  factory OrderDetailModel.fromJson(Map<String, dynamic> json) =>
      _$OrderDetailModelFromJson(json);

  Map<String, dynamic> toJson() => _$OrderDetailModelToJson(this);

  /// Convert to domain entity
  OrderDetail toDomain() {
    return OrderDetail(
      id: id,
      code: code,
      orderId: orderId,
      lockerId: lockerId,
      lockerLabel: lockerLabel,
      renterId: renterId,
      senderId: senderId,
      delegateeId: delegateeId,
      hwStatus: hwStatus,
      overdueFee: overdueFee,
      status: status,
      receiverName: receiverName,
      receiverEmail: receiverEmail,
      receiverPhone: receiverPhone,
      receiverAddress: receiverAddress,
      receiverLatitude: receiverLatitude,
      receiverLongitude: receiverLongitude,
      accessCode: accessCode is String
          ? accessCode as String?
          : (accessCode is Map)
          ? (accessCode as Map)['code'] as String?
          : null,
      cabinetName: cabinetName,
      cabinetAddress: cabinetAddress,
      note: note,
      itemType: itemType,
      rentMonths: rentMonths,
      rentStartDate: rentStartDate,
      rentEndDate: rentEndDate,
      isFixed: isFixed,
      createdAt: createdAt,
      updatedAt: updatedAt,
      courierId: courierId,
      receiverId: receiverId,
      pickedUpAt: pickedUpAt,
      row: row,
      column: column,
      pickupAddress: pickupAddress,
      pickupLatitude: pickupLatitude,
      pickupLongitude: pickupLongitude,
      logisticsType: logisticsType,
      locationSendId: locationSendId,
      locationSendName: locationSendName,
      locationSendLatitude: locationSendLatitude,
      locationSendLongitude: locationSendLongitude,
      imageUrls: imageUrls,
    );
  }
}
