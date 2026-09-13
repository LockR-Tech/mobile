import 'package:smart_laundry_locker/features/locker/infrastructure/models/locker_location_model.dart';
import 'package:smart_laundry_locker/features/locker/infrastructure/models/cabinet_model.dart';
import 'package:smart_laundry_locker/features/locker/infrastructure/models/locker_model.dart';

/// Local Data Source: LockerLocalDataSource
/// Interface định nghĩa các method để cache/fetch data từ local storage.
abstract class LockerLocalDataSource {
  // ==================== LOCATIONS ====================

  /// Cache danh sách locations
  Future<void> cacheLocations(List<LockerLocationModel> locations);

  /// Lấy cached locations
  Future<List<LockerLocationModel>?> getCachedLocations();

  /// Cache một location
  Future<void> cacheLocation(LockerLocationModel location);

  /// Lấy cached location theo ID
  Future<LockerLocationModel?> getCachedLocationById(String id);

  // ==================== CABINETS ====================

  /// Cache danh sách cabinets
  Future<void> cacheCabinets(List<CabinetModel> cabinets);

  /// Lấy cached cabinets
  Future<List<CabinetModel>?> getCachedCabinets();

  /// Cache cabinets theo location
  Future<void> cacheCabinetsByLocation(
    String locationId,
    List<CabinetModel> cabinets,
  );

  /// Lấy cached cabinets theo location
  Future<List<CabinetModel>?> getCachedCabinetsByLocation(String locationId);

  // ==================== LOCKERS ====================

  /// Cache lockers theo cabinet
  Future<void> cacheLockersByCabinet(
    String cabinetId,
    List<LockerModel> lockers,
  );

  /// Lấy cached lockers theo cabinet
  Future<List<LockerModel>?> getCachedLockersByCabinet(String cabinetId);

  // ==================== UTILS ====================

  /// Clear all cache
  Future<void> clearCache();

  /// Check cache expired
  Future<bool> isCacheExpired();
}
