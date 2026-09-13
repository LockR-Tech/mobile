import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:smart_laundry_locker/features/locker/domain/entities/locker.dart';
import 'package:smart_laundry_locker/features/locker/domain/repositories/locker_repository.dart';
import 'package:dartz/dartz.dart';

class GetLockerByIdUseCase {
  final LockerRepository _repository;

  GetLockerByIdUseCase(this._repository);

  Future<Either<Failure, Locker>> call(String lockerId) async {
    return await _repository.getLockerById(lockerId);
  }
}
