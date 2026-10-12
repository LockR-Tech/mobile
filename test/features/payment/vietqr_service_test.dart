import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/payment/data/vietqr_service.dart';

import '../../helpers/test_helpers.dart';

({VietQrService service, DioAdapter adapter, List<String> requests}) _service() {
  final dio = Dio();
  final requests = <String>[];
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        requests.add(options.uri.toString());
        handler.next(options);
      },
    ),
  );
  final adapter = DioAdapter(dio: dio);
  return (service: VietQrService(dio: dio), adapter: adapter, requests: requests);
}

void main() {
  group('buildVietQrPayDeeplink', () {
    test('đúng định dạng dl.vietqr.io/pay, mã ngân hàng viết thường', () {
      expect(
        buildVietQrPayDeeplink(
          appId: 'vcb',
          accountNo: '0123456789',
          bankCode: 'MB',
          amount: 20000,
          transferContent: 'LKR81',
        ),
        'https://dl.vietqr.io/pay?app=vcb&ba=0123456789@mb&am=20000&tn=LKR81',
      );
    });

    test('mã hoá ký tự đặc biệt trong nội dung', () {
      final url = buildVietQrPayDeeplink(
        appId: 'tcb',
        accountNo: '123',
        bankCode: 'icb',
        amount: 5000,
        transferContent: 'LKR 42&x',
      );
      expect(url, endsWith('&tn=LKR%2042%26x'));
      expect(Uri.parse(url).queryParameters['tn'], 'LKR 42&x');
    });
  });

  group('bankCodeForBin', () {
    test('tra GET /v2/banks (bin → code viết thường) và nhớ lại', () async {
      final s = _service();
      s.adapter.onGet(
        'https://api.vietqr.io/v2/banks',
        (server) => server.reply(200, {
          'code': '00',
          'data': [
            {'bin': '970422', 'code': 'MB', 'shortName': 'MBBank'},
            {'bin': '970999', 'code': 'NEWB', 'shortName': 'Ngân hàng mới'},
          ],
        }),
      );

      expect(await s.service.bankCodeForBin('970422'), 'mb');
      expect(await s.service.bankCodeForBin('970999'), 'newb');
      expect(s.requests.where((u) => u.endsWith('/v2/banks')), hasLength(1));
    });

    test('API lỗi ⇒ dùng bảng mã dự phòng, lần sau thử gọi lại', () async {
      final s = _service();
      s.adapter.onGet(
        'https://api.vietqr.io/v2/banks',
        (server) => server.reply(500, {'code': '99'}),
      );

      expect(await s.service.bankCodeForBin('970436'), 'vcb');
      expect(await s.service.bankCodeForBin('970422'), 'mb');
      // Lỗi không được nhớ ⇒ mỗi lần tra đều thử API lại.
      expect(s.requests.where((u) => u.endsWith('/v2/banks')), hasLength(2));
    });

    test('API thiếu BIN ⇒ dự phòng; không có ở đâu ⇒ null', () async {
      final s = _service();
      s.adapter.onGet(
        'https://api.vietqr.io/v2/banks',
        (server) => server.reply(200, {
          'data': [
            {'bin': '970999', 'code': 'NEWB'},
          ],
        }),
      );

      expect(await s.service.bankCodeForBin('970407'), 'tcb');
      expect(await s.service.bankCodeForBin('123456'), isNull);
    });
  });

  group('bankApps', () {
    test('chỉ giữ app autofill == 1, theo nền tảng, nhớ lại', () async {
      final s = _service();
      s.adapter.onGet(
        'https://api.vietqr.io/v2/android-app-deeplinks',
        (server) => server.reply(200, {
          'apps': [
            {
              'appId': 'vcb',
              'appName': 'Vietcombank',
              'appLogo': 'https://img/vcb.png',
              'deeplink': 'https://dl.vietqr.io/pay?app=vcb',
              'autofill': 1,
            },
            {'appId': 'old', 'appName': 'App cũ', 'autofill': 0},
            {'appId': 'mb', 'appName': 'MB Bank', 'autofill': 1},
          ],
        }),
      );

      final apps = await s.service.bankApps(ios: false);
      expect(apps.map((a) => a.appId), ['vcb', 'mb']);
      expect(apps.first.appLogo, 'https://img/vcb.png');
      await s.service.bankApps(ios: false);
      expect(
        s.requests.where((u) => u.endsWith('/android-app-deeplinks')),
        hasLength(1),
      );
    });

    test('iOS gọi ios-app-deeplinks', () async {
      final s = _service();
      s.adapter.onGet(
        'https://api.vietqr.io/v2/ios-app-deeplinks',
        (server) => server.reply(200, {
          'apps': [
            {'appId': 'tcb', 'appName': 'Techcombank', 'autofill': 1},
          ],
        }),
      );

      final apps = await s.service.bankApps(ios: true);
      expect(apps.single.appName, 'Techcombank');
    });
  });
}
