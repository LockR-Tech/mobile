import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/pages/my_locker_orders_page.dart';

void main() {
  test('đơn drone đang giao: nút là "Theo dõi giao drone"', () {
    for (final status in ['AWAITING_DISPATCH', 'STORING', 'INITIALIZED']) {
      expect(droneFlightFinished(status), isFalse, reason: status);
    }
  });

  test(
    'đơn drone đã xong / huỷ / hết hạn: vẫn có nút, đổi thành "Xem lại hành trình drone"',
    () {
      for (final status in [
        'COMPLETED',
        'CANCELED',
        'EXPIRED',
        'DELIVERY_INCOMPLETE',
        'completed',
      ]) {
        expect(droneFlightFinished(status), isTrue, reason: status);
      }
    },
  );
}
