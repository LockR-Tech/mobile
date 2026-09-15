import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/core/config/business_config.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/order_extras.dart';

void main() {
  group('nextLoyaltyTierText', () {
    final config = BusinessConfig.fromPublicMaps(
      loyalty: {
        'app.loyalty.tier-silver-points': 300,
        'app.loyalty.tier-gold-points': 1000,
        'app.loyalty.tier-platinum-points': 4000,
      },
    );

    test('tính điểm còn thiếu theo ngưỡng admin cấu hình', () {
      expect(nextLoyaltyTierText(0, config), 'còn 300 điểm lên hạng Bạc');
      expect(nextLoyaltyTierText(300, config), 'còn 700 điểm lên hạng Vàng');
      expect(
        nextLoyaltyTierText(3999, config),
        'còn 1 điểm lên hạng Bạch kim',
      );
    });

    test('đã ở hạng cao nhất ⇒ null', () {
      expect(nextLoyaltyTierText(4000, config), isNull);
    });

    test('mặc định dùng ngưỡng hiện hành của backend', () {
      expect(
        nextLoyaltyTierText(450, BusinessConfig.defaults()),
        'còn 50 điểm lên hạng Bạc',
      );
    });
  });
}
