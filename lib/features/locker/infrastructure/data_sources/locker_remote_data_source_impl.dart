import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/features/locker/infrastructure/data_sources/locker_remote_data_source.dart';
import 'package:smart_laundry_locker/features/locker/infrastructure/models/cabinet_model.dart';
import 'package:smart_laundry_locker/features/locker/infrastructure/models/customer_cabinet_model.dart';
import 'package:smart_laundry_locker/features/locker/infrastructure/models/fixed_rent_response_model.dart';
import 'package:smart_laundry_locker/features/locker/infrastructure/models/locker_location_model.dart';
import 'package:smart_laundry_locker/features/locker/infrastructure/models/locker_rent_request_model.dart';
import 'package:smart_laundry_locker/features/locker/infrastructure/models/locker_model.dart';
import 'package:smart_laundry_locker/features/locker/infrastructure/models/responses/responses.dart';
import 'package:dio/dio.dart';

/// Implementation của LockerRemoteDataSource
/// Sử dụng ApiClient để gọi API endpoints.
class LockerRemoteDataSourceImpl implements LockerRemoteDataSource {
  final ApiClient _apiClient;

  /// API base path cho locker service
  static const String _basePath = '/lockers';

  LockerRemoteDataSourceImpl(this._apiClient);

  /// Extract data field từ API response
  /// API trả về format: {statusCode, message, data: {...}}
  Map<String, dynamic> _extractData(Response<dynamic> response) {
    if (response.data == null) return {};
    final responseData = response.data as Map<String, dynamic>;
    if (responseData['data'] == null) return {};
    return responseData['data'] as Map<String, dynamic>;
  }

  // ==================== LOCATIONS ====================

  /// Current backend exposes GET /api/lockers as a flat list (no server-side
  /// paging/search). We fetch all lockers, map each to the location model with
  /// null-safe defaults, and filter client-side. Shared by the customer /
  /// courier / default location listings so the "Tủ" tab works for any role.
  ///
  /// Also fetches GET /api/stores once to resolve store images by storeId so
  /// each locker card can display the store photo — same images as the home page.
  Future<LocationsResponse> _fetchLockerLocations({String? search}) async {
    final lockersResp = await _apiClient.get<dynamic>('/api/lockers');
    final raw = lockersResp.data;
    final List<dynamic> items = raw is Map<String, dynamic>
        ? (raw['data'] as List<dynamic>? ?? const <dynamic>[])
        : (raw is List ? raw : const <dynamic>[]);

    // Build storeId → imageUrl map; ignore failures (images are optional).
    final Map<String, String> storeImages = {};
    try {
      final storesResp = await _apiClient.get<dynamic>('/api/stores');
      final storeRaw = storesResp.data;
      if (storeRaw != null) {
        final List<dynamic> storeItems = storeRaw is Map<String, dynamic>
            ? (storeRaw['data'] as List<dynamic>? ?? const <dynamic>[])
            : (storeRaw is List ? storeRaw : const <dynamic>[]);
        for (final s in storeItems) {
          if (s is! Map<String, dynamic>) continue;
          final sid = s['id']?.toString();
          final img = (s['image'] ?? s['imageUrl']) as String?;
          if (sid != null && img != null && img.isNotEmpty) {
            storeImages[sid] = img;
          }
        }
      }
    } catch (_) {
      // Store images not critical — list works fine without them.
    }

    final query = (search ?? '').trim().toLowerCase();

    final locations = <Map<String, dynamic>>[];
    for (final item in items) {
      if (item is! Map<String, dynamic>) continue;
      final code = (item['code'] ?? '').toString();
      final lockerName = (item['name'] ?? code).toString();
      final addr = (item['address'] ?? '').toString();
      final status = (item['status'] ?? 'ACTIVE').toString().toUpperCase();
      final storeId = item['storeId']?.toString();

      if (query.isNotEmpty &&
          !lockerName.toLowerCase().contains(query) &&
          !code.toLowerCase().contains(query) &&
          !addr.toLowerCase().contains(query)) {
        continue;
      }

      locations.add(<String, dynamic>{
        'id': (item['id'] ?? '').toString(),
        'name': lockerName,
        'address': addr,
        // Missing coordinates -> NaN so LockerLocation.hasValidCoordinate is
        // false and the detail page shows a friendly "no map" message instead
        // of dropping a pin at (0,0). The list itself only uses name/address.
        'latitude': (item['latitude'] as num?)?.toDouble() ?? double.nan,
        'longitude': (item['longitude'] as num?)?.toDouble() ?? double.nan,
        'isActive': status == 'ACTIVE',
        if (storeId != null && storeImages.containsKey(storeId))
          'imageUrl': storeImages[storeId],
      });
    }

    final count = locations.length;
    return LocationsResponse.fromJson(<String, dynamic>{
      'locations': locations,
      'pagination': {'total': count, 'page': 1, 'limit': count > 0 ? count : 10},
    });
  }

  @override
  Future<LocationsResponse> getLocations({
    int page = 1,
    int limit = 10,
    String? search,
    String? name,
    String? address,
    bool? isActive,
  }) =>
      _fetchLockerLocations(search: search ?? name);

  @override
  Future<LocationsResponse> getLocationsForCustomer({
    int page = 1,
    int limit = 10,
    String? search,
  }) =>
      _fetchLockerLocations(search: search);

  @override
  Future<LocationsResponse> getLocationsForCourier({
    int page = 1,
    int limit = 10,
    String? search,
  }) =>
      _fetchLockerLocations(search: search);

  @override
  Future<LockerLocationModel> getLocationById(String id) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '$_basePath/locations/$id',
    );
    final data = _extractData(response);
    return LockerLocationModel.fromJson(
      data['location'] as Map<String, dynamic>? ?? data,
    );
  }

  @override
  Future<LocationCabinetsResponse> getLocationCabinets(
    String locationId, {
    int page = 1,
    int limit = 10,
    String? status,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (status != null && status.isNotEmpty) 'status': status,
      if (search != null && search.isNotEmpty) 'search': search,
    };

    final response = await _apiClient.get<Map<String, dynamic>>(
      '$_basePath/locations/$locationId/cabinets',
      queryParameters: queryParams,
    );

    return LocationCabinetsResponse.fromJson(_extractData(response));
  }

  @override
  Future<List<CustomerCabinetModel>> getCustomerCabinets(
    String locationId,
  ) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/locations/$locationId/customer/cabinets',
    );

    final data = _extractData(response);
    final cabinetsJson = data['cabinets'] as List<dynamic>?;
    if (cabinetsJson == null) return [];

    return cabinetsJson
        .map((j) => CustomerCabinetModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  // ==================== CABINETS ====================

  @override
  Future<CabinetsResponse> getCabinets({
    int page = 1,
    int limit = 10,
    String? locationId,
    String? name,
    String? macAddress,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (locationId != null && locationId.isNotEmpty) 'locationId': locationId,
      if (name != null && name.isNotEmpty) 'name': name,
      if (macAddress != null && macAddress.isNotEmpty) 'macAddress': macAddress,
    };

    final response = await _apiClient.get<Map<String, dynamic>>(
      '$_basePath/cabinets',
      queryParameters: queryParams,
    );

    return CabinetsResponse.fromJson(_extractData(response));
  }

  @override
  Future<CabinetModel> getCabinetById(String id) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/cabinets/$id',
    );
    final data = _extractData(response);
    return CabinetModel.fromJson(
      data['cabinet'] as Map<String, dynamic>? ?? data,
    );
  }

  @override
  Future<CabinetLockersResponse> getCabinetLockers(
    String cabinetId, {
    int page = 1,
    int limit = 10,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (search != null && search.isNotEmpty) 'search': search,
    };

    final response = await _apiClient.get<Map<String, dynamic>>(
      '$_basePath/cabinets/$cabinetId/lockers',
      queryParameters: queryParams,
    );

    return CabinetLockersResponse.fromJson(_extractData(response));
  }

  // ==================== LOCKERS ====================

  @override
  Future<LockerModel> getLockerById(String id) async {
    final response = await _apiClient.get<Map<String, dynamic>>('/lockers/$id');
    final data = _extractData(response);
    return LockerModel.fromJson(
      data['locker'] as Map<String, dynamic>? ?? data,
    );
  }

  @override
  Future<LockersResponse> getLockersByCabinet(String cabinetId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '$_basePath/lockers/cabinet/$cabinetId',
    );
    return LockersResponse.fromJson(_extractData(response));
  }

  @override
  Future<LockersResponse> getAvailableLockers({
    String? locationId,
    String? cabinetId,
    String? sizeId,
  }) async {
    final queryParams = <String, dynamic>{
      if (locationId != null && locationId.isNotEmpty) 'locationId': locationId,
      if (cabinetId != null && cabinetId.isNotEmpty) 'cabinetId': cabinetId,
      if (sizeId != null && sizeId.isNotEmpty) 'sizeId': sizeId,
    };

    final response = await _apiClient.get<Map<String, dynamic>>(
      '$_basePath/lockers/available',
      queryParameters: queryParams,
    );

    return LockersResponse.fromJson(_extractData(response));
  }

  @override
  Future<List<LockerModel>> getLeastUsedLockers(
    String cabinetId, {
    String? sizeId,
  }) async {
    final queryParams = <String, dynamic>{
      'cabinetId': cabinetId,
      if (sizeId != null) 'sizeId': sizeId,
    };

    final response = await _apiClient.get<Map<String, dynamic>>(
      '$_basePath/least-used',
      queryParameters: queryParams,
    );

    final data = _extractData(response);
    final lockersJson = data['lockers'] as List<dynamic>?;
    if (lockersJson == null) return [];

    return lockersJson
        .map((j) => LockerModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<LockerCountResponse> getLockerCountBySize({
    required String cabinetId,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '$_basePath/count/$cabinetId',
    );

    return LockerCountResponse.fromJson(_extractData(response));
  }

  // ==================== RENTING & MANAGEMENT ====================

  @override
  Future<Map<String, dynamic>> rentLockerFlexible({
    required String lockerId,
    required String cabinetId,
    String itemType = 'OTHER',
    bool skipPhysicalOpen = false,
    String? voucherId,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '$_basePath/rent',
      data: {
        'lockerId': lockerId,
        'cabinetId': cabinetId,
        'itemType': itemType,
        'skipPhysicalOpen': skipPhysicalOpen,
        if (voucherId != null) 'voucherId': voucherId,
      },
    );
    return _extractData(response);
  }

  @override
  Future<FixedRentResponseModel> fixedRentLocker(
    LockerRentRequestModel request,
  ) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/orders/locker/fixed-rent',
      data: request.toJson(),
    );
    return FixedRentResponseModel.fromJson(_extractData(response));
  }

  @override
  Future<Map<String, dynamic>> openLocker(String lockerId) async {
    final response = await _apiClient.put<Map<String, dynamic>>(
      '$_basePath/rent/open/$lockerId',
    );
    return _extractData(response);
  }

  @override
  Future<Map<String, dynamic>> closeLocker(String lockerId) async {
    final response = await _apiClient.put<Map<String, dynamic>>(
      '$_basePath/rent/close/$lockerId',
    );
    return _extractData(response);
  }

  @override
  Future<Map<String, dynamic>> getRentedLockerDetail(
    String orderDetailId,
  ) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '$_basePath/rent/$orderDetailId',
    );
    return _extractData(response);
  }

  @override
  Future<Map<String, dynamic>> openLockerTemporarily(String lockerId) async {
    final response = await _apiClient.put<Map<String, dynamic>>(
      '$_basePath/rent/open/$lockerId',
    );
    return _extractData(response);
  }

  @override
  Future<Map<String, dynamic>> finishRental(String lockerId) async {
    final response = await _apiClient.put<Map<String, dynamic>>(
      '$_basePath/rent/finish/$lockerId',
    );
    return _extractData(response);
  }
}
