import 'package:smart_laundry_locker/core/utils/app_date_time.dart';
import 'package:smart_laundry_locker/features/promotions/data/models/promotion_model.dart';

/// Voucher đổi bằng điểm (`GET /api/promotions/exchangeable`): mọi field của
/// khuyến mãi + `pointsCost` (giá bằng điểm) + `held` (đang giữ voucher này
/// chưa dùng — dùng xong mới đổi tiếp được).
class ExchangeableVoucherModel {
  const ExchangeableVoucherModel({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    required this.discountType,
    required this.discountValue,
    this.maxDiscountAmount,
    this.minOrderAmount,
    required this.pointsCost,
    required this.held,
    this.endAt,
    this.lockerId,
    this.lockerCode,
    this.lockerName,
  });

  final int id;
  final String code;
  final String name;
  final String? description;
  final String discountType;
  final double discountValue;
  final double? maxDiscountAmount;
  final double? minOrderAmount;
  final int pointsCost;
  final bool held;
  final DateTime? endAt;
  final int? lockerId;
  final String? lockerCode;
  final String? lockerName;

  bool get isPercentage => discountType.toUpperCase() == 'PERCENTAGE';

  /// `Áp dụng tại: Tủ A` hoặc `Toàn hệ thống`.
  String get scopeLabel => promotionScopeLabel(
    lockerId: lockerId,
    lockerName: lockerName,
    lockerCode: lockerCode,
  );

  factory ExchangeableVoucherModel.fromJson(Map<String, dynamic> json) {
    double? asDouble(dynamic raw) =>
        raw == null ? null : double.tryParse(raw.toString());
    int asInt(dynamic raw) =>
        raw is num ? raw.toInt() : int.tryParse('${raw ?? ''}') ?? 0;
    return ExchangeableVoucherModel(
      id: asInt(json['id']),
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      discountType: json['discountType']?.toString() ?? 'FIXED_AMOUNT',
      discountValue: asDouble(json['discountValue']) ?? 0,
      maxDiscountAmount: asDouble(json['maxDiscountAmount']),
      minOrderAmount: asDouble(json['minOrderAmount']),
      pointsCost: asInt(json['pointsCost']),
      held: json['held'] == true,
      endAt: parseServerDateTime(json['endAt']),
      lockerId: promotionLockerId(json['lockerId']),
      lockerCode: json['lockerCode']?.toString(),
      lockerName: json['lockerName']?.toString(),
    );
  }
}

/// Kết quả một lần đổi (`POST /api/promotions/{id}/exchange`).
class VoucherExchangeOutcome {
  const VoucherExchangeOutcome({
    required this.pointsSpent,
    required this.balance,
  });

  final int pointsSpent;
  final int balance;

  factory VoucherExchangeOutcome.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic raw) =>
        raw is num ? raw.toInt() : int.tryParse('${raw ?? ''}') ?? 0;
    return VoucherExchangeOutcome(
      pointsSpent: asInt(json['pointsSpent']),
      balance: asInt(json['balance']),
    );
  }
}
