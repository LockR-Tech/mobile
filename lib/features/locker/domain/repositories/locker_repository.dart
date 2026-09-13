import 'package:smart_laundry_locker/features/locker/domain/entities/cabinet.dart';
import 'package:smart_laundry_locker/features/locker/domain/entities/fixed_rent_entity.dart';
import 'package:smart_laundry_locker/features/locker/domain/entities/locker.dart';
import 'package:smart_laundry_locker/features/locker/domain/entities/locker_location.dart';
import 'package:smart_laundry_locker/features/locker/infrastructure/models/responses/lockers_response.dart';
import 'package:smart_laundry_locker/core/domain/entities/pagination.dart';
import 'package:dartz/dartz.dart';
import 'package:smart_laundry_locker/core/errors/failures.dart';

/// Repository Contract: LockerRepository
/// Định nghĩa interface cho data access, implementation ở infrastructure layer.
/// Sử dụng Either<Failure, T> để handle errors theo functional programming.
abstract class LockerRepository {
  // ==================== LOCATIONS ====================

  /// Lấy danh sách locations với pagination và filter
  /// API: GET /locations
  Future<Either<Failure, PaginatedResult<LockerLocation>>> getLocations({
    int page = 1,
    int limit = 10,
    String? search,
    String? name,
    String? address,
    bool? isActive,
  });

  /// Lấy chi tiết location theo ID
  /// API: GET /locations/:id
  Future<Either<Failure, LockerLocation>> getLocationById(String id);

  /// Lấy danh sách cabinets trong location
  /// API: GET /locations/:id/cabinets
  Future<Either<Failure, LocationWithCabinets>> getLocationCabinets(
    String locationId, {
    int page = 1,
    int limit = 10,
    String? status,
    String? search,
  });

  // ==================== CABINETS ====================

  /// Lấy danh sách cabinets với pagination
  /// API: GET /cabinets
  Future<Either<Failure, PaginatedResult<Cabinet>>> getCabinets({
    int page = 1,
    int limit = 10,
    String? locationId,
    String? name,
    String? macAddress,
  });

  /// Lấy chi tiết cabinet theo ID
  /// API: GET /cabinets/:id
  Future<Either<Failure, Cabinet>> getCabinetById(String id);

  /// Lấy danh sách lockers trong cabinet
  /// API: GET /cabinets/:id/lockers
  Future<Either<Failure, CabinetWithLockers>> getCabinetLockers(
    String cabinetId, {
    int page = 1,
    int limit = 10,
    String? search,
  });

  // ==================== LOCKERS ====================

  /// Lấy chi tiết locker theo ID
  /// API: GET /lockers/:id
  Future<Either<Failure, Locker>> getLockerById(String id);

  /// Lấy danh sách lockers theo cabinet (không pagination)
  /// API: GET /lockers/cabinet/:cabinetId
  Future<Either<Failure, List<Locker>>> getLockersByCabinet(String cabinetId);

  /// Lấy danh sách lockers available
  /// API: GET /lockers/available
  Future<Either<Failure, List<Locker>>> getAvailableLockers({
    String? locationId,
    String? cabinetId,
    String? sizeId,
  });

  /// Đếm lockers theo size
  /// API: GET /lockers/count/:cabinetId
  Future<Either<Failure, LockerCountResponse>> getLockerCountBySize({
    required String cabinetId,
  });

  /// Lấy danh sách cabinets cho customer
  /// API: GET /locations/:id/customer/cabinets
  Future<Either<Failure, List<Cabinet>>> getCustomerCabinets(String locationId);

  /// Lấy danh sách least used lockers
  /// API: GET /lockers/least-used
  Future<Either<Failure, List<Locker>>> getLeastUsedLockers(
    String cabinetId, {
    String? sizeId,
  });

  // ==================== RENTING & MANAGEMENT ====================

  /// Thuê tủ linh hoạt
  Future<Either<Failure, Map<String, dynamic>>> rentLockerFlexible({
    required String lockerId,
    required String cabinetId,
    String itemType = 'OTHER',
    bool skipPhysicalOpen = false,
    String? voucherId,
  });

  /// Thuê tủ cố định
  Future<Either<Failure, FixedRentEntity>> fixedRentLocker({
    required String cabinetId,
    required String lockerId,
    required int rentMonths,
    int? rentDays,
    String itemType = 'OTHER',
    bool skipPhysicalOpen = false,
    String? voucherId,
  });

  /// Điều khiển mở tủ sau khi thuê
  Future<Either<Failure, Map<String, dynamic>>> openLocker(String lockerId);

  /// Điều khiển đóng tủ sau khi thuê
  Future<Either<Failure, Map<String, dynamic>>> closeLocker(String lockerId);

  /// Lấy chi tiết tủ đang thuê
  Future<Either<Failure, Map<String, dynamic>>> getRentedLockerDetail(
    String orderDetailId,
  );

  /// Mở tủ tạm thời
  Future<Either<Failure, Map<String, dynamic>>> openLockerTemporarily(
    String lockerId,
  );

  Future<Either<Failure, Map<String, dynamic>>> finishRental(String lockerId);
}

/// Helper class cho location with cabinets
class LocationWithCabinets {
  final LockerLocation location;
  final List<Cabinet> cabinets;
  final Pagination pagination;

  const LocationWithCabinets({
    required this.location,
    required this.cabinets,
    required this.pagination,
  });
}

/// Helper class cho cabinet with lockers
class CabinetWithLockers {
  final Cabinet cabinet;
  final List<Locker> lockers;
  final Pagination pagination;

  const CabinetWithLockers({
    required this.cabinet,
    required this.lockers,
    required this.pagination,
  });
}
