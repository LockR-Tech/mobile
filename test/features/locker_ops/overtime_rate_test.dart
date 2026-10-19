import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/core/config/business_config.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/pages/my_locker_orders_page.dart';

void main() {
  final config = BusinessConfig.defaults();

  test('đơn giá quá giờ lấy theo server (đơn thuê = giá thuê ô), không theo phí đơn gửi hàng', () {
    expect(overtimeRateOf({'overtimeRatePerHour': 5000}, config), 5000);
    expect(overtimeCappedOf({'overtimeCapped': false}), isFalse);
  });

  test('server cũ chưa trả đơn giá thì dùng phí quá hạn mỗi giờ trong cấu hình', () {
    expect(overtimeRateOf(<String, dynamic>{}, config), config.pickupOvertimeFeePerHour);
    expect(overtimeCappedOf(<String, dynamic>{}), isTrue);
  });
}
