import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/profile/domain/entities/loyalty.dart';

void main() {
  test('đọc tài khoản điểm và nhãn hạng', () {
    final s = LoyaltySummary.fromJson({
      'id': 1,
      'userId': 7,
      'points': 620,
      'stamps': 2,
      'tier': 'silver',
    });
    expect(s.points, 620);
    expect(s.tier, 'SILVER');
    expect(s.tierLabel, 'Bạc');
    expect(loyaltyTierLabel('PLATINUM'), 'Bạch kim');
    expect(loyaltyTierLabel('BRONZE'), 'Đồng');
  });

  test('lịch sử điểm: nhãn loại và chiều cộng/trừ', () {
    final earn = PointTransaction.fromJson({
      'id': 3,
      'orderId': 42,
      'points': 85,
      'type': 'ORDER_EARN',
      'createdAt': '2026-10-12T02:00:00',
    });
    final redeem = PointTransaction.fromJson({
      'id': 4,
      'points': -50,
      'type': 'REDEEM',
    });
    expect(earn.isCredit, isTrue);
    expect(earn.typeLabel, 'Tích điểm đơn hàng #42');
    expect(earn.createdAt, DateTime.utc(2026, 10, 12, 2).toLocal());
    expect(redeem.isCredit, isFalse);
    expect(redeem.typeLabel, 'Đổi điểm');
    expect(pointTransactionLabel('ADJUSTMENT'), 'Điều chỉnh điểm');
  });

  test('hạng kế tiếp theo ngưỡng cấu hình', () {
    final next = nextLoyaltyTier(
      620,
      silverPoints: 500,
      goldPoints: 2000,
      platinumPoints: 5000,
    );
    expect(next, isNotNull);
    expect(next!.name, 'Vàng');
    expect(next.missing, 1380);
    expect(
      nextLoyaltyTier(5000, silverPoints: 500, goldPoints: 2000, platinumPoints: 5000),
      isNull,
    );
  });
}
