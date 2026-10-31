import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/core/config/business_config.dart';
import 'package:smart_laundry_locker/core/constants/payment_methods.dart';
import 'package:smart_laundry_locker/core/network/api_client.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('PaymentMethods (chỉ SePay; MoMo/VNPay đã bỏ)', () {
    test('thanh toán đơn chỉ qua SEPAY', () {
      expect(PaymentMethods.orderPayment, 'SEPAY');
    });

    test('admin còn bật MOMO/VNPAY/WALLET/CASH vẫn bị lọc bỏ', () {
      expect(
        PaymentMethods.enabledAmong(['CASH', 'MOMO', 'sepay', 'VNPAY', 'WALLET']),
        ['SEPAY'],
      );
      expect(PaymentMethods.enabledAmong(['VNPAY', 'MOMO', 'WALLET']), isEmpty);
    });

    test('cấu hình mặc định không còn MOMO/VNPAY/WALLET', () {
      final defaults = BusinessConfig.fromPublicMaps().enabledPaymentMethods;
      expect(defaults, isNot(contains('MOMO')));
      expect(defaults, isNot(contains('VNPAY')));
      expect(defaults, isNot(contains('WALLET')));
    });
  });

  test('ApiClient dịch lỗi 400 PAYMENT_METHOD_UNSUPPORTED sang tiếng Việt', () async {
    final mock = createMockApiClient();
    mock.adapter.onPost(
      '/api/payments/topup/create',
      (server) => server.reply(400, {
        'success': false,
        'code': 'PAYMENT_METHOD_UNSUPPORTED',
        'message': 'Payment method VNPAY is not supported',
      }),
      data: {'method': 'VNPAY'},
    );

    await expectLater(
      mock.apiClient.post<dynamic>(
        '/api/payments/topup/create',
        data: {'method': 'VNPAY'},
      ),
      throwsA(
        isA<ValidationException>().having(
          (e) => e.message,
          'message',
          PaymentMethods.unsupportedMessage,
        ),
      ),
    );
  });
}
