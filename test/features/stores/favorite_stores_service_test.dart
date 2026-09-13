import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/stores/infrastructure/services/favorite_stores_service.dart';

import '../../helpers/test_helpers.dart';

void main() {
  late FavoriteStoresService service;

  setUp(() async {
    await mockSharedPreferences();
    service = FavoriteStoresService();
  });

  group('getFavoriteIds()', () {
    test('returns empty set when no favorites saved', () async {
      final result = await service.getFavoriteIds();
      expect(result, isEmpty);
    });

    test('returns stored favorite ids after toggle', () async {
      await service.toggle(1);
      await service.toggle(3);

      final result = await service.getFavoriteIds();
      expect(result, containsAll([1, 3]));
      expect(result, hasLength(2));
    });
  });

  group('isFavorite()', () {
    test('returns false when store is not favorited', () async {
      final result = await service.isFavorite(1);
      expect(result, isFalse);
    });

    test('returns true after toggling store on', () async {
      await service.toggle(1);
      final result = await service.isFavorite(1);
      expect(result, isTrue);
    });

    test('returns false after toggling store off', () async {
      await service.toggle(1); // on
      await service.toggle(1); // off
      final result = await service.isFavorite(1);
      expect(result, isFalse);
    });
  });

  group('toggle()', () {
    test('returns true when adding a new favorite', () async {
      final result = await service.toggle(1);
      expect(result, isTrue);
    });

    test('returns false when removing an existing favorite', () async {
      await service.toggle(1); // add
      final result = await service.toggle(1); // remove
      expect(result, isFalse);
    });

    test('toggling multiple stores independently', () async {
      await service.toggle(1);
      await service.toggle(2);
      await service.toggle(3);
      await service.toggle(2); // remove store 2

      final ids = await service.getFavoriteIds();
      expect(ids, containsAll([1, 3]));
      expect(ids.contains(2), isFalse);
    });

    test('state persists across service instances', () async {
      await service.toggle(5);
      await service.toggle(7);

      // New instance reads from the same SharedPreferences
      final service2 = FavoriteStoresService();
      final ids = await service2.getFavoriteIds();
      expect(ids, containsAll([5, 7]));
    });
  });
}
