import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:smart_laundry_locker/features/locker/domain/repositories/locker_repository.dart';
import 'package:dartz/dartz.dart';

/// Use Case: GetLocationCabinetsUseCase
/// Lấy danh sách cabinets trong một location.
class GetLocationCabinetsUseCase {
  final LockerRepository _repository;

  GetLocationCabinetsUseCase(this._repository);

  /// Execute use case
  Future<Either<Failure, LocationWithCabinets>> call(
    GetLocationCabinetsParams params,
  ) async {
    if (params.locationId.isEmpty) {
      return Left(ValidationFailure('Location ID không được để trống'));
    }

    return await _repository.getLocationCabinets(
      params.locationId,
      page: params.page,
      limit: params.limit,
      status: params.status,
      search: params.search,
    );
  }
}

/// Parameters cho GetLocationCabinetsUseCase
class GetLocationCabinetsParams {
  final String locationId;
  final int page;
  final int limit;
  final String? status;
  final String? search;

  const GetLocationCabinetsParams({
    required this.locationId,
    this.page = 1,
    this.limit = 10,
    this.status,
    this.search,
  });
}
