import 'package:smart_laundry_locker/features/subscription/domain/entities/plan_entity.dart';

class PricingModel extends PricingEntity {
  const PricingModel({
    required super.id,
    required super.name,
    required super.blockDuration,
    required super.blockUnit,
    required super.feePerBlock,
    required super.lateFeePerBlock,
    required super.orderType,
    super.description,
    required super.gracePeriod,
  });

  factory PricingModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return PricingModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      blockDuration: parseInt(json['blockDuration'] ?? json['block_duration']),
      blockUnit: (json['blockUnit'] ?? json['block_unit'] ?? '').toString(),
      feePerBlock: parseInt(json['feePerBlock'] ?? json['fee_per_block']),
      lateFeePerBlock: parseInt(
        json['lateFeePerBlock'] ?? json['late_fee_per_block'],
      ),
      orderType: (json['orderType'] ?? json['order_type'] ?? '').toString(),
      description: json['description']?.toString(),
      gracePeriod: parseInt(json['gracePeriod'] ?? json['grace_period']),
    );
  }
}

class PlanModel extends PlanEntity {
  const PlanModel({
    required super.id,
    required super.name,
    required super.price,
    super.description,
    required super.maxLockers,
    required super.discountLockerRental,
    required super.fixedLocker,
    required super.discountFixedLockerRental,
    required super.status,
    required super.isFreeDefault,
    super.pricings,
  });

  factory PlanModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    final rawPricings = json['pricings'];
    final pricings = rawPricings is List
        ? rawPricings
              .whereType<Map>()
              .map(
                (item) =>
                    PricingModel.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList()
        : <PricingEntity>[];

    return PlanModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      price: parseInt(json['price']),
      description: json['description']?.toString(),
      maxLockers: parseInt(json['maxLockers'] ?? json['max_lockers']),
      discountLockerRental: parseInt(
        json['discountLockerRental'] ?? json['discount_locker_rental'],
      ),
      fixedLocker: parseInt(json['fixedLocker'] ?? json['fixed_locker']),
      discountFixedLockerRental: parseInt(
        json['discountFixedLockerRental'] ??
            json['discount_fixed_locker_rental'],
      ),
      status: (json['status'] ?? '').toString(),
      isFreeDefault: (json['isFreeDefault'] ?? json['is_free_default']) == true,
      pricings: pricings,
    );
  }
}
