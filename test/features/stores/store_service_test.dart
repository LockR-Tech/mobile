import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/stores/infrastructure/services/store_service.dart';

import '../../helpers/test_helpers.dart';

Map<String, dynamic> _store({int id = 1, String name = 'Cửa hàng A'}) => {
  'id': id,
  'name': name,
  'address': '1 Đường ABC, TP.HCM',
  'contactPhone': '0901234567',
  'latitude': 10.762622,
  'longitude': 106.660172,
  'active': true,
  'status': 'ACTIVE',
};

void main() {
  late StoreService service;
  late DioAdapter adapter;

  setUp(() {
    final mock = createMockApiClient();
    adapter = mock.adapter;
    service = StoreService(mock.apiClient);
  });

  group('getStores()', () {
    test('returns list of all stores', () async {
      adapter.onGet('/api/stores', (server) => server.reply(200, apiOk([
        _store(id: 1, name: 'Cửa hàng A'),
        _store(id: 2, name: 'Cửa hàng B'),
        _store(id: 3, name: 'Cửa hàng C'),
      ])));

      final result = await service.getStores();

      expect(result, hasLength(3));
      expect(result.first.id, equals(1));
      expect(result.first.name, equals('Cửa hàng A'));
    });

    test('filters by search query client-side (name match)', () async {
      adapter.onGet('/api/stores', (server) => server.reply(200, apiOk([
        _store(id: 1, name: 'Cửa hàng Quận 1'),
        _store(id: 2, name: 'Cửa hàng Quận 7'),
        _store(id: 3, name: 'Giặt ủi Bình Thạnh'),
      ])));

      final result = await service.getStores(search: 'Quận');

      expect(result, hasLength(2));
      expect(result.every((s) => s.name.contains('Quận')), isTrue);
    });

    test('returns empty list when no stores match search', () async {
      adapter.onGet('/api/stores', (server) => server.reply(200, apiOk([
        _store(id: 1, name: 'Cửa hàng A'),
      ])));

      final result = await service.getStores(search: 'xyz_không_tồn_tại');
      expect(result, isEmpty);
    });

    test('returns empty list when backend returns empty array', () async {
      adapter.onGet('/api/stores', (server) => server.reply(200, apiOk([])));

      final result = await service.getStores();
      expect(result, isEmpty);
    });
  });

  group('getStore()', () {
    test('returns store by id', () async {
      adapter.onGet('/api/stores/1', (server) => server.reply(200, apiOk(
        _store(id: 1, name: 'Cửa hàng A'),
      )));

      final result = await service.getStore(1);

      expect(result.id, equals(1));
      expect(result.name, equals('Cửa hàng A'));
      expect(result.address, equals('1 Đường ABC, TP.HCM'));
    });

    test('throws NotFoundException on 404', () async {
      adapter.onGet('/api/stores/999', (server) => server.reply(
        404,
        apiError('Cửa hàng không tồn tại'),
      ));

      expect(() => service.getStore(999), throwsA(isA<Exception>()));
    });
  });

  group('getRatings()', () {
    test('returns list of store ratings', () async {
      adapter.onGet('/api/stores/1/ratings', (server) => server.reply(200, apiOk([
        {'id': 1, 'storeId': 1, 'userId': 10, 'rating': 5, 'comment': 'Tuyệt vời', 'createdAt': '2026-06-22T09:00:00'},
        {'id': 2, 'storeId': 1, 'userId': 11, 'rating': 4, 'comment': 'Khá tốt', 'createdAt': '2026-06-21T08:00:00'},
      ])));

      final result = await service.getRatings(1);

      expect(result, hasLength(2));
      expect(result.first.rating, equals(5));
      expect(result.last.rating, equals(4));
    });

    test('returns empty list when no ratings', () async {
      adapter.onGet('/api/stores/1/ratings', (server) => server.reply(200, apiOk([])));

      final result = await service.getRatings(1);
      expect(result, isEmpty);
    });
  });
}
