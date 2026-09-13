// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_detail_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderDetailModel _$OrderDetailModelFromJson(
  Map<String, dynamic> json,
) => OrderDetailModel(
  id: _readId(json, 'id') as String? ?? '',
  code: json['code'] as String? ?? '',
  orderId: _readOrderId(json, 'orderId') as String? ?? '',
  lockerId: _readLockerId(json, 'lockerId') as String?,
  lockerLabel: _readLockerLabel(json, 'lockerLabel') as String?,
  renterId: _readRenterId(json, 'renterId') as String?,
  senderId: _readSenderId(json, 'senderId') as String?,
  delegateeId: _readDelegateeId(json, 'delegateeId') as String?,
  hwStatus: json['hwStatus'] as String?,
  overdueFee: _parseDouble(_readOverdueFee(json, 'overdueFee')),
  status: json['status'] as String? ?? '',
  receiverName: _readReceiverName(json, 'receiverName') as String?,
  receiverEmail: _readReceiverEmail(json, 'receiverEmail') as String?,
  receiverPhone: _readReceiverPhone(json, 'receiverPhone') as String?,
  receiverAddress: _readReceiverAddress(json, 'receiverAddress') as String?,
  receiverLatitude: _parseDouble(
    _readReceiverLatitude(json, 'receiverLatitude'),
  ),
  receiverLongitude: _parseDouble(
    _readReceiverLongitude(json, 'receiverLongitude'),
  ),
  accessCode: _readAccessCode(json, 'accessCode'),
  cabinetName: _readCabinetName(json, 'cabinetName') as String?,
  cabinetAddress: _readCabinetAddress(json, 'cabinetAddress') as String?,
  note: json['note'] as String?,
  itemType: _readItemType(json, 'itemType') as String?,
  rentMonths: (_readRentMonths(json, 'rentMonths') as num?)?.toInt(),
  rentStartDate: _parseDateTimeNullable(
    _readRentStartDate(json, 'rentStartDate'),
  ),
  rentEndDate: _parseDateTimeNullable(_readRentEndDate(json, 'rentEndDate')),
  isFixed: _readIsFixed(json, 'isFixed') as bool? ?? false,
  createdAt: _parseDateTime(_readCreatedAt(json, 'createdAt')),
  updatedAt: _parseDateTimeNullable(_readUpdatedAt(json, 'updatedAt')),
  courierId: _readCourierId(json, 'courierId') as String?,
  receiverId: _readReceiverId(json, 'receiverId') as String?,
  pickedUpAt: _parseDateTimeNullable(_readPickedUpAt(json, 'pickedUpAt')),
  row: (_readRow(json, 'row') as num?)?.toInt(),
  column: (_readColumn(json, 'column') as num?)?.toInt(),
  pickupAddress: _readPickupAddress(json, 'pickupAddress') as String?,
  pickupLatitude: _parseDouble(_readPickupLatitude(json, 'pickupLatitude')),
  pickupLongitude: _parseDouble(_readPickupLongitude(json, 'pickupLongitude')),
  logisticsType: _readLogisticsType(json, 'logisticsType') as String?,
  locationSendId: _readLocationSendId(json, 'locationSendId') as String?,
  locationSendName: _readLocationSendName(json, 'locationSendName') as String?,
  locationSendLatitude: _parseDouble(
    _readLocationSendLatitude(json, 'locationSendLatitude'),
  ),
  locationSendLongitude: _parseDouble(
    _readLocationSendLongitude(json, 'locationSendLongitude'),
  ),
  imageUrls:
      (_readImageUrls(json, 'imageUrls') as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
);

Map<String, dynamic> _$OrderDetailModelToJson(OrderDetailModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'orderId': instance.orderId,
      'lockerId': instance.lockerId,
      'lockerLabel': instance.lockerLabel,
      'renterId': instance.renterId,
      'senderId': instance.senderId,
      'delegateeId': instance.delegateeId,
      'hwStatus': instance.hwStatus,
      'overdueFee': instance.overdueFee,
      'status': instance.status,
      'receiverName': instance.receiverName,
      'receiverEmail': instance.receiverEmail,
      'receiverPhone': instance.receiverPhone,
      'receiverAddress': instance.receiverAddress,
      'receiverLatitude': instance.receiverLatitude,
      'receiverLongitude': instance.receiverLongitude,
      'accessCode': instance.accessCode,
      'cabinetName': instance.cabinetName,
      'cabinetAddress': instance.cabinetAddress,
      'note': instance.note,
      'itemType': instance.itemType,
      'rentMonths': instance.rentMonths,
      'rentStartDate': instance.rentStartDate?.toIso8601String(),
      'rentEndDate': instance.rentEndDate?.toIso8601String(),
      'isFixed': instance.isFixed,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'courierId': instance.courierId,
      'pickedUpAt': instance.pickedUpAt?.toIso8601String(),
      'receiverId': instance.receiverId,
      'row': instance.row,
      'column': instance.column,
      'pickupAddress': instance.pickupAddress,
      'pickupLatitude': instance.pickupLatitude,
      'pickupLongitude': instance.pickupLongitude,
      'logisticsType': instance.logisticsType,
      'locationSendId': instance.locationSendId,
      'locationSendName': instance.locationSendName,
      'locationSendLatitude': instance.locationSendLatitude,
      'locationSendLongitude': instance.locationSendLongitude,
      'imageUrls': instance.imageUrls,
    };
