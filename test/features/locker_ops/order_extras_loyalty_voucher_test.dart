import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/core/config/business_config.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/order_extras.dart';
import 'package:smart_laundry_locker/features/promotions/data/models/promotion_model.dart';

void main() {
  final config = BusinessConfig.fromPublicMaps(
    loyalty: {
      'app.loyalty.tier-silver-points': 300,
      'app.loyalty.tier-gold-points': 1000,
      'app.loyalty.tier-platinum-points': 4000,
    },
  );

  group('loyaltyHintText', () {
    test('điểm thật + hạng + điểm còn thiếu lên hạng kế', () {
      expect(
        loyaltyHintText(120, 'Đồng', config),
        'Bạn đang có 120 điểm · hạng Đồng · còn 180 điểm lên hạng Bạc',
      );
    });

    test('hạng cao nhất', () {
      expect(
        loyaltyHintText(5000, 'Bạch kim', config),
        'Bạn đang có 5000 điểm · hạng Bạch kim · hạng cao nhất',
      );
    });

    test('thiếu nhãn hạng thì bỏ phần hạng', () {
      expect(
        loyaltyHintText(0, null, config),
        'Bạn đang có 0 điểm · còn 300 điểm lên hạng Bạc',
      );
    });

    test('nhãn hạng: ưu tiên tierLabel, không có thì đổi từ mã', () {
      expect(loyaltyTierLabel(tierLabel: 'Vàng', tier: 'SILVER'), 'Vàng');
      expect(loyaltyTierLabel(tier: 'platinum'), 'Bạch kim');
      expect(loyaltyTierLabel(), isNull);
    });
  });

  group('voucher đã lưu trong bộ chọn mã', () {
    test('chỉ lấy voucher SAVED/UNUSED, bỏ USED/EXPIRED', () {
      final saved = usableSavedVouchers([
        {'id': 1, 'code': 'GIAM10', 'name': 'Giảm 10%', 'status': 'SAVED'},
        {'id': 2, 'code': 'DUNGROI', 'name': 'x', 'status': 'USED'},
        {'id': 3, 'code': 'HETHAN', 'name': 'x', 'status': 'EXPIRED'},
        {'id': 4, 'code': 'MOI', 'name': 'x', 'status': 'UNUSED'},
      ]);
      expect(saved.map((p) => p.code), ['GIAM10', 'MOI']);
    });

    test(
      'gộp với khuyến mãi đang chạy, voucher đã lưu lên trước, bỏ trùng mã',
      () {
        PromotionModel p(String code) =>
            PromotionModel.fromJson({'id': 1, 'code': code, 'name': code});
        final merged = mergeVoucherOptions(
          [p('GIAM10')],
          [p('giam10'), p('FREESHIP')],
        );
        expect(merged.map((e) => e.code), ['GIAM10', 'FREESHIP']);
      },
    );
  });
}
