import 'package:smart_laundry_locker/features/orders/domain/entities/order_detail.dart';
import 'package:equatable/equatable.dart';

/// Delegation entity - đại diện cho một bản ghi uỷ quyền trong hệ thống
class Delegation extends Equatable {
  final String id;
  final String orderId;
  final String orderDetailId;
  final String? delegateeId;
  final DateTime validFrom;
  final DateTime validTo;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? accessCode;
  final OrderDetail? orderDetail;
  final DateTime? usedAt;
  final DateTime? expiredAt;

  const Delegation({
    required this.id,
    required this.orderId,
    required this.orderDetailId,
    this.delegateeId,
    required this.validFrom,
    required this.validTo,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.accessCode,
    this.orderDetail,
    this.usedAt,
    this.expiredAt,
  });

  bool get isActive => status == 'ACTIVE';

  @override
  List<Object?> get props => [
    id,
    orderId,
    orderDetailId,
    delegateeId,
    validFrom,
    validTo,
    status,
    createdAt,
    updatedAt,
    accessCode,
    orderDetail,
    usedAt,
    expiredAt,
  ];
}
