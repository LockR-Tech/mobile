import 'package:smart_laundry_locker/features/locker/application/use_cases/get_available_lockers_use_case.dart';
import 'package:smart_laundry_locker/features/locker/application/use_cases/get_cabinet_lockers_use_case.dart';
import 'package:smart_laundry_locker/features/locker/application/use_cases/get_location_cabinets_use_case.dart';
import 'package:smart_laundry_locker/features/locker/application/use_cases/get_location_detail_use_case.dart';
import 'package:smart_laundry_locker/features/locker/application/use_cases/get_cabinet_by_id_use_case.dart';
import 'package:smart_laundry_locker/features/locker/application/use_cases/get_locker_by_id_use_case.dart';
import 'package:smart_laundry_locker/features/locker/application/use_cases/get_locker_count_use_case.dart';
import 'package:smart_laundry_locker/features/locker/application/use_cases/get_locations_use_case.dart';
import 'package:smart_laundry_locker/features/locker/application/use_cases/get_customer_cabinets_use_case.dart';
import 'package:smart_laundry_locker/features/locker/application/use_cases/get_least_used_lockers_use_case.dart';
import 'package:smart_laundry_locker/features/locker/application/use_cases/rent_locker_flexible_use_case.dart';
import 'package:smart_laundry_locker/features/locker/application/use_cases/get_rented_locker_detail_use_case.dart';
import 'package:smart_laundry_locker/features/locker/application/use_cases/open_locker_temporarily_use_case.dart';
import 'package:smart_laundry_locker/features/locker/application/use_cases/finish_rental_use_case.dart';
import 'package:smart_laundry_locker/features/subscription/application/use_cases/get_pricings_use_case.dart';
import 'package:smart_laundry_locker/features/subscription/domain/entities/plan_entity.dart';
import 'package:smart_laundry_locker/features/locker/domain/entities/cabinet.dart';
import 'package:smart_laundry_locker/features/locker/domain/entities/locker.dart';
import 'package:smart_laundry_locker/features/locker/domain/entities/locker_location.dart';
import 'package:smart_laundry_locker/core/domain/entities/pagination.dart';
import 'package:smart_laundry_locker/features/locker/infrastructure/models/responses/lockers_response.dart';
import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

/// Locker State: Quản lý state cho locker feature
class LockerState {
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final List<LockerLocation> locations;
  final LockerLocation? selectedLocation;
  final List<Cabinet> cabinets;
  final Cabinet? selectedCabinet;
  final List<Locker> lockers;
  final List<Locker> availableLockers;
  final List<Locker> leastUsedLockers;
  final Map<String, int> lockerCounts;
  final List<PricingEntity> pricings;
  final List<LockerSizeCount> lockerSizeItems;
  final Pagination? locationsPagination;
  final Pagination? cabinetsPagination;
  final Pagination? lockersPagination;

  const LockerState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.locations = const [],
    this.selectedLocation,
    this.cabinets = const [],
    this.selectedCabinet,
    this.lockers = const [],
    this.availableLockers = const [],
    this.leastUsedLockers = const [],
    this.lockerCounts = const {},
    this.pricings = const [],
    this.lockerSizeItems = const [],
    this.locationsPagination,
    this.cabinetsPagination,
    this.lockersPagination,
  });

  LockerState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    List<LockerLocation>? locations,
    LockerLocation? selectedLocation,
    List<Cabinet>? cabinets,
    Cabinet? selectedCabinet,
    List<Locker>? lockers,
    List<Locker>? availableLockers,
    List<Locker>? leastUsedLockers,
    Map<String, int>? lockerCounts,
    List<PricingEntity>? pricings,
    List<LockerSizeCount>? lockerSizeItems,
    Pagination? locationsPagination,
    Pagination? cabinetsPagination,
    Pagination? lockersPagination,
  }) {
    return LockerState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      locations: locations ?? this.locations,
      selectedLocation: selectedLocation ?? this.selectedLocation,
      cabinets: cabinets ?? this.cabinets,
      selectedCabinet: selectedCabinet ?? this.selectedCabinet,
      lockers: lockers ?? this.lockers,
      availableLockers: availableLockers ?? this.availableLockers,
      leastUsedLockers: leastUsedLockers ?? this.leastUsedLockers,
      lockerCounts: lockerCounts ?? this.lockerCounts,
      pricings: pricings ?? this.pricings,
      lockerSizeItems: lockerSizeItems ?? this.lockerSizeItems,
      locationsPagination: locationsPagination ?? this.locationsPagination,
      cabinetsPagination: cabinetsPagination ?? this.cabinetsPagination,
      lockersPagination: lockersPagination ?? this.lockersPagination,
    );
  }

  /// Kiểm tra có thể load more locations không
  bool get canLoadMoreLocations => locationsPagination?.hasNextPage ?? false;

  /// Kiểm tra có thể load more cabinets không
  bool get canLoadMoreCabinets => cabinetsPagination?.hasNextPage ?? false;
}

/// Locker Provider: State management cho locker feature
/// Sử dụng ChangeNotifier pattern (có thể thay bằng Riverpod/Bloc).
class LockerProvider extends ChangeNotifier {
  final GetLocationsUseCase _getLocationsUseCase;
  final GetLocationDetailUseCase _getLocationDetailUseCase;
  final GetLocationCabinetsUseCase _getLocationCabinetsUseCase;
  final GetCabinetLockersUseCase _getCabinetLockersUseCase;
  final GetAvailableLockersUseCase _getAvailableLockersUseCase;
  final GetLockerCountBySizeUseCase _getLockerCountUseCase;
  final GetCustomerCabinetsUseCase _getCustomerCabinetsUseCase;
  final GetLeastUsedLockersUseCase _getLeastUsedLockersUseCase;
  final RentLockerFlexibleUseCase _rentLockerFlexibleUseCase;
  final GetRentedLockerDetailUseCase _getRentedLockerDetailUseCase;
  final OpenLockerTemporarilyUseCase _openLockerTemporarilyUseCase;
  final FinishRentalUseCase _finishRentalUseCase;
  final GetCabinetByIdUseCase _getCabinetByIdUseCase;
  final GetLockerByIdUseCase _getLockerByIdUseCase;
  final GetPricingsUseCase _getPricingsUseCase;

  LockerState _state = const LockerState();
  LockerState get state => _state;

  LockerProvider({
    required GetLocationsUseCase getLocationsUseCase,
    required GetLocationDetailUseCase getLocationDetailUseCase,
    required GetLocationCabinetsUseCase getLocationCabinetsUseCase,
    required GetCabinetLockersUseCase getCabinetLockersUseCase,
    required GetAvailableLockersUseCase getAvailableLockersUseCase,
    required GetLockerCountBySizeUseCase getLockerCountUseCase,
    required GetCustomerCabinetsUseCase getCustomerCabinetsUseCase,
    required GetLeastUsedLockersUseCase getLeastUsedLockersUseCase,
    required RentLockerFlexibleUseCase rentLockerFlexibleUseCase,
    required GetRentedLockerDetailUseCase getRentedLockerDetailUseCase,
    required OpenLockerTemporarilyUseCase openLockerTemporarilyUseCase,
    required FinishRentalUseCase finishRentalUseCase,
    required GetCabinetByIdUseCase getCabinetByIdUseCase,
    required GetLockerByIdUseCase getLockerByIdUseCase,
    required GetPricingsUseCase getPricingsUseCase,
  }) : _getLocationsUseCase = getLocationsUseCase,
       _getLocationDetailUseCase = getLocationDetailUseCase,
       _getLocationCabinetsUseCase = getLocationCabinetsUseCase,
       _getCabinetLockersUseCase = getCabinetLockersUseCase,
       _getAvailableLockersUseCase = getAvailableLockersUseCase,
       _getLockerCountUseCase = getLockerCountUseCase,
       _getCustomerCabinetsUseCase = getCustomerCabinetsUseCase,
       _getLeastUsedLockersUseCase = getLeastUsedLockersUseCase,
       _rentLockerFlexibleUseCase = rentLockerFlexibleUseCase,
       _getRentedLockerDetailUseCase = getRentedLockerDetailUseCase,
       _openLockerTemporarilyUseCase = openLockerTemporarilyUseCase,
       _finishRentalUseCase = finishRentalUseCase,
       _getCabinetByIdUseCase = getCabinetByIdUseCase,
       _getLockerByIdUseCase = getLockerByIdUseCase,
       _getPricingsUseCase = getPricingsUseCase;

  // ==================== LOCATIONS ====================

  Future<void> getLocations({String? search, bool refresh = false}) async {
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();

    final result = await _getLocationsUseCase(
      GetLocationsParams(page: 1, limit: 10, search: search, isActive: true),
    );

    result.fold(
      (failure) {
        _state = _state.copyWith(isLoading: false, error: failure.message);
      },
      (paginatedResult) {
        _state = _state.copyWith(
          isLoading: false,
          locations: paginatedResult.items,
          locationsPagination: paginatedResult.pagination,
        );
      },
    );
    notifyListeners();
  }

  /// Load more locations
  Future<void> loadMoreLocations({String? search}) async {
    if (!_state.canLoadMoreLocations || _state.isLoadingMore) return;

    _state = _state.copyWith(isLoadingMore: true);
    notifyListeners();

    final nextPage = (_state.locationsPagination?.page ?? 0) + 1;
    final result = await _getLocationsUseCase(
      GetLocationsParams(
        page: nextPage,
        limit: 10,
        search: search,
        isActive: true,
      ),
    );

    result.fold(
      (failure) {
        _state = _state.copyWith(isLoadingMore: false, error: failure.message);
      },
      (paginatedResult) {
        _state = _state.copyWith(
          isLoadingMore: false,
          locations: [..._state.locations, ...paginatedResult.items],
          locationsPagination: paginatedResult.pagination,
        );
      },
    );
    notifyListeners();
  }

  /// Lấy chi tiết location
  Future<void> getLocationDetail(String locationId) async {
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();

    final result = await _getLocationDetailUseCase(locationId);

    result.fold(
      (failure) {
        _state = _state.copyWith(isLoading: false, error: failure.message);
      },
      (location) {
        _state = _state.copyWith(isLoading: false, selectedLocation: location);
      },
    );
    notifyListeners();
  }

  /// Lấy cabinets trong location
  Future<void> getLocationCabinets(String locationId) async {
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();

    final result = await _getLocationCabinetsUseCase(
      GetLocationCabinetsParams(locationId: locationId),
    );

    result.fold(
      (failure) {
        _state = _state.copyWith(isLoading: false, error: failure.message);
      },
      (locationWithCabinets) {
        _state = _state.copyWith(
          isLoading: false,
          selectedLocation: locationWithCabinets.location,
          cabinets: locationWithCabinets.cabinets,
          cabinetsPagination: locationWithCabinets.pagination,
        );
      },
    );
    notifyListeners();
  }

  // ==================== CABINETS ====================

  /// Lấy lockers trong cabinet
  Future<void> getCabinetLockers(String cabinetId) async {
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();

    final result = await _getCabinetLockersUseCase(
      GetCabinetLockersParams(cabinetId: cabinetId),
    );

    result.fold(
      (failure) {
        _state = _state.copyWith(isLoading: false, error: failure.message);
      },
      (cabinetWithLockers) {
        _state = _state.copyWith(
          isLoading: false,
          selectedCabinet: cabinetWithLockers.cabinet,
          lockers: cabinetWithLockers.lockers,
          lockersPagination: cabinetWithLockers.pagination,
        );
      },
    );
    notifyListeners();
  }

  /// Lấy chi tiết cabinet
  Future<Cabinet?> getCabinetById(String cabinetId) async {
    final result = await _getCabinetByIdUseCase(cabinetId);

    return result.fold((failure) {
      _state = _state.copyWith(error: failure.message);
      notifyListeners();
      return null;
    }, (cabinet) => cabinet);
  }

  // ==================== LOCKERS ====================

  /// Lấy chi tiết locker
  Future<Locker?> getLockerById(String lockerId) async {
    final result = await _getLockerByIdUseCase(lockerId);

    return result.fold((failure) {
      _state = _state.copyWith(error: failure.message);
      notifyListeners();
      return null;
    }, (locker) => locker);
  }

  /// Lấy available lockers
  Future<void> getAvailableLockers({
    String? locationId,
    String? cabinetId,
    String? sizeId,
  }) async {
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();

    final result = await _getAvailableLockersUseCase(
      GetAvailableLockersParams(
        locationId: locationId,
        cabinetId: cabinetId,
        sizeId: sizeId,
      ),
    );

    result.fold(
      (failure) {
        _state = _state.copyWith(isLoading: false, error: failure.message);
      },
      (lockers) {
        _state = _state.copyWith(isLoading: false, availableLockers: lockers);
      },
    );
    notifyListeners();
  }

  /// Lấy locker count by size
  Future<void> getLockerCountBySize({required String cabinetId}) async {
    final result = await _getLockerCountUseCase(
      GetLockerCountParams(cabinetId: cabinetId),
    );

    result.fold(
      (failure) {
        // Silent fail hoặc log error
      },
      (response) {
        _state = _state.copyWith(
          lockerCounts: response.counts,
          lockerSizeItems: response.items,
        );
        notifyListeners();
      },
    );
  }

  /// Lấy cabinets cho customer
  Future<void> getCustomerCabinets(String locationId) async {
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();

    final result = await _getCustomerCabinetsUseCase(locationId);

    result.fold(
      (failure) {
        _state = _state.copyWith(isLoading: false, error: failure.message);
      },
      (cabinets) {
        _state = _state.copyWith(isLoading: false, cabinets: cabinets);
      },
    );
    notifyListeners();
  }

  /// Lấy least used lockers
  Future<void> getLeastUsedLockers(String cabinetId, {String? sizeId}) async {
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();

    final result = await _getLeastUsedLockersUseCase(cabinetId, sizeId: sizeId);

    result.fold(
      (failure) {
        _state = _state.copyWith(isLoading: false, error: failure.message);
      },
      (lockers) {
        _state = _state.copyWith(isLoading: false, leastUsedLockers: lockers);
      },
    );
    notifyListeners();
  }

  // ==================== RENTING & MANAGEMENT ====================

  /// Thuê tủ linh hoạt
  Future<Either<Failure, Map<String, dynamic>>> rentLockerFlexible({
    required String lockerId,
    String? cabinetId,
    bool skipPhysicalOpen = false,
  }) async {
    final effectiveCabinetId = cabinetId ?? _state.selectedCabinet?.id;

    if (effectiveCabinetId == null) {
      return const Left(ValidationFailure('No cabinet selected'));
    }

    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();

    final result = await _rentLockerFlexibleUseCase(
      lockerId: lockerId,
      cabinetId: effectiveCabinetId,
      skipPhysicalOpen: skipPhysicalOpen,
    );

    _state = _state.copyWith(isLoading: false);
    result.fold((failure) {
      _state = _state.copyWith(error: failure.message);
    }, (_) {});
    notifyListeners();
    return result;
  }

  /// Lấy chi tiết tủ đang thuê
  Future<Either<Failure, Map<String, dynamic>>> getRentedLockerDetail(
    String orderDetailId,
  ) async {
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();

    final result = await _getRentedLockerDetailUseCase(orderDetailId);

    _state = _state.copyWith(isLoading: false);
    result.fold((failure) {
      _state = _state.copyWith(error: failure.message);
    }, (_) {});
    notifyListeners();
    return result;
  }

  /// Mở tủ tạm thời
  Future<Either<Failure, Map<String, dynamic>>> openLockerTemporarily(
    String lockerId,
  ) async {
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();

    final result = await _openLockerTemporarilyUseCase(lockerId);

    _state = _state.copyWith(isLoading: false);
    result.fold((failure) {
      _state = _state.copyWith(error: failure.message);
    }, (_) {});
    notifyListeners();
    return result;
  }

  /// Trả tủ
  Future<Either<Failure, Map<String, dynamic>>> finishRental(
    String lockerId,
  ) async {
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();

    final result = await _finishRentalUseCase(lockerId);

    _state = _state.copyWith(isLoading: false);
    result.fold((failure) {
      _state = _state.copyWith(error: failure.message);
    }, (_) {});
    notifyListeners();
    return result;
  }

  // ==================== PRICINGS ====================

  Future<void> getPricings({String? orderType}) async {
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();

    final result = await _getPricingsUseCase(orderType: orderType);

    result.fold(
      (failure) {
        _state = _state.copyWith(isLoading: false, error: failure.message);
      },
      (pricings) {
        _state = _state.copyWith(isLoading: false, pricings: pricings);
      },
    );
    notifyListeners();
  }

  // ==================== SELECTION ====================

  /// Select location
  void selectLocation(LockerLocation location) {
    _state = _state.copyWith(selectedLocation: location);
    notifyListeners();
  }

  /// Select cabinet
  void selectCabinet(Cabinet cabinet) {
    _state = _state.copyWith(selectedCabinet: cabinet);
    notifyListeners();
  }

  /// Clear selection
  void clearSelection() {
    _state = _state.copyWith(
      selectedLocation: null,
      selectedCabinet: null,
      cabinets: [],
      lockers: [],
    );
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _state = _state.copyWith(error: null);
    notifyListeners();
  }
}
