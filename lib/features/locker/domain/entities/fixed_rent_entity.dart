class AccessCodeEntity {
  final String id;
  final String code;
  final String status;

  const AccessCodeEntity({
    required this.id,
    required this.code,
    required this.status,
  });
}

class FixedRentOrderEntity {
  final String id;
  final String orderCode;
  final String status;

  const FixedRentOrderEntity({
    required this.id,
    required this.orderCode,
    required this.status,
  });
}

class FixedRentOrderDetailEntity {
  final String id;
  final String lockerId;
  final int rentMonths;
  final DateTime? rentStartDate;
  final DateTime? rentEndDate;
  final String status;

  const FixedRentOrderDetailEntity({
    required this.id,
    required this.lockerId,
    required this.rentMonths,
    required this.rentStartDate,
    required this.rentEndDate,
    required this.status,
  });
}

class FixedRentLockerEntity {
  final String id;
  final String status;
  final String? hwState;

  const FixedRentLockerEntity({
    required this.id,
    required this.status,
    this.hwState,
  });
}

class FixedRentPricingEntity {
  final String id;
  final String name;
  final int feePerBlock;

  const FixedRentPricingEntity({
    required this.id,
    required this.name,
    required this.feePerBlock,
  });
}

class FixedRentEntity {
  final FixedRentOrderEntity order;
  final FixedRentOrderDetailEntity orderDetail;
  final FixedRentLockerEntity locker;
  final FixedRentPricingEntity pricing;
  final AccessCodeEntity accessCode;

  const FixedRentEntity({
    required this.order,
    required this.orderDetail,
    required this.locker,
    required this.pricing,
    required this.accessCode,
  });
}
