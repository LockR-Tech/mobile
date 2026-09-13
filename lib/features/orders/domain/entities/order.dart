import 'package:equatable/equatable.dart';

class Order extends Equatable {
  final String id;
  final String orderCode;
  final String? rentalCabinetId;
  final String? originCabinetId;
  final String? destinationCabinetId;
  final String userId;
  final String orderType; // 'LOGISTICS', 'PERSONAL_RENTAL'
  final double currentRate;
  final double accumulatedFee;
  final double totalCollected;
  final DateTime? lastBillingAt;
  final String status; // OrderStatus enum
  final String? paymentStatus; // PaymentStatus enum
  final String? transactionId;
  final DateTime? closedAt;
  final DateTime? plannedEndTime;
  final bool isPrepaid;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? dispatchId;
  final double? rentalUnitPrice;
  final double? shippingUnitPrice;
  final String? logisticsType;
  final String? pickupAddress;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final int totalTimeRent;
  final String? voucherId;
  final String? voucherName;

  const Order({
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

  /// Kiểm tra đây có phải order thuê tủ cá nhân không
  bool get isPersonalRental => orderType == 'PERSONAL_RENTAL';

  /// Kiểm tra đây có phải order logistics không
  bool get isLogistics => orderType == 'LOGISTICS';

  /// Kiểm tra đơn hàng đang active (chưa kết thúc)
  bool get isActive =>
      status == 'ACTIVE' ||
      status == 'PENDING' ||
      status == 'AWAITING_COURIER' ||
      status == 'AWAITING_PICKUP';

  @override
  List<Object?> get props => [
    id,
    orderCode,
    status,
    orderType,
    dispatchId,
    totalTimeRent,
    pickupLatitude,
    pickupLongitude,
    voucherId,
    voucherName,
  ];
}
