import 'package:smart_laundry_locker/features/stores/domain/entities/store.dart';
import 'package:smart_laundry_locker/core/network/user_gateway_client.dart';

/// Read-only gateway client for the public store catalogue.
///
/// Endpoints (all go through the API gateway, JWT attached by DioClient):
/// - `GET /api/stores` (optional `latitude`/`longitude`/`radiusKm` for nearby)
/// - `GET /api/stores/{id}`
/// - `GET /api/stores/{storeId}/ratings`
class StoreService extends UserGatewayClient {
  StoreService(super.apiClient);

  /// Lists stores. When [latitude]/[longitude] are given the backend returns
  /// stores sorted by distance with `distanceKm` populated. [search] filters
  /// the result client-side by name/address.
  Future<List<Store>> getStores({
    String? search,
    double? latitude,
    double? longitude,
    double? radiusKm,
  }) async {
    final response = await apiClient.get<Map<String, dynamic>>(
      '/api/stores',
      queryParameters: {
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (radiusKm != null) 'radiusKm': radiusKm,
      },
    );

    var stores = unwrapList(response)
        .whereType<Map<String, dynamic>>()
        .map(Store.fromJson)
        .where((store) => store.id > 0)
        .toList();

    final query = search?.trim().toLowerCase();
    if (query != null && query.isNotEmpty) {
      stores = stores
          .where(
            (store) =>
                store.name.toLowerCase().contains(query) ||
                (store.address ?? '').toLowerCase().contains(query),
          )
          .toList();
    }
    return stores;
  }

  Future<Store> getStore(int id) async {
    final response = await apiClient.get<Map<String, dynamic>>(
      '/api/stores/$id',
    );
    return Store.fromJson(unwrapMap(response));
  }

  Future<List<StoreRating>> getRatings(int storeId) async {
    final response = await apiClient.get<Map<String, dynamic>>(
      '/api/stores/$storeId/ratings',
    );
    return unwrapList(
      response,
    ).whereType<Map<String, dynamic>>().map(StoreRating.fromJson).toList();
  }
}
