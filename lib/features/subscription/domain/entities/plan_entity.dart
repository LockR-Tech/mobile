class PricingEntity {
  final String id;
  final String name;
  final int blockDuration;
  final String blockUnit;
  final int feePerBlock;
  final int lateFeePerBlock;
  final String orderType;
  final String? description;
  final int gracePeriod;

  const PricingEntity({
    required this.id,
    required this.name,
    required this.blockDuration,
    required this.blockUnit,
    required this.feePerBlock,
    required this.lateFeePerBlock,
    required this.orderType,
    this.description,
    required this.gracePeriod,
  });
}

class PlanEntity {
  final String id;
  final String name;
  final int price;
  final String? description;
  final int maxLockers;
  final int discountLockerRental;
  final int fixedLocker;
  final int discountFixedLockerRental;
  final String status;
  final bool isFreeDefault;
  final List<PricingEntity> pricings;

  const PlanEntity({
    required this.id,
    required this.name,
    required this.price,
    this.description,
    required this.maxLockers,
    required this.discountLockerRental,
    required this.fixedLocker,
    required this.discountFixedLockerRental,
    required this.status,
    required this.isFreeDefault,
    this.pricings = const [],
  });
}
