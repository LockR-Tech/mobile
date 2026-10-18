import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/core/config/business_config.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/order_extras.dart';
import 'package:smart_laundry_locker/features/promotions/data/models/promotion_model.dart';
import 'package:smart_laundry_locker/features/vouchers/data/models/voucher_model.dart';

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

    test('hạng kế tiếp tính theo tổng điểm đã tích (tiêu điểm không tụt hạng)', () {
      expect(
        loyaltyHintText(50, 'Bạc', config, lifetimePoints: 900),
        'Bạn đang có 50 điểm · hạng Bạc · còn 100 điểm lên hạng Vàng',
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

    test('bộ chọn mã chỉ giữ mã toàn hệ thống + mã của đúng tủ đang đặt', () {
      final options = [
        PromotionModel.fromJson({'id': 1, 'code': 'TOAN', 'name': 'x'}),
        PromotionModel.fromJson({
          'id': 2,
          'code': 'TU5',
          'name': 'x',
          'lockerId': 5,
          'lockerName': 'Tủ A',
        }),
        PromotionModel.fromJson({'id': 3, 'code': 'TU9', 'name': 'x', 'lockerId': 9}),
      ];
      expect(vouchersUsableAt(options, 5).map((p) => p.code), ['TOAN', 'TU5']);
      // Chưa chọn tủ ⇒ chỉ mã toàn hệ thống.
      expect(vouchersUsableAt(options, null).map((p) => p.code), ['TOAN']);
    });
  });

  group('phạm vi áp dụng của mã', () {
    test('nhãn "Toàn hệ thống" / "Áp dụng tại: <tên tủ>"', () {
      final global = PromotionModel.fromJson({'id': 1, 'code': 'A', 'name': 'x'});
      expect(global.isLockerScoped, isFalse);
      expect(global.scopeLabel, 'Toàn hệ thống');
      expect(global.lockerDisplayName, isNull);

      final scoped = PromotionModel.fromJson({
        'id': 2,
        'code': 'B',
        'name': 'x',
        'lockerId': 7,
        'lockerCode': 'CAB-TU01',
        'lockerName': 'Tủ Thư viện',
      });
      expect(scoped.scopeLabel, 'Áp dụng tại: Tủ Thư viện');
      expect(scoped.usableAt(7), isTrue);
      expect(scoped.usableAt(8), isFalse);

      // Thiếu tên ⇒ mã tủ, rồi id.
      expect(
        PromotionModel.fromJson({'id': 3, 'code': 'C', 'name': 'x', 'lockerId': 7, 'lockerCode': 'CAB-TU01'}).scopeLabel,
        'Áp dụng tại: CAB-TU01',
      );
      expect(
        PromotionModel.fromJson({'id': 4, 'code': 'D', 'name': 'x', 'lockerId': 7}).scopeLabel,
        'Áp dụng tại: Tủ #7',
      );
      // 0 = toàn hệ thống (bộ lọc admin).
      expect(
        PromotionModel.fromJson({'id': 5, 'code': 'E', 'name': 'x', 'lockerId': 0}).isLockerScoped,
        isFalse,
      );
    });

    test('voucher trong ví đọc tên tủ', () {
      final voucher = VoucherModel.fromJson({
        'id': 1,
        'code': 'B',
        'status': 'SAVED',
        'lockerId': 7,
        'lockerName': 'Tủ Thư viện',
      });
      expect(voucher.lockerId, 7);
      expect(voucher.scopeLabel, 'Áp dụng tại: Tủ Thư viện');
      expect(
        VoucherModel.fromJson({'id': 2, 'code': 'A', 'status': 'SAVED'}).scopeLabel,
        'Toàn hệ thống',
      );
    });
  });
}
