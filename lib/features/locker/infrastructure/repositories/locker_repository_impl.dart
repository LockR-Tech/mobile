import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/core/services/token_service.dart';
import 'package:smart_laundry_locker/features/locker/domain/entities/cabinet.dart';
import 'package:smart_laundry_locker/features/locker/domain/entities/fixed_rent_entity.dart';
import 'package:smart_laundry_locker/features/locker/domain/entities/locker.dart';
import 'package:smart_laundry_locker/features/locker/domain/entities/locker_location.dart';
import 'package:smart_laundry_locker/core/domain/entities/pagination.dart';
import 'package:smart_laundry_locker/features/locker/domain/repositories/locker_repository.dart';
import 'package:smart_laundry_locker/features/locker/infrastructure/data_sources/locker_local_data_source.dart';
import 'package:smart_laundry_locker/features/locker/infrastructure/data_sources/locker_remote_data_source.dart';
import 'package:smart_laundry_locker/features/locker/infrastructure/models/responses/responses.dart';
import 'package:smart_laundry_locker/features/locker/infrastructure/models/locker_rent_request_model.dart';
import 'package:dartz/dartz.dart';

/// Implementation của LockerRepository
/// Kết hợp Remote và Local data sources để implement repository contract.
class LockerRepositoryImpl implements LockerRepository {
  final LockerRemoteDataSource _remoteDataSource;
  final LockerLocalDataSource? _localDataSource;

  LockerRepositoryImpl({
    required LockerRemoteDataSource remoteDataSource,
    LockerLocalDataSource? localDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource;

  // ==================== LOCATIONS ====================

  @override
  Future<Either<Failure, PaginatedResult<LockerLocation>>> getLocations({
    int page = 1,
    int limit = 10,
    String? search,
    String? name,
    String? address,
    bool? isActive,
  }) async {
    try {
      final roles = await TokenService.getCurrentRoles();
      print('DEBUG: Current user roles extracted: $roles');

      LocationsResponse response;
      // Check for roles with flexible matching (handling potential ROLE_ prefix or case)
      final hasCustomerRole = roles.any(
        (r) => r == 'CUSTOMER' || r == 'ROLE_CUSTOMER',
      );
      final hasCourierRole = roles.any(
        (r) => r == 'COURIER' || r == 'ROLE_COURIER',
      );
      final hasAdminRole = roles.any(
        (r) =>
            r == 'ADMIN' ||
            r == 'TECHNICIAN' ||
            r == 'ROLE_ADMIN' ||
            r == 'ROLE_TECHNICIAN',
      );

      if (hasCustomerRole && !hasAdminRole) {
        print('DEBUG: Routing to CUSTOMER location API');
        response = await _remoteDataSource.getLocationsForCustomer(
          page: page,
          limit: limit,
          search: search,
        );
      } else if (hasCourierRole && !hasAdminRole) {
        print('DEBUG: Routing to COURIER location API');
        response = await _remoteDataSource.getLocationsForCourier(
          page: page,
          limit: limit,
          search: search,
        );
      } else {
        print('DEBUG: Routing to DEFAULT location API');
        response = await _remoteDataSource.getLocations(
          page: page,
          limit: limit,
          search: search,
          name: name,
          address: address,
          isActive: isActive,
        );
      }

      // Cache locations nếu có local data source
      if (_localDataSource != null) {
        await _localDataSource.cacheLocations(response.locations);
      }

      // Convert models to entities
      final locations = response.locations.map((m) => m.toEntity()).toList();
      final pagination = Pagination(
        total: response.pagination.total,
        page: response.pagination.page,
        limit: response.pagination.limit,
      );

      return Right(PaginatedResult(items: locations, pagination: pagination));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      // Try to get from cache if network error
      if (_localDataSource != null) {
        final cached = await _localDataSource.getCachedLocations();
        if (cached != null && cached.isNotEmpty) {
          final locations = cached.map((m) => m.toEntity()).toList();
          return Right(
            PaginatedResult(
              items: locations,
              pagination: Pagination(
                total: locations.length,
                page: 1,
                limit: locations.length,
              ),
            ),
          );
        }
      }
      return Left(NetworkFailure(e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on AuthorizationException catch (e) {
      return Left(AuthorizationFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, LockerLocation>> getLocationById(String id) async {
    try {
      final model = await _remoteDataSource.getLocationById(id);

      // Cache location
      if (_localDataSource != null) {
        await _localDataSource.cacheLocation(model);
      }

      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      // Try to get from cache
      if (_localDataSource != null) {
        final cached = await _localDataSource.getCachedLocationById(id);
        if (cached != null) {
          return Right(cached.toEntity());
        }
      }
      return Left(NetworkFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, LocationWithCabinets>> getLocationCabinets(
    String locationId, {
    int page = 1,
    int limit = 10,
    String? status,
    String? search,
  }) async {
    try {
      final response = await _remoteDataSource.getLocationCabinets(
        locationId,
        page: page,
        limit: limit,
        status: status,
        search: search,
      );

      // Cache cabinets
      if (_localDataSource != null) {
        await _localDataSource.cacheCabinetsByLocation(
          locationId,
          response.cabinets,
        );
      }

      return Right(
        LocationWithCabinets(
          location: response.location.toEntity(),
          cabinets: response.cabinets.map((m) => m.toEntity()).toList(),
          pagination: Pagination(
            total: response.pagination.total,
            page: response.pagination.page,
            limit: response.pagination.limit,
          ),
        ),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  // ==================== CABINETS ====================

  @override
  Future<Either<Failure, PaginatedResult<Cabinet>>> getCabinets({
    int page = 1,
    int limit = 10,
    String? locationId,
    String? name,
    String? macAddress,
  }) async {
    try {
      final response = await _remoteDataSource.getCabinets(
        page: page,
        limit: limit,
        locationId: locationId,
        name: name,
        macAddress: macAddress,
      );

      // Cache cabinets
      if (_localDataSource != null) {
        await _localDataSource.cacheCabinets(response.cabinets);
      }

      final cabinets = response.cabinets.map((m) => m.toEntity()).toList();
      final pagination = Pagination(
        total: response.pagination.total,
        page: response.pagination.page,
        limit: response.pagination.limit,
      );

      return Right(PaginatedResult(items: cabinets, pagination: pagination));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Cabinet>> getCabinetById(String id) async {
    try {
      final model = await _remoteDataSource.getCabinetById(id);
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CabinetWithLockers>> getCabinetLockers(
    String cabinetId, {
    int page = 1,
    int limit = 10,
    String? search,
  }) async {
    try {
      final response = await _remoteDataSource.getCabinetLockers(
        cabinetId,
        page: page,
        limit: limit,
        search: search,
      );

      // Cache lockers
      if (_localDataSource != null) {
        await _localDataSource.cacheLockersByCabinet(
          cabinetId,
          response.lockers,
        );
      }

      return Right(
        CabinetWithLockers(
          cabinet: response.cabinet.toEntity(),
          lockers: response.lockers.map((m) => m.toEntity()).toList(),
          pagination: Pagination(
            total: response.pagination.total,
            page: response.pagination.page,
            limit: response.pagination.limit,
          ),
        ),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  // ==================== LOCKERS ====================

  @override
  Future<Either<Failure, Locker>> getLockerById(String id) async {
    try {
      final model = await _remoteDataSource.getLockerById(id);
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Locker>>> getLockersByCabinet(
    String cabinetId,
  ) async {
    try {
      final response = await _remoteDataSource.getLockersByCabinet(cabinetId);

      // Cache lockers
      if (_localDataSource != null) {
        await _localDataSource.cacheLockersByCabinet(
          cabinetId,
          response.lockers,
        );
      }

      return Right(response.lockers.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      // Try to get from cache
      if (_localDataSource != null) {
        final cached = await _localDataSource.getCachedLockersByCabinet(
          cabinetId,
        );
        if (cached != null && cached.isNotEmpty) {
          return Right(cached.map((m) => m.toEntity()).toList());
        }
      }
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Locker>>> getAvailableLockers({
    String? locationId,
    String? cabinetId,
    String? sizeId,
  }) async {
    try {
      final response = await _remoteDataSource.getAvailableLockers(
        locationId: locationId,
        cabinetId: cabinetId,
        sizeId: sizeId,
      );

      return Right(response.lockers.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, LockerCountResponse>> getLockerCountBySize({
    required String cabinetId,
  }) async {
    try {
      final response = await _remoteDataSource.getLockerCountBySize(
        cabinetId: cabinetId,
      );

      return Right(response);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Cabinet>>> getCustomerCabinets(
    String locationId,
  ) async {
    try {
      final cabinets = await _remoteDataSource.getCustomerCabinets(locationId);
      return Right(cabinets.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Locker>>> getLeastUsedLockers(
    String cabinetId, {
    String? sizeId,
  }) async {
    try {
      final models = await _remoteDataSource.getLeastUsedLockers(
        cabinetId,
        sizeId: sizeId,
      );
      final entities = models.map((m) => m.toEntity()).toList();
      return Right(entities);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  // ==================== RENTING & MANAGEMENT ====================

  @override
  Future<Either<Failure, Map<String, dynamic>>> rentLockerFlexible({
    required String lockerId,
    required String cabinetId,
    String itemType = 'OTHER',
    bool skipPhysicalOpen = false,
    String? voucherId,
  }) async {
    try {
      final result = await _remoteDataSource.rentLockerFlexible(
        lockerId: lockerId,
        cabinetId: cabinetId,
        itemType: itemType,
        skipPhysicalOpen: skipPhysicalOpen,
        voucherId: voucherId,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, FixedRentEntity>> fixedRentLocker({
    required String cabinetId,
    required String lockerId,
    required int rentMonths,
    int? rentDays,
    String itemType = 'OTHER',
    bool skipPhysicalOpen = false,
    String? voucherId,
  }) async {
    try {
      final response = await _remoteDataSource.fixedRentLocker(
        LockerRentRequestModel(
          cabinetId: cabinetId,
          lockerId: lockerId,
          rentMonths: rentMonths,
          rentDays: rentDays,
          itemType: itemType,
          skipPhysicalOpen: skipPhysicalOpen,
          voucherId: voucherId,
        ),
      );
      return Right(response.entity);
    } on ValidationException catch (e) {
      return Left(_mapFixedRentFailure(e.message));
    } on ServerException catch (e) {
      return Left(_mapFixedRentFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on AuthorizationException catch (e) {
      return Left(AuthorizationFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> openLocker(
    String lockerId,
  ) async {
    try {
      final data = await _remoteDataSource.openLocker(lockerId);
      return Right(data);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on AuthorizationException catch (e) {
      return Left(AuthorizationFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> closeLocker(
    String lockerId,
  ) async {
    try {
      final data = await _remoteDataSource.closeLocker(lockerId);
      return Right(data);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on AuthorizationException catch (e) {
      return Left(AuthorizationFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getRentedLockerDetail(
    String orderDetailId,
  ) async {
    try {
      final result = await _remoteDataSource.getRentedLockerDetail(
        orderDetailId,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> openLockerTemporarily(
    String lockerId,
  ) async {
    try {
      final result = await _remoteDataSource.openLockerTemporarily(lockerId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> finishRental(
    String lockerId,
  ) async {
    try {
      final result = await _remoteDataSource.finishRental(lockerId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}

Failure _mapFixedRentFailure(String message) {
  final m = message.toLowerCase();
  if (m.contains('tủ này đang được thuê')) {
    return const ValidationFailure('Tủ này đang được thuê.');
  }
  if (m.contains('số dư không đủ') || m.contains('insufficient')) {
    return const ValidationFailure('Số dư không đủ.');
  }
  return ValidationFailure(
    message.isNotEmpty ? message : 'Thuê tủ cố định thất bại.',
  );
}
