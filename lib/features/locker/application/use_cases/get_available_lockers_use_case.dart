import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:smart_laundry_locker/features/locker/domain/entities/locker.dart';
import 'package:smart_laundry_locker/features/locker/domain/repositories/locker_repository.dart';
import 'package:dartz/dartz.dart';

/// Use Case: GetAvailableLockersUseCase
/// Lấy danh sách lockers còn trống theo filter.
class GetAvailableLockersUseCase {
  final LockerRepository _repository;

  GetAvailableLockersUseCase(this._repository);

  /// Execute use case
  ///
  /// [params] - Filter parameters
  /// Returns: Either<Failure, List<Locker>>
  Future<Either<Failure, List<Locker>>> call(
    GetAvailableLockersParams params,
  ) async {
    return await _repository.getAvailableLockers(
      locationId: params.locationId,
      cabinetId: params.cabinetId,
      sizeId: params.sizeId,
    );
  }
}

/// Parameters cho GetAvailableLockersUseCase
class GetAvailableLockersParams {
  final String? locationId;
  final String? cabinetId;
  final String? sizeId;

  const GetAvailableLockersParams({
    this.locationId,
    this.cabinetId,
    this.sizeId,
  });

  factory GetAvailableLockersParams.byLocation(String locationId) =>
      GetAvailableLockersParams(locationId: locationId);

  factory GetAvailableLockersParams.byCabinet(String cabinetId) =>
      GetAvailableLockersParams(cabinetId: cabinetId);

  factory GetAvailableLockersParams.bySize(String sizeId) =>
      GetAvailableLockersParams(sizeId: sizeId);
}
