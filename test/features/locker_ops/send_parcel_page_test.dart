import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/core/config/business_config.dart';
import 'package:smart_laundry_locker/core/network/dio_client.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/pages/send_parcel_page.dart';

import '../../helpers/test_helpers.dart';

void main() {
  setUp(() {
    DioClient.instance.init(baseUrl: kTestBaseUrl);
    mockSecureStorage({
      'access_token': makeFakeJwt(sub: '99', roles: ['CUSTOMER']),
    });
  });

  testWidgets('phí gửi và hạn lấy hàng lấy theo cấu hình admin', (tester) async {
    final service = useBusinessConfig(
      BusinessConfig.fromPublicMaps(
        order: {
          'app.order.send-base-fee': 18000,
          'app.order.send-pickup-hours-limit': 36,
          'app.order.pickup-overtime-fee-per-hour': 0,
        },
      ),
    );
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: SendParcelPage(initialLockerId: 5, initialLockerName: 'Tủ demo'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('18.000đ'), findsOneWidget);
    expect(
      find.text(
        'Người nhận có 36 giờ để lấy hàng kể từ lúc bạn bỏ hàng vào ô. '
        'Không tính phí quá giờ.',
      ),
      findsOneWidget,
    );
    expect(service.current.sendBaseFee, 18000);
  });
}
