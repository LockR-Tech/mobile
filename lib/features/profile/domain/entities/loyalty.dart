import 'package:smart_laundry_locker/core/utils/app_date_time.dart';

/// Tài khoản điểm thưởng của chính người dùng (`GET /api/loyalty/summary`,
/// loyalty-service lấy người dùng từ token): `{id, userId, points, stamps, tier}`.
class LoyaltySummary {
  final int points;
  final int stamps;

  /// `BRONZE | SILVER | GOLD | PLATINUM` — backend tính theo ngưỡng admin cấu
  /// hình (`app.loyalty.tier-*-points`).
  final String tier;

  const LoyaltySummary({
    required this.points,
    required this.stamps,
    required this.tier,
  });

  factory LoyaltySummary.fromJson(Map<String, dynamic> json) {
    return LoyaltySummary(
      points: _asInt(json['points']),
      stamps: _asInt(json['stamps']),
      tier: (json['tier'] ?? 'BRONZE').toString().toUpperCase(),
    );
  }

  String get tierLabel => loyaltyTierLabel(tier);
}

/// Một dòng lịch sử điểm (`GET /api/loyalty/points/history`):
/// `{id, userId, orderId, points, type, createdAt}`. `points` âm = trừ điểm.
class PointTransaction {
  final int id;
  final int? orderId;
  final int points;
  final String type;
  final DateTime? createdAt;

  const PointTransaction({
    required this.id,
    this.orderId,
    required this.points,
    required this.type,
    this.createdAt,
  });

  factory PointTransaction.fromJson(Map<String, dynamic> json) {
    final orderId = json['orderId'];
    return PointTransaction(
      id: _asInt(json['id']),
      orderId: orderId == null ? null : _asInt(orderId),
      points: _asInt(json['points']),
      type: (json['type'] ?? '').toString().toUpperCase(),
      createdAt: parseServerDateTime(json['createdAt']),
    );
  }

  bool get isCredit => points >= 0;

  String get typeLabel => pointTransactionLabel(type, orderId: orderId);
}

String loyaltyTierLabel(String tier) {
  switch (tier.toUpperCase()) {
    case 'SILVER':
      return 'Bạc';
    case 'GOLD':
      return 'Vàng';
    case 'PLATINUM':
      return 'Bạch kim';
    case 'BRONZE':
    default:
      return 'Đồng';
  }
}

String pointTransactionLabel(String type, {int? orderId}) {
  switch (type.toUpperCase()) {
    case 'ORDER_EARN':
      return orderId != null
          ? 'Tích điểm đơn hàng #$orderId'
          : 'Tích điểm đơn hàng';
    case 'REDEEM':
      return 'Đổi điểm';
    case 'ADJUSTMENT':
      return 'Điều chỉnh điểm';
    default:
      return 'Biến động điểm';
  }
}

/// Hạng kế tiếp theo ngưỡng admin cấu hình: `(tên hạng, số điểm còn thiếu)`,
/// `null` khi đã ở hạng cao nhất.
({String name, int missing})? nextLoyaltyTier(
  int points, {
  required int silverPoints,
  required int goldPoints,
  required int platinumPoints,
}) {
  final tiers = [
    (points: silverPoints, name: 'Bạc'),
    (points: goldPoints, name: 'Vàng'),
    (points: platinumPoints, name: 'Bạch kim'),
  ]..sort((a, b) => a.points.compareTo(b.points));
  for (final tier in tiers) {
    if (points < tier.points) {
      return (name: tier.name, missing: tier.points - points);
    }
  }
  return null;
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? 0;
}
