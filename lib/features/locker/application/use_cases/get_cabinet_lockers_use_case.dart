import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:smart_laundry_locker/features/locker/domain/repositories/locker_repository.dart';
import 'package:dartz/dartz.dart';

/// Use Case: GetCabinetLockersUseCase
/// Lấy danh sách lockers trong một cabinet.
class GetCabinetLockersUseCase {
  final LockerRepository _repository;

  GetCabinetLockersUseCase(this._repository);

  /// Execute use case
  Future<Either<Failure, CabinetWithLockers>> call(
    GetCabinetLockersParams params,
  ) async {
    if (params.cabinetId.isEmpty) {
      return Left(ValidationFailure('Cabinet ID không được để trống'));
    }

    return await _repository.getCabinetLockers(
      params.cabinetId,
      page: params.page,
      limit: params.limit,
      search: params.search,
    );
  }
}

/// Parameters cho GetCabinetLockersUseCase
class GetCabinetLockersParams {
  final String cabinetId;
  final int page;
  final int limit;
  final String? search;

  const GetCabinetLockersParams({
    required this.cabinetId,
    this.page = 1,
    this.limit = 20,
    this.search,
  });
}
