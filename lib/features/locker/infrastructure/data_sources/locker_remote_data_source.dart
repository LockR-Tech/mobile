import 'package:smart_laundry_locker/features/locker/infrastructure/models/cabinet_model.dart';
import 'package:smart_laundry_locker/features/locker/infrastructure/models/customer_cabinet_model.dart';
import 'package:smart_laundry_locker/features/locker/infrastructure/models/fixed_rent_response_model.dart';
import 'package:smart_laundry_locker/features/locker/infrastructure/models/locker_rent_request_model.dart';
import 'package:smart_laundry_locker/features/locker/infrastructure/models/locker_location_model.dart';
import 'package:smart_laundry_locker/features/locker/infrastructure/models/locker_model.dart';
import 'package:smart_laundry_locker/features/locker/infrastructure/models/responses/responses.dart';

/// Remote Data Source: LockerRemoteDataSource
/// Interface định nghĩa các method để fetch data từ API.
abstract class LockerRemoteDataSource {
  // ==================== LOCATIONS ====================

  /// GET /locations
  Future<LocationsResponse> getLocations({
    int page = 1,
    int limit = 10,
    String? search,
    String? name,
    String? address,
    bool? isActive,
  });

  /// GET /locations/customer
  Future<LocationsResponse> getLocationsForCustomer({
    int page = 1,
    int limit = 10,
    String? search,
  });

  /// GET /locations/courier
  Future<LocationsResponse> getLocationsForCourier({
    int page = 1,
    int limit = 10,
    String? search,
  });

  /// GET /locations/:id
  Future<LockerLocationModel> getLocationById(String id);

  /// GET /locations/:id/cabinets
  Future<LocationCabinetsResponse> getLocationCabinets(
    String locationId, {
    int page = 1,
    int limit = 10,
    String? status,
    String? search,
  });

  /// GET /locations/:id/customer/cabinets
  Future<List<CustomerCabinetModel>> getCustomerCabinets(String locationId);

  // ==================== CABINETS ====================

  /// GET /cabinets
  Future<CabinetsResponse> getCabinets({
    int page = 1,
    int limit = 10,
    String? locationId,
    String? name,
    String? macAddress,
  });

  /// GET /cabinets/:id
  Future<CabinetModel> getCabinetById(String id);

  /// GET /cabinets/:id/lockers
  Future<CabinetLockersResponse> getCabinetLockers(
    String cabinetId, {
    int page = 1,
    int limit = 10,
    String? search,
  });

  // ==================== LOCKERS ====================

  /// GET /lockers/:id
  Future<LockerModel> getLockerById(String id);

  /// GET /lockers/cabinet/:cabinetId
  Future<LockersResponse> getLockersByCabinet(String cabinetId);

  /// GET /lockers/available
  Future<LockersResponse> getAvailableLockers({
    String? locationId,
    String? cabinetId,
    String? sizeId,
  });

  /// GET /lockers/least-used
  Future<List<LockerModel>> getLeastUsedLockers(
    String cabinetId, {
    String? sizeId,
  });

  /// GET /lockers/count/:cabinetId
  Future<LockerCountResponse> getLockerCountBySize({required String cabinetId});

  // ==================== RENTING & MANAGEMENT ====================

  /// POST /lockers/rent (Linh hoạt)
  Future<Map<String, dynamic>> rentLockerFlexible({
    required String lockerId,
    required String cabinetId,
    String itemType = 'OTHER',
    bool skipPhysicalOpen = false,
    String? voucherId,
  });

  /// POST /orders/locker/fixed-rent (Cố định)
  Future<FixedRentResponseModel> fixedRentLocker(
    LockerRentRequestModel request,
  );

  /// PUT /lockers/rent/open/:lockerId
  Future<Map<String, dynamic>> openLocker(String lockerId);

  /// PUT /lockers/rent/close/:lockerId
  Future<Map<String, dynamic>> closeLocker(String lockerId);

  /// GET /lockers/rent/:orderDetailId
  Future<Map<String, dynamic>> getRentedLockerDetail(String orderDetailId);

  /// PUT /lockers/rent/open/:lockerId
  Future<Map<String, dynamic>> openLockerTemporarily(String lockerId);

  /// PUT /lockers/rent/finish/:lockerId
  Future<Map<String, dynamic>> finishRental(String lockerId);
}
