import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_laundry_locker/features/drone_delivery/infrastructure/services/pickup_geocoder.dart';

http.Response _json(Object body) => http.Response(
  jsonEncode(body),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Map<String, Object> _feature(
  double lat,
  double lon,
  Map<String, Object> props,
) => {
  'type': 'Feature',
  'properties': props,
  'geometry': {
    'type': 'Point',
    'coordinates': [lon, lat],
  },
};

void main() {
  test(
    'gợi ý địa chỉ qua Photon, ưu tiên quanh TP.HCM và chỉ giữ kết quả ở Việt Nam',
    () async {
      final requested = <Uri>[];
      String? userAgent;
      final client = MockClient((request) async {
        requested.add(request.url);
        userAgent = request.headers['User-Agent'];
        return _json({
          'features': [
            _feature(10.8414, 106.8098, {
              'name': 'Trường Đại học FPT',
              'street': 'Đường D1',
              'district': 'Tăng Nhơn Phú',
              'city': 'Thành phố Hồ Chí Minh',
              'countrycode': 'VN',
            }),
            _feature(1.3, 103.8, {
              'name': 'FPT Singapore',
              'countrycode': 'SG',
            }),
          ],
        });
      });

      final results = await PickupGeocoder(
        client: client,
      ).search('dai hoc fpt');

      expect(requested.single.host, 'photon.komoot.io');
      // Photon chặn (403) User-Agent mặc định của Dart.
      expect(userAgent, startsWith('SmartLaundryLocker/'));
      expect(requested.single.queryParameters['q'], 'dai hoc fpt');
      expect(requested.single.queryParameters['lat'], '10.7769');
      expect(results, hasLength(1));
      expect(results.single.latitude, 10.8414);
      expect(results.single.longitude, 106.8098);
      expect(
        results.single.address,
        'Trường Đại học FPT, Đường D1, Tăng Nhơn Phú, Thành phố Hồ Chí Minh',
      );
    },
  );

  test('Photon lỗi thì tìm qua Nominatim dự phòng', () async {
    final hosts = <String>[];
    final client = MockClient((request) async {
      hosts.add(request.url.host);
      if (request.url.host == 'photon.komoot.io') {
        return http.Response('down', 503);
      }
      expect(request.url.queryParameters['countrycodes'], 'vn');
      return _json([
        {'lat': '10.78', 'lon': '106.69', 'display_name': '45 Lê Lợi, Quận 1'},
      ]);
    });

    final results = await PickupGeocoder(client: client).search('45 Le Loi');

    expect(hosts, ['photon.komoot.io', 'nominatim.openstreetmap.org']);
    expect(results.single.address, '45 Lê Lợi, Quận 1');
  });

  test('tra ngược toạ độ ra địa chỉ có số nhà', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/reverse');
      return _json({
        'features': [
          _feature(10.84, 106.80, {
            'housenumber': '123A',
            'street': 'Lê Văn Việt',
            'district': 'Tăng Nhơn Phú',
            'city': 'Thành phố Hồ Chí Minh',
            'countrycode': 'VN',
          }),
        ],
      });
    });

    final address = await PickupGeocoder(
      client: client,
    ).addressOf(10.84, 106.80);

    expect(address, '123A Lê Văn Việt, Tăng Nhơn Phú, Thành phố Hồ Chí Minh');
  });

  test('gõ dưới 3 ký tự thì không gọi dịch vụ', () async {
    var calls = 0;
    final client = MockClient((_) async {
      calls++;
      return _json({'features': []});
    });

    expect(await PickupGeocoder(client: client).search('ab'), isEmpty);
    expect(calls, 0);
  });
}
