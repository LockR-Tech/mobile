import 'package:smart_laundry_locker/core/utils/app_date_time.dart';

/// Tài khoản điểm thưởng của chính người dùng (`GET /api/loyalty/summary`,
/// loyalty-service lấy người dùng từ token):
/// `{id, userId, points, lifetimePoints, stamps, tier}`.
class LoyaltySummary {
  /// Điểm hiện có (dùng được để thanh toán).
  final int points;

  /// Tổng điểm đã tích từ trước tới nay — căn cứ xếp hạng; tiêu điểm không
  /// làm giảm số này. `null` với server cũ chưa trả.
  final int? lifetimePoints;
  final int stamps;

  /// `BRONZE | SILVER | GOLD | PLATINUM` — backend tính theo ngưỡng admin cấu
  /// hình (`app.loyalty.tier-*-points`) trên tổng điểm đã tích.
  final String tier;

  const LoyaltySummary({
    required this.points,
    this.lifetimePoints,
    required this.stamps,
    required this.tier,
  });

  factory LoyaltySummary.fromJson(Map<String, dynamic> json) {
    final lifetime = json['lifetimePoints'];
    return LoyaltySummary(
      points: _asInt(json['points']),
      lifetimePoints: lifetime == null ? null : _asInt(lifetime),
      stamps: _asInt(json['stamps']),
      tier: (json['tier'] ?? 'BRONZE').toString().toUpperCase(),
    );
  }

  /// Số điểm dùng để tính hạng: tổng điểm đã tích, server cũ thì điểm hiện có.
  int get tierPoints => lifetimePoints ?? points;

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

  /// Dùng điểm để thanh toán / được hoàn lại khi đơn huỷ.
  bool get isOrderRedemption =>
      type == 'ORDER_REDEEM' || type == 'ORDER_REDEEM_REFUND';

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
  final order = orderId != null ? ' #$orderId' : '';
  switch (type.toUpperCase()) {
    case 'ORDER_EARN':
      return 'Tích điểm đơn hàng$order';
    case 'ORDER_REDEEM':
      return 'Dùng điểm thanh toán đơn$order';
    case 'ORDER_REDEEM_REFUND':
      return 'Hoàn điểm đơn huỷ$order';
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
