import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_laundry_locker/features/drone_delivery/infrastructure/services/pickup_geocoder.dart';

void main() {
  test(
    'biases address search toward HCMC and preserves result coordinates',
    () async {
      late Uri requestedUri;
      final client = MockClient((request) async {
        requestedUri = request.url;
        return http.Response(
          jsonEncode([
            {
              'lat': '10.8411',
              'lon': '106.8097',
              'display_name': 'FPT University HCMC, Ho Chi Minh City',
            },
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final results = await PickupGeocoder(
        client: client,
      ).search('dai hoc fpt');

      expect(
        requestedUri.queryParameters['viewbox'],
        '106.35,11.15,107.05,10.35',
      );
      expect(requestedUri.queryParameters['addressdetails'], '1');
      expect(requestedUri.queryParameters['countrycodes'], 'vn');
      expect(results, hasLength(1));
      expect(results.single.latitude, 10.8411);
      expect(results.single.longitude, 106.8097);
    },
  );
}
