import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:smart_laundry_locker/features/locker/domain/repositories/locker_repository.dart';
import 'package:smart_laundry_locker/features/locker/infrastructure/models/responses/lockers_response.dart';
import 'package:dartz/dartz.dart';

/// Use Case: GetLockerCountBySizeUseCase
/// Đếm số lượng lockers theo size.
class GetLockerCountBySizeUseCase {
  final LockerRepository _repository;

  GetLockerCountBySizeUseCase(this._repository);

  /// Execute use case
  ///
  /// [params] - Filter parameters
  /// Returns: LockerCountResponse với items list chứa đầy đủ thông tin size
  Future<Either<Failure, LockerCountResponse>> call(
    GetLockerCountParams params,
  ) async {
    return await _repository.getLockerCountBySize(cabinetId: params.cabinetId);
  }
}

/// Parameters cho GetLockerCountBySizeUseCase
class GetLockerCountParams {
  final String cabinetId;

  const GetLockerCountParams({required this.cabinetId});

  factory GetLockerCountParams.byCabinet(String cabinetId) =>
      GetLockerCountParams(cabinetId: cabinetId);
}
