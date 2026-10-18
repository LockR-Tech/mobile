import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/core/config/business_config.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/utils/business_rules_text.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/loyalty_redeem_toggle.dart';

LoyaltyRedeemPreview _preview({
  bool enabled = true,
  int balance = 500,
  int minPoints = 10,
  int maxPoints = 75,
  int orderTotal = 15000,
}) => LoyaltyRedeemPreview.fromJson({
  'enabled': enabled,
  'balance': balance,
  'vndPerPoint': 100,
  'maxPercent': 50,
  'minPoints': minPoints,
  'maxPoints': maxPoints,
  'maxDiscount': maxPoints * 100,
}, orderTotal: orderTotal);

void main() {
  group('LoyaltyRedeemPreview', () {
    test('dùng được: câu "Dùng N điểm · giảm X"', () {
      final p = _preview();
      expect(p.usable, isTrue);
      expect(p.unavailableReason, isNull);
      expect(p.offerText, 'Dùng 75 điểm · giảm 7.500đ');
      expect(
        p.ruleText,
        'Bạn có 500 điểm · 1 điểm = 100đ, tối đa 50% giá trị đơn',
      );
    });

    test('lý do không dùng được', () {
      expect(
        _preview(enabled: false, maxPoints: 0).unavailableReason,
        'Hiện chưa áp dụng dùng điểm để thanh toán',
      );
      expect(
        _preview(balance: 0, maxPoints: 0).unavailableReason,
        'Bạn chưa có điểm — điểm được cộng khi đơn hoàn tất',
      );
      expect(
        _preview(balance: 5, maxPoints: 0).unavailableReason,
        'Bạn có 5 điểm, cần tối thiểu 10 điểm mỗi lần dùng',
      );
      expect(
        _preview(maxPoints: 0, orderTotal: 1500).unavailableReason,
        'Đơn chưa đủ giá trị để dùng tối thiểu 10 điểm',
      );
      expect(
        _preview(maxPoints: 0, orderTotal: 0).unavailableReason,
        'Đơn đã được giảm hết, không cần dùng điểm',
      );
    });

    test('ước tính lại theo đúng công thức server khi số tiền đổi', () {
      final p = _preview(balance: 150);
      final bigger = p.estimateFor(40000);
      expect(bigger.maxPoints, 150); // 50% = 200 điểm nhưng chỉ có 150
      expect(bigger.maxDiscount, 15000);
      final smaller = p.estimateFor(10000);
      expect(smaller.maxPoints, 50);
      expect(smaller.maxDiscount, 5000);
      // Dưới số điểm tối thiểu ⇒ 0.
      final tiny = p.estimateFor(1500);
      expect(tiny.maxPoints, 0);
      expect(tiny.usable, isFalse);
    });
  });

  group('kết quả server sau khi tạo đơn', () {
    test('đơn 0đ / PAID ⇒ coi như đã thanh toán', () {
      expect(
        orderFullyCovered({'totalPrice': 0, 'paymentStatus': 'PAID'}),
        isTrue,
      );
      expect(orderFullyCovered({'totalPrice': 0, 'amountDue': 0}), isTrue);
      expect(orderFullyCovered({'totalPrice': 0.0}), isTrue);
      expect(
        orderFullyCovered({'totalPrice': 5000, 'paymentStatus': 'UNPAID'}),
        isFalse,
      );
      // Server cũ không trả tổng tiền ⇒ không đoán.
      expect(orderFullyCovered({'orderId': 1}), isFalse);
    });

    test('bật dùng điểm mà server không trừ điểm nào ⇒ báo khách', () {
      expect(
        loyaltyRedeemSkippedNotice(75, {'pointsUsed': 0}),
        'Chưa dùng được điểm thưởng lúc này — đơn được tính đủ giá.',
      );
      expect(loyaltyRedeemSkippedNotice(75, {'pointsUsed': 75}), isNull);
      expect(loyaltyRedeemSkippedNotice(0, {'pointsUsed': 0}), isNull);
      // Server cũ chưa có `pointsUsed`.
      expect(loyaltyRedeemSkippedNotice(75, {'totalPrice': 1}), isNull);
    });

    test('dòng điểm thưởng', () {
      expect(loyaltyPointsDiscountText(120, 12000), '-12.000đ (120 điểm)');
      expect(orderPointsUsed({'pointsUsed': 120}), 120);
      expect(orderPointsDiscount({'pointsDiscount': '12000.00'}), 12000);
      expect(orderHasDiscounts({'pointsUsed': 0, 'discount': 0}), isFalse);
      expect(orderHasDiscounts({'discount': 5000}), isTrue);
    });

    testWidgets('bảng giá đơn theo số liệu server', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OrderDiscountRows(
              order: {
                'originalPrice': 20000,
                'discount': 5000,
                'promotionCode': 'GIAM5K',
                'pointsUsed': 75,
                'pointsDiscount': 7500,
                'totalPrice': 7500,
              },
            ),
          ),
        ),
      );
      expect(find.text('20.000đ'), findsOneWidget);
      expect(find.text('-5.000đ (GIAM5K)'), findsOneWidget);
      expect(find.text('-7.500đ (75 điểm)'), findsOneWidget);
      expect(find.text('7.500đ'), findsOneWidget);
    });
  });

  test('câu quy tắc tích/dùng điểm theo cấu hình admin', () {
    final config = BusinessConfig.defaults();
    expect(
      loyaltyEarnRuleText(config),
      'Tích 1 điểm cho mỗi 1.000đ bạn thanh toán, cộng khi đơn hoàn tất.',
    );
    expect(
      loyaltyRedeemRuleText(config),
      '1 điểm = 100đ khi thanh toán, dùng tối đa 50% giá trị đơn (từ 10 điểm).',
    );
    expect(
      loyaltyRedeemRuleText(
        BusinessConfig.fromPublicMaps(
          loyalty: {'app.loyalty.redeem-enabled': false},
        ),
      ),
      'Hiện chưa áp dụng dùng điểm để thanh toán.',
    );
  });
}
