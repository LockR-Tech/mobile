import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:smart_laundry_locker/features/locker/domain/repositories/locker_repository.dart';
import 'package:dartz/dartz.dart';

class OpenLockerTemporarilyUseCase {
  final LockerRepository _repository;

  OpenLockerTemporarilyUseCase(this._repository);

  Future<Either<Failure, Map<String, dynamic>>> call(String lockerId) async {
    return await _repository.openLockerTemporarily(lockerId);
  }
}
