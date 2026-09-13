import 'package:equatable/equatable.dart';

/// OrderDetail entity - chi tiết đơn hàng
/// Matches API OrderDetailResponse schema exactly.
class OrderDetail extends Equatable {
  final String id;
  final String code;
  final String orderId;
  final String? lockerId;
  final String? lockerLabel;
  final String? renterId;
  final String? senderId;
  final String? delegateeId;
  final String? hwStatus;
  final double overdueFee;
  final String status; // OrderDetailStatus enum
  final String? receiverName;

  /// Có thể chứa SĐT người nhận tùy backend.
  final String? receiverEmail;
  final String? receiverPhone;
  final String? receiverAddress;
  final double? receiverLatitude;
  final double? receiverLongitude;
  final String? accessCode;
  final String? cabinetName;
  final String? cabinetAddress;
  final String? note;
  final String? itemType; // 'FOOD', 'OTHER'
  final int? rentMonths;
  final DateTime? rentStartDate;
  final DateTime? rentEndDate;
  final bool isFixed;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? courierId;
  final String? receiverId;
  final DateTime? pickedUpAt;
  final int? row;
  final int? column;
  final String? pickupAddress;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final String? logisticsType;
  final String? locationSendId;
  final String? locationSendName;
  final double? locationSendLatitude;
  final double? locationSendLongitude;
  final List<String> imageUrls;

  const OrderDetail({
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

  @override
  List<Object?> get props => [
    id,
    code,
    orderId,
    lockerId,
    lockerLabel,
    renterId,
    senderId,
    delegateeId,
    overdueFee,
    status,
    receiverName,
    receiverEmail,
    note,
    rentMonths,
    rentStartDate,
    rentEndDate,
    isFixed,
    createdAt,
    updatedAt,
    hwStatus,
    courierId,
    accessCode,
    receiverPhone,
    receiverAddress,
    receiverLatitude,
    receiverLongitude,
    pickedUpAt,
    receiverId,
    row,
    column,
    itemType,
    logisticsType,
    pickupAddress,
    pickupLatitude,
    pickupLongitude,
    locationSendId,
    locationSendName,
    locationSendLatitude,
    locationSendLongitude,
    imageUrls,
  ];

  String get formattedPosition {
    if (row == null || column == null) return 'N/A';
    return '${row}x$column';
  }

  String get formattedLockerLabel {
    if (lockerLabel != null && lockerLabel!.isNotEmpty) {
      final normalized = lockerLabel!.trim();
      final compact = normalized.replaceAll(' ', '');

      final alphaNumeric = RegExp(r'^([A-Za-z])(\d+)$').firstMatch(compact);
      if (alphaNumeric != null) {
        final rowChar = alphaNumeric.group(1)!.toUpperCase();
        final columnNum = int.tryParse(alphaNumeric.group(2)!);
        final rowNum = rowChar.codeUnitAt(0) - 'A'.codeUnitAt(0) + 1;
        if (rowNum > 0 && columnNum != null && columnNum > 0) {
          return '${rowNum}x$columnNum';
        }
      }

      final parts = compact.split('x');
      if (parts.length == 2) {
        final rowNum = int.tryParse(parts[0]);
        final colNum = int.tryParse(parts[1]);
        if (rowNum != null && colNum != null && rowNum > 0 && colNum > 0) {
          return '${rowNum}x$colNum';
        }
      }
      return normalized;
    }
    return formattedPosition;
  }
}
