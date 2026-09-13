import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:smart_laundry_locker/features/locker/domain/repositories/locker_repository.dart';
import 'package:dartz/dartz.dart';

class FinishRentalUseCase {
  final LockerRepository _repository;

  FinishRentalUseCase(this._repository);

  Future<Either<Failure, Map<String, dynamic>>> call(String lockerId) async {
    return await _repository.finishRental(lockerId);
  }
}
