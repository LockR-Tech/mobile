class PlanPricingUIModel {
  final String id;
  final String name;
  final int blockDuration;
  final String blockUnit;
  final int feePerBlockVnd;
  final int lateFeePerBlockVnd;
  final String orderType;
  final String? description;
  final int gracePeriod;

  const PlanPricingUIModel({
    required this.id,
    required this.name,
    required this.blockDuration,
    required this.blockUnit,
    required this.feePerBlockVnd,
    required this.lateFeePerBlockVnd,
    required this.orderType,
    this.description,
    required this.gracePeriod,
  });
}

class PlanUIModel {
  final String id;
  final String name;
  final int maxLockers;
  final int priceVnd;
  final int fixedLocker;
  final int discountLockerRental;
  final int discountFixedLockerRental;
  final String? description;
  final String status;
  final bool isFreeDefault;
  final List<PlanPricingUIModel> pricings;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PlanUIModel({
    required this.id,
    required this.name,
    required this.maxLockers,
    required this.priceVnd,
    required this.fixedLocker,
    required this.discountLockerRental,
    required this.discountFixedLockerRental,
    this.description,
    required this.status,
    required this.isFreeDefault,
    this.pricings = const [],
    this.createdAt,
    this.updatedAt,
  });
}
