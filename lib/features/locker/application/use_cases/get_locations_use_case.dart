import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:smart_laundry_locker/features/locker/domain/entities/locker_location.dart';
import 'package:smart_laundry_locker/core/domain/entities/pagination.dart';
import 'package:smart_laundry_locker/features/locker/domain/repositories/locker_repository.dart';
import 'package:dartz/dartz.dart';

/// Use Case: GetLocationsUseCase
/// Lấy danh sách locations với pagination và filter.
/// Đây là application-specific workflow.
class GetLocationsUseCase {
  final LockerRepository _repository;

  GetLocationsUseCase(this._repository);

  /// Execute use case
  ///
  /// [params] - Tham số để lọc và phân trang
  /// Returns: Either<Failure, PaginatedResult<LockerLocation>>
  Future<Either<Failure, PaginatedResult<LockerLocation>>> call(
    GetLocationsParams params,
  ) async {
    return await _repository.getLocations(
      page: params.page,
      limit: params.limit,
      search: params.search,
      name: params.name,
      address: params.address,
      isActive: params.isActive,
    );
  }
}

/// Parameters cho GetLocationsUseCase
class GetLocationsParams {
  final int page;
  final int limit;
  final String? search;
  final String? name;
  final String? address;
  final bool? isActive;

  const GetLocationsParams({
    this.page = 1,
    this.limit = 10,
    this.search,
    this.name,
    this.address,
    this.isActive,
  });

  /// Factory: Default params
  factory GetLocationsParams.initial() => const GetLocationsParams();

  /// CopyWith để tạo params mới
  GetLocationsParams copyWith({
    int? page,
    int? limit,
    String? search,
    String? name,
    String? address,
    bool? isActive,
  }) {
    return GetLocationsParams(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      search: search ?? this.search,
      name: name ?? this.name,
      address: address ?? this.address,
      isActive: isActive ?? this.isActive,
    );
  }
}
