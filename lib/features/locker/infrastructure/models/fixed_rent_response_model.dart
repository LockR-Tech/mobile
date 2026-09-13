import 'package:smart_laundry_locker/features/locker/domain/entities/fixed_rent_entity.dart';

class FixedRentResponseModel {
  final FixedRentEntity entity;

  const FixedRentResponseModel(this.entity);

  factory FixedRentResponseModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    DateTime? parseDate(dynamic value) {
      if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
      return null;
    }

    final order = (json['order'] as Map?)?.cast<String, dynamic>() ?? {};
    final detail = (json['orderDetail'] as Map?)?.cast<String, dynamic>() ?? {};
    final locker = (json['locker'] as Map?)?.cast<String, dynamic>() ?? {};
    final pricing = (json['pricing'] as Map?)?.cast<String, dynamic>() ?? {};
    final accessCodeRaw =
        (json['accessCode'] as Map?)?.cast<String, dynamic>() ??
        (detail['accessCode'] as Map?)?.cast<String, dynamic>() ??
        {};

    return FixedRentResponseModel(
      FixedRentEntity(
        order: FixedRentOrderEntity(
          id: (order['id'] ?? '').toString(),
          orderCode: (order['orderCode'] ?? '').toString(),
          status: (order['status'] ?? '').toString(),
        ),
        orderDetail: FixedRentOrderDetailEntity(
          id: (detail['id'] ?? '').toString(),
          lockerId: (detail['lockerId'] ?? '').toString(),
          rentMonths: parseInt(detail['rentMonths']),
          rentStartDate: parseDate(detail['rentStartDate']),
          rentEndDate: parseDate(detail['rentEndDate']),
          status: (detail['status'] ?? '').toString(),
        ),
        locker: FixedRentLockerEntity(
          id: (locker['id'] ?? '').toString(),
          status: (locker['status'] ?? '').toString(),
          hwState: locker['hwState']?.toString(),
        ),
        pricing: FixedRentPricingEntity(
          id: (pricing['id'] ?? '').toString(),
          name: (pricing['name'] ?? '').toString(),
          feePerBlock: parseInt(pricing['feePerBlock']),
        ),
        accessCode: AccessCodeEntity(
          id: (accessCodeRaw['id'] ?? '').toString(),
          code: (accessCodeRaw['code'] ?? '').toString(),
          status: (accessCodeRaw['status'] ?? '').toString(),
        ),
      ),
    );
  }
}
