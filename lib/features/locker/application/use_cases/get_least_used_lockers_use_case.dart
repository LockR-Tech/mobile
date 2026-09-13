import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:smart_laundry_locker/features/locker/domain/entities/locker.dart';
import 'package:smart_laundry_locker/features/locker/domain/repositories/locker_repository.dart';
import 'package:dartz/dartz.dart';

class GetLeastUsedLockersUseCase {
  final LockerRepository _repository;

  GetLeastUsedLockersUseCase(this._repository);

  Future<Either<Failure, List<Locker>>> call(
    String cabinetId, {
    String? sizeId,
  }) async {
    return await _repository.getLeastUsedLockers(cabinetId, sizeId: sizeId);
  }
}
